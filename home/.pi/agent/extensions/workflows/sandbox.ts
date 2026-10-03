import { randomBytes } from "node:crypto"
import { spawn, type ChildProcess } from "node:child_process"
import * as path from "node:path"
import { fileURLToPath } from "node:url"
import * as v from "valibot"
import {
  safeStringify,
  toSerializable,
  type JsonValue,
} from "./serialization.ts"

const MAX_SOURCE_BYTES = 512 * 1024

const MAX_ARGS_BYTES = 256 * 1024

const MAX_RESULT_BYTES = 1024 * 1024

const MAX_AGENT_MESSAGE_BYTES = 512 * 1024

const MAX_AGENT_REQUESTS = 32

export interface SandboxAgentOptions {
  label?: unknown
  phase?: unknown
  schema?: unknown
  model?: unknown
  provider?: unknown
  effort?: unknown
}

export interface SandboxAgentResult {
  ok: boolean
  output: string
  structured?: unknown
  error?: string
}

export interface RunWorkflowSandboxOptions {
  source: string
  args: unknown
  cwd: string
  signal: AbortSignal
  onAgent: (
    prompt: string,
    options: SandboxAgentOptions,
    signal: AbortSignal,
  ) => Promise<SandboxAgentResult>
  onPhase: (title: string) => void
}

function byteLength(value: string) {
  return Buffer.byteLength(value, "utf8")
}

const AgentOptionsSchema = v.pipe(
  v.unknown(),
  v.check((value) => !Array.isArray(value)),
  v.object({
    label: v.optional(v.unknown()),
    phase: v.optional(v.unknown()),
    schema: v.optional(v.unknown()),
    model: v.optional(v.unknown()),
    provider: v.optional(v.unknown()),
    effort: v.optional(v.unknown()),
  }),
)

const IpcEnvelopeSchema = v.object({
  token: v.string(),
  kind: v.string(),
  payloadJson: v.optional(v.unknown()),
  resultJson: v.optional(v.unknown()),
  error: v.optional(v.unknown()),
})

const AgentRequestSchema = v.object({
  id: v.pipe(v.number(), v.safeInteger(), v.minValue(1)),
  prompt: v.pipe(v.string(), v.maxLength(100_000)),
  options: AgentOptionsSchema,
})

function errorText<T>(error: T) {
  return error instanceof Error ? error.message : String(error)
}

function terminateChild(child: ChildProcess) {
  if (child.exitCode !== null || child.signalCode !== null) return
  child.kill("SIGTERM")

  const force = setTimeout(() => {
    if (child.exitCode === null && child.signalCode === null)
      child.kill("SIGKILL")
  }, 1_000)

  force.unref?.()
}

function sanitizeAgentOptions(
  value: v.InferOutput<typeof AgentOptionsSchema>,
): SandboxAgentOptions {
  const options: SandboxAgentOptions = {}

  if (value.label !== undefined) options.label = value.label

  if (value.phase !== undefined) options.phase = value.phase

  if (value.schema !== undefined) options.schema = value.schema

  if (value.model !== undefined) options.model = value.model

  if (value.provider !== undefined) options.provider = value.provider

  if (value.effort !== undefined) options.effort = value.effort

  return options
}

/**
 * Execute orchestration code in a separate, permission-restricted Node process.
 * The child can only invoke the narrow agent/phase IPC protocol and is always
 * terminated on completion, cancellation, or protocol failure. The workflow
 * itself and its agent requests have no wall-clock deadline. Active requests
 * are aborted only when the workflow is cancelled or the sandbox is cleaned up.
 */
export function runWorkflowSandbox(options: RunWorkflowSandboxOptions) {
  if (!process.allowedNodeEnvironmentFlags.has("--permission")) {
    return Promise.reject(
      new Error("This Node runtime cannot enforce workflow child permissions"),
    )
  }

  if (byteLength(options.source) > MAX_SOURCE_BYTES) {
    return Promise.reject(
      new Error(`Workflow script exceeds the ${MAX_SOURCE_BYTES} byte limit`),
    )
  }

  const argsJson = safeStringify(
    { defined: options.args !== undefined, value: options.args },
    { maxBytes: MAX_ARGS_BYTES, maxDepth: 16, maxNodes: 10_000 },
  )

  if (byteLength(argsJson) > MAX_ARGS_BYTES) {
    return Promise.reject(new Error("Workflow args exceed the IPC limit"))
  }

  return new Promise<JsonValue | undefined>((resolve, reject) => {
    const workerPath = fileURLToPath(
      new URL("./sandbox-child.cjs", import.meta.url),
    )

    const child = spawn(
      process.execPath,
      [
        "--permission",
        `--allow-fs-read=${path.dirname(workerPath)}`,
        "--max-old-space-size=128",
        "--stack-size=2048",
        workerPath,
      ],
      {
        cwd: options.cwd,
        env: {
          PATH: process.env.PATH ?? "",
          NODE_NO_WARNINGS: "1",
        },
        stdio: ["ignore", "ignore", "ignore", "ipc"],
      },
    )

    const token = randomBytes(24).toString("hex")
    const requestIds = new Set<number>()
    const activeAgentRequests = new Map<number, AbortController>()
    let requestCount = 0
    let finished = false

    const cleanup = () => {
      for (const abortController of activeAgentRequests.values()) {
        abortController.abort(new Error("Workflow stopped"))
      }

      activeAgentRequests.clear()
      options.signal.removeEventListener("abort", onAbort)
      child.removeAllListeners("message")
      child.removeAllListeners("error")
      child.removeAllListeners("exit")
      terminateChild(child)
    }

    const finish = (error?: Error, value?: JsonValue) => {
      if (finished) return
      finished = true
      cleanup()

      if (error) reject(error)
      else resolve(value)
    }

    const onAbort = () => finish(new Error("Workflow was aborted"))

    options.signal.addEventListener("abort", onAbort, { once: true })

    if (options.signal.aborted) {
      onAbort()

      return
    }

    child.on("error", (error) => finish(error))
    child.on("exit", (code, exitSignal) => {
      if (!finished) {
        finish(
          new Error(
            `Workflow sandbox exited before completion (${exitSignal ?? code ?? "unknown"})`,
          ),
        )
      }
    })
    child.on("message", (message) => {
      const parsedEnvelope = v.safeParse(IpcEnvelopeSchema, message)

      if (
        Array.isArray(message) ||
        !parsedEnvelope.success ||
        parsedEnvelope.output.token !== token
      ) {
        finish(new Error("Workflow sandbox sent an invalid IPC message"))

        return
      }

      const raw = parsedEnvelope.output

      if (raw.kind === "phase") {
        if (
          !v.is(v.string(), raw.payloadJson) ||
          byteLength(raw.payloadJson) > 4096
        ) {
          finish(new Error("Workflow sandbox sent an invalid phase update"))

          return
        }

        try {
          const payload = v.parse(
            v.object({ title: v.string() }),
            JSON.parse(raw.payloadJson),
          )

          options.onPhase(payload.title.slice(0, 160))
        } catch {
          finish(new Error("Workflow sandbox sent an invalid phase update"))
        }

        return
      }

      if (raw.kind === "agent") {
        if (
          !v.is(v.string(), raw.payloadJson) ||
          byteLength(raw.payloadJson) > MAX_AGENT_MESSAGE_BYTES
        ) {
          finish(new Error("Workflow sandbox sent an oversized agent request"))

          return
        }

        let payload: unknown

        try {
          payload = JSON.parse(raw.payloadJson)
        } catch {
          finish(new Error("Workflow sandbox sent malformed agent JSON"))

          return
        }

        const parsedRequest = v.safeParse(AgentRequestSchema, payload)

        if (!parsedRequest.success) {
          finish(new Error("Workflow sandbox sent an invalid agent request"))

          return
        }

        const request = parsedRequest.output

        if (requestIds.has(request.id) || ++requestCount > MAX_AGENT_REQUESTS) {
          finish(
            new Error("Workflow sandbox exceeded its agent request budget"),
          )

          return
        }

        requestIds.add(request.id)
        const id = request.id
        const abortController = new AbortController()

        const sendResult = (result: SandboxAgentResult) => {
          if (!activeAgentRequests.delete(id)) return

          if (finished || !child.connected) return

          const normalized = toSerializable(result, {
            maxDepth: 16,
            maxNodes: 10_000,
            maxStringBytes: 128 * 1024,
          })

          let resultJson = JSON.stringify(normalized)

          if (byteLength(resultJson) > MAX_AGENT_MESSAGE_BYTES) {
            resultJson = JSON.stringify({
              ok: false,
              output: "",
              error: "Agent result exceeded the workflow IPC output limit",
            })
          }

          child.send({ token, kind: "agentResult", id, resultJson })
        }

        activeAgentRequests.set(id, abortController)
        void options
          .onAgent(
            request.prompt,
            sanitizeAgentOptions(request.options),
            abortController.signal,
          )
          .then(sendResult)
          .catch((error) =>
            sendResult({ ok: false, output: "", error: errorText(error) }),
          )

        return
      }

      if (raw.kind === "result") {
        if (
          !v.is(v.string(), raw.resultJson) ||
          byteLength(raw.resultJson) > MAX_RESULT_BYTES
        ) {
          finish(new Error("Workflow result exceeded the IPC limit"))

          return
        }

        try {
          const normalized = toSerializable(JSON.parse(raw.resultJson))
          finish(undefined, JSON.parse(JSON.stringify(normalized)))
        } catch (error) {
          finish(
            new Error(`Workflow returned invalid JSON: ${errorText(error)}`),
          )
        }

        return
      }

      if (raw.kind === "error" && v.is(v.string(), raw.error)) {
        finish(new Error(raw.error.slice(0, 16 * 1024)))

        return
      }

      finish(new Error("Workflow sandbox sent an unknown IPC message"))
    })

    child.send(
      {
        kind: "init",
        token,
        source: options.source,
        argsJson,
      },
      (error) => {
        if (error) finish(error)
      },
    )
  })
}
