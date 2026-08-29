/** Scripted backend used by manager tests. */

import * as fs from "node:fs"
import * as os from "node:os"
import * as path from "node:path"
import {
  AsyncEventQueue,
  type SubagentBackend,
  type SubagentSession,
} from "../backend.ts"
import type {
  BackendName,
  QueuedMessage,
  SpawnTask,
  SubagentEvent,
  SubagentMeta,
} from "../domain.ts"
import { SendError } from "../domain.ts"

export interface StubProfile {
  readonly backend: BackendName
  readonly defaultModelLabel: string
  readonly contextWindow: number
  readonly toolName: string
  readonly cadenceMs: number
}

const STUB_DIR = path.join(os.tmpdir(), "subagents-stub")
let sessionCounter = 0

export function makeStubBackend(profile: StubProfile): SubagentBackend {
  return {
    name: profile.backend,
    capabilities: {
      steering: true,
      modelSelection: true,
      reasoningEffort: true,
    },
    available: async () => true,
    spawn: (task) => makeStubSession(profile, task),
  }
}

function firstLine(text: string) {
  return (
    text
      .split("\n")
      .find((line) => line.trim())
      ?.trim() ?? ""
  )
}
function chunked(text: string, size: number) {
  const chunks: string[] = []
  for (let index = 0; index < text.length; index += size)
    chunks.push(text.slice(index, index + size))
  return chunks
}
function pause(ms: number, signal: AbortSignal) {
  return new Promise<void>((resolve, reject) => {
    const timer = setTimeout(resolve, ms)
    signal.addEventListener(
      "abort",
      () => {
        clearTimeout(timer)
        reject(new Error("Interrupted"))
      },
      { once: true },
    )
  })
}

async function makeStubSession(
  profile: StubProfile,
  task: SpawnTask,
): Promise<SubagentSession> {
  const sessionId = `stub-${profile.backend}-${++sessionCounter}`
  const sessionFile = path.join(STUB_DIR, `${sessionId}.jsonl`)
  const state = {
    meta: {
      backend: profile.backend,
      modelLabel: task.model ?? profile.defaultModelLabel,
      contextWindow: profile.contextWindow,
      sessionFilePath: sessionFile,
      nativeSessionId: sessionId,
    } satisfies SubagentMeta,
    pending: [] as string[],
    turnCount: 0,
    closed: false,
    active: undefined as AbortController | undefined,
  }
  const events = new AsyncEventQueue<SubagentEvent>()
  const inbox = new AsyncEventQueue<string>()
  const emit = (event: SubagentEvent) => {
    try {
      fs.appendFileSync(sessionFile, `${JSON.stringify(event)}\n`)
    } catch {}
    if (event._tag === "MetaChanged")
      state.meta = { ...state.meta, ...event.meta }
    events.push(event)
  }
  const queuedView = (): ReadonlyArray<QueuedMessage> =>
    state.pending.map((text) => ({ text, kind: "steer" }))
  const runTurn = async (
    userText: string,
    turn: number,
    signal: AbortSignal,
  ) => {
    emit({ _tag: "RunStarted" })
    const failing = userText.trimStart().startsWith("FAIL:")
    const thinking = "Looking at the task and planning an approach..."
    for (const delta of chunked(thinking, 16)) {
      emit({ _tag: "AssistantDelta", kind: "thinking", delta })
      await pause(profile.cadenceMs, signal)
    }
    const toolId = `${sessionId}-tool-${turn}`
    const argsPreview = `{"command":"ls ${task.cwd}"}`
    emit({
      _tag: "AssistantMessage",
      parts: [
        { type: "thinking", text: thinking },
        {
          type: "text",
          text: `I'll run ${profile.toolName} to look around first.`,
        },
        { type: "toolCall", toolId, name: profile.toolName, argsPreview },
      ],
    })
    emit({ _tag: "ToolStart", toolId, name: profile.toolName, argsPreview })
    await pause(profile.cadenceMs, signal)
    emit({ _tag: "ToolUpdate", toolId, outputPreview: "src docs package.json" })
    await pause(profile.cadenceMs, signal)
    emit({
      _tag: "ToolEnd",
      toolId,
      name: profile.toolName,
      isError: false,
      outputPreview: "src docs package.json",
    })
    emit({
      _tag: "UsageChanged",
      tokens: Math.min(profile.contextWindow, 2400 * (turn + 1)),
      contextWindow: profile.contextWindow,
    })
    if (failing) {
      await pause(profile.cadenceMs, signal)
      emit({
        _tag: "RunSettled",
        outcome: {
          _tag: "Failed",
          errorText: `[stub:${profile.backend}] task failed as requested by FAIL: prefix`,
        },
      })
      return
    }
    const finalText = `[stub:${profile.backend}] completed: ${firstLine(userText).slice(0, 200)}\n\nThis is a stubbed ${profile.backend} subagent turn ${turn + 1}. The real backend integration will replace this scripted output.`
    for (const delta of chunked(finalText, 24)) {
      emit({ _tag: "AssistantDelta", kind: "text", delta })
      await pause(profile.cadenceMs, signal)
    }
    emit({
      _tag: "AssistantMessage",
      parts: [{ type: "text", text: finalText }],
    })
    emit({
      _tag: "UsageChanged",
      tokens: Math.min(profile.contextWindow, 2400 * (turn + 1) + 900),
      contextWindow: profile.contextWindow,
    })
    emit({ _tag: "RunSettled", outcome: { _tag: "Completed", finalText } })
  }
  const driver = async () => {
    for await (const text of inbox) {
      if (state.closed) break
      state.pending.shift()
      emit({ _tag: "QueueChanged", queued: queuedView() })
      emit({ _tag: "UserMessage", text })
      const controller = new AbortController()
      state.active = controller
      try {
        await runTurn(text, state.turnCount++, controller.signal)
      } catch {
        if (!state.closed)
          emit({ _tag: "RunSettled", outcome: { _tag: "Interrupted" } })
      } finally {
        if (state.active === controller) state.active = undefined
      }
    }
  }
  void driver()
  try {
    fs.mkdirSync(STUB_DIR, { recursive: true })
  } catch {}
  emit({ _tag: "MetaChanged", meta: state.meta })
  const submit = async (text: string) => {
    if (state.closed)
      throw new SendError({ message: "Subagent session is closed." })
    state.pending.push(text)
    if (state.active) emit({ _tag: "QueueChanged", queued: queuedView() })
    inbox.push(text)
  }
  await submit(task.prompt)
  return {
    meta: () => state.meta,
    events,
    send: submit,
    interrupt: async () => {
      const cleared = inbox.clear()
      state.pending = []
      emit({ _tag: "QueueChanged", queued: [] })
      if (state.active) state.active.abort()
      else if (cleared.length > 0)
        emit({ _tag: "RunSettled", outcome: { _tag: "Interrupted" } })
    },
    dispose: async () => {
      if (state.closed) return
      state.closed = true
      state.active?.abort()
      inbox.close()
      events.close()
    },
  }
}
