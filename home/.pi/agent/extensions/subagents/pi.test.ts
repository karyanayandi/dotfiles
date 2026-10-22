import assert from "node:assert/strict"
import childProcess from "node:child_process"
import { once } from "node:events"
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises"
import {
  createServer,
  type IncomingMessage,
  type ServerResponse,
} from "node:http"
import { syncBuiltinESMExports } from "node:module"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test, { type TestContext } from "node:test"
import { ModelRegistry, ModelRuntime } from "@earendil-works/pi-coding-agent"
import { piBackend } from "./src/backends/pi.ts"
import type { SpawnTask, SubagentEvent } from "./src/domain.ts"
import * as v from "valibot"

const PROVIDER = "subagents-local-test"

const MODEL_ID = "local-session-test"

const API_KEY = "subagents-test-key"

const COMPLETE_PROMPT = "Reply with the local test result"

const CANCEL_PROMPT = "Hold the response until cancelled"

const CANCEL_TEXT = "partial local result"

type RunSettledEvent = Extract<SubagentEvent, { _tag: "RunSettled" }>

const requestSchema = v.looseObject({
  model: v.string(),
  messages: v.array(
    v.looseObject({
      role: v.string(),
      content: v.union([
        v.string(),
        v.array(
          v.looseObject({ type: v.string(), text: v.optional(v.string()) }),
        ),
      ]),
    }),
  ),
  tools: v.optional(
    v.array(v.looseObject({ function: v.looseObject({ name: v.string() }) })),
  ),
})

type ModelRequest = v.InferOutput<typeof requestSchema>

interface CapturedRequest {
  body: ModelRequest
  authorization: string | undefined
}

interface PiFixture {
  agentDir: string
  cwd: string
  modelRegistry: ModelRegistry
  requests: CapturedRequest[]
  waitForBlockedResponseClose(): Promise<void>
  close(): Promise<void>
}

function isRunSettledEvent(event: SubagentEvent): event is RunSettledEvent {
  return event._tag === "RunSettled"
}

function deadline<Value>(operation: Promise<Value>, timeoutMs: number) {
  let timer: ReturnType<typeof setTimeout> | undefined

  const timeout = new Promise<never>((_resolve, reject) => {
    timer = setTimeout(
      () => reject(new Error(`Pi backend test exceeded ${timeoutMs}ms`)),
      timeoutMs,
    )
  })

  return Promise.race([operation, timeout]).finally(() => {
    if (timer) clearTimeout(timer)
  })
}

function installNoChildProcessGuard(t: TestContext) {
  let attempts = 0

  function rejectProcessLaunch() {
    attempts += 1
    throw new Error("Pi backend must not launch a child process")
  }

  const methods = [
    "spawn",
    "spawnSync",
    "exec",
    "execSync",
    "execFile",
    "execFileSync",
    "fork",
  ] as const

  for (const method of methods)
    t.mock.method(childProcess, method, rejectProcessLaunch)

  syncBuiltinESMExports()

  return {
    assertNone() {
      assert.equal(attempts, 0)
    },
    restore() {
      t.mock.restoreAll()
      syncBuiltinESMExports()
    },
  }
}

function readLastUserText(body: ModelRequest) {
  const message = [...body.messages]
    .reverse()
    .find((entry) => entry.role === "user")

  if (!message) return undefined

  if (!Array.isArray(message.content)) return message.content

  return message.content
    .filter((part) => part.type === "text")
    .map((part) => part.text ?? "")
    .join("\n")
}

function readToolNames(body: ModelRequest) {
  return body.tools?.map((tool) => tool.function.name) ?? []
}

function sendChunk(
  response: ServerResponse,
  delta: Record<string, string>,
  finishReason: string | null,
) {
  response.write(
    `data: ${JSON.stringify({
      id: "subagents-test-response",
      object: "chat.completion.chunk",
      created: 1,
      model: MODEL_ID,
      choices: [{ index: 0, delta, finish_reason: finishReason }],
    })}\n\n`,
  )
}

async function readRequestBody(request: IncomingMessage) {
  request.setEncoding("utf8")
  let text = ""

  for await (const chunk of request) text += String(chunk)

  try {
    const result = v.safeParse(requestSchema, JSON.parse(text))

    return result.success ? result.output : undefined
  } catch {
    return undefined
  }
}

async function createFixture(): Promise<PiFixture> {
  const root = await mkdtemp(join(tmpdir(), "subagents-pi-test-"))
  const agentDir = join(root, "agent")
  const cwd = join(root, "workspace")
  const previousAgentDir = process.env.PI_CODING_AGENT_DIR
  const previousOffline = process.env.PI_OFFLINE
  const requests: CapturedRequest[] = []
  let blockedResponseClosed: Promise<void> | undefined

  process.env.PI_CODING_AGENT_DIR = agentDir
  process.env.PI_OFFLINE = "1"

  async function handleModelRequest(
    request: IncomingMessage,
    response: ServerResponse,
  ) {
    const body = await readRequestBody(request)

    if (!body) {
      response.writeHead(400).end()

      return
    }

    requests.push({ body, authorization: request.headers.authorization })
    response.writeHead(200, {
      "content-type": "text/event-stream",
      "cache-control": "no-cache",
      connection: "keep-alive",
    })
    sendChunk(response, { role: "assistant" }, null)

    if (readLastUserText(body) === CANCEL_PROMPT) {
      blockedResponseClosed = new Promise((resolve) =>
        response.once("close", resolve),
      )
      sendChunk(response, { content: CANCEL_TEXT }, null)

      return
    }

    sendChunk(response, { content: "Hello " }, null)
    sendChunk(response, { content: "from local Pi" }, null)
    sendChunk(response, {}, "stop")
    response.end("data: [DONE]\n\n")
  }

  const server = createServer((request, response) => {
    void handleModelRequest(request, response).catch((error) => {
      response.destroy(error instanceof Error ? error : undefined)
    })
  })

  function restoreEnvironment() {
    if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR
    else process.env.PI_CODING_AGENT_DIR = previousAgentDir

    if (previousOffline === undefined) delete process.env.PI_OFFLINE
    else process.env.PI_OFFLINE = previousOffline
  }

  async function closeServer() {
    if (!server.listening) return

    server.closeAllConnections()
    await new Promise<void>((resolve, reject) => {
      server.close((error) => {
        if (error) reject(error)
        else resolve()
      })
    })
  }

  async function close() {
    try {
      await closeServer()
    } finally {
      restoreEnvironment()
      await rm(root, { recursive: true, force: true })
    }
  }

  try {
    await mkdir(agentDir, { recursive: true })
    await mkdir(cwd, { recursive: true })
    server.listen(0, "127.0.0.1")
    await once(server, "listening")

    const address = server.address()

    if (!address || v.is(v.string(), address))
      throw new Error("Local model server has no TCP address")

    const modelsPath = join(agentDir, "models.json")
    await writeFile(
      modelsPath,
      JSON.stringify({
        providers: {
          [PROVIDER]: {
            baseUrl: `http://127.0.0.1:${address.port}/v1`,
            api: "openai-completions",
            apiKey: API_KEY,
            models: [
              {
                id: MODEL_ID,
                name: "Local session test",
                input: ["text"],
                contextWindow: 8192,
                maxTokens: 256,
                reasoning: false,
              },
            ],
          },
        },
      }),
    )

    const modelRuntime = await ModelRuntime.create({
      authPath: join(agentDir, "auth.json"),
      modelsPath,
      refreshOnCreate: false,
    })

    return {
      agentDir,
      cwd,
      modelRegistry: new ModelRegistry(modelRuntime),
      requests,
      async waitForBlockedResponseClose() {
        if (!blockedResponseClosed)
          throw new Error("The local server did not start the held response")
        await deadline(blockedResponseClosed, 5_000)
      },
      close,
    }
  } catch (error) {
    await close()
    throw error
  }
}

function makeTask(
  cwd: string,
  modelRegistry: ModelRegistry,
  prompt: string,
): SpawnTask {
  return {
    prompt,
    title: "Pi backend test",
    cwd,
    parent: {
      parentCwd: cwd,
      projectTrusted: false,
      inheritedModel: { provider: PROVIDER, id: MODEL_ID },
      inheritedThinkingLevel: "off",
      modelRegistry,
    },
  }
}

async function collectUntilSettled(
  events: AsyncIterable<SubagentEvent>,
): Promise<SubagentEvent[]> {
  const iterator = events[Symbol.asyncIterator]()
  const collected: SubagentEvent[] = []

  while (true) {
    const next = await deadline(iterator.next(), 10_000)

    if (next.done) throw new Error("Pi event stream closed before settlement")
    collected.push(next.value)

    if (isRunSettledEvent(next.value)) return collected
  }
}

async function nextMatchingEvent<Event extends SubagentEvent>(
  iterator: AsyncIterator<SubagentEvent>,
  predicate: (event: SubagentEvent) => event is Event,
): Promise<Event> {
  while (true) {
    const next = await deadline(iterator.next(), 10_000)

    if (next.done) throw new Error("Pi event stream closed before the event")

    if (predicate(next.value)) return next.value
  }
}

async function drainUntilClosed(iterator: AsyncIterator<SubagentEvent>) {
  while (!(await deadline(iterator.next(), 5_000)).done) {
    // Drain queued events before checking that disposal closes the stream.
  }
}

void test(
  "Pi backend completes an inherited model run in process",
  { timeout: 20_000 },
  async (t) => {
    const fixture = await createFixture()
    const processGuard = installNoChildProcessGuard(t)
    let session: Awaited<ReturnType<typeof piBackend.spawn>> | undefined

    try {
      session = await piBackend.spawn(
        makeTask(fixture.cwd, fixture.modelRegistry, COMPLETE_PROMPT),
      )
      const events = await collectUntilSettled(session.events)
      const settled = events.find(isRunSettledEvent)
      const meta = session.meta()
      const request = fixture.requests[0]

      assert.ok(settled)
      assert.deepEqual(settled.outcome, {
        _tag: "Completed",
        finalText: "Hello from local Pi",
      })
      assert.ok(events.some((event) => event._tag === "RunStarted"))
      assert.ok(
        events.some(
          (event) =>
            event._tag === "UserMessage" && event.text === COMPLETE_PROMPT,
        ),
      )
      assert.deepEqual(
        events
          .filter(
            (event) => event._tag === "AssistantDelta" && event.kind === "text",
          )
          .map((event) => (event._tag === "AssistantDelta" ? event.delta : "")),
        ["Hello ", "from local Pi"],
      )
      assert.ok(
        events.some(
          (event) =>
            event._tag === "AssistantMessage" &&
            event.parts.some(
              (part) =>
                part.type === "text" && part.text === "Hello from local Pi",
            ),
        ),
      )
      assert.ok(events.some((event) => event._tag === "UsageChanged"))
      assert.ok(
        events.some(
          (event) =>
            event._tag === "MetaChanged" &&
            event.meta.backend === "pi" &&
            event.meta.modelLabel === `${PROVIDER}/${MODEL_ID}`,
        ),
      )
      assert.equal(meta.backend, "pi")
      assert.equal(meta.modelLabel, `${PROVIDER}/${MODEL_ID}`)
      assert.equal(meta.thinkingLevel, "off")
      assert.equal(meta.contextWindow, 8192)
      assert.ok(meta.sessionFilePath)
      assert.ok(
        meta.sessionFilePath.startsWith(join(fixture.agentDir, "sessions")),
      )
      assert.ok(request)
      assert.equal(request.body.model, MODEL_ID)
      assert.equal(request.authorization, `Bearer ${API_KEY}`)
      assert.deepEqual(
        readToolNames(request.body).filter((name) =>
          [
            "subagent_spawn",
            "subagent_wait",
            "subagent_cancel",
            "subagent_check",
            "subagent_list",
            "workflow",
            "ask_user",
          ].includes(name),
        ),
        [],
      )
      assert.match(
        await readFile(meta.sessionFilePath, "utf8"),
        /Hello from local Pi/,
      )
    } finally {
      try {
        if (session) await session.dispose()
      } finally {
        try {
          processGuard.assertNone()
        } finally {
          processGuard.restore()
          await fixture.close()
        }
      }
    }
  },
)

void test(
  "Pi backend interrupts and disposes an active in-process run",
  { timeout: 20_000 },
  async (t) => {
    const fixture = await createFixture()
    const processGuard = installNoChildProcessGuard(t)
    let session: Awaited<ReturnType<typeof piBackend.spawn>> | undefined

    try {
      session = await piBackend.spawn(
        makeTask(fixture.cwd, fixture.modelRegistry, CANCEL_PROMPT),
      )
      const iterator = session.events[Symbol.asyncIterator]()

      await nextMatchingEvent(
        iterator,
        (event): event is Extract<SubagentEvent, { _tag: "AssistantDelta" }> =>
          event._tag === "AssistantDelta" && event.delta === CANCEL_TEXT,
      )
      await session.interrupt()

      const settled = await nextMatchingEvent(iterator, isRunSettledEvent)
      assert.deepEqual(settled.outcome, {
        _tag: "Interrupted",
        partialText: CANCEL_TEXT,
      })
      await fixture.waitForBlockedResponseClose()

      const sessionFilePath = session.meta().sessionFilePath
      assert.ok(sessionFilePath)
      assert.ok(sessionFilePath.startsWith(join(fixture.agentDir, "sessions")))

      await session.dispose()
      await session.dispose()
      await drainUntilClosed(iterator)
      await assert.rejects(
        session.send("must not restart"),
        /session is closed/i,
      )
    } finally {
      try {
        if (session) await session.dispose()
      } finally {
        try {
          processGuard.assertNone()
        } finally {
          processGuard.restore()
          await fixture.close()
        }
      }
    }
  },
)
