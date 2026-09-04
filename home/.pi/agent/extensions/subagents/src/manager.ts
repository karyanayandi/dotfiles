/** Owns subagent sessions, event pumps, limits, and synchronous TUI reads. */

import type { SubagentBackend, SubagentSession } from "./backend.ts"
import type {
  BackendName,
  LiveToolState,
  RunOutcome,
  SpawnTask,
  SubagentEvent,
  SubagentOrigin,
  SubagentMeta,
  SubagentSnapshot,
  SubagentStatus,
  TranscriptItem,
} from "./domain.ts"
import {
  BackendUnavailableError,
  ConcurrencyLimitError,
  SendError,
  SpawnError,
} from "./domain.ts"

export const MAX_RUNNING = 4
export const MAX_TRACKED = 64
const STOP_TIMEOUT_MS = 5_000
const GLOBAL_NOTIFY_INTERVAL_MS = 100
const ERROR_TEXT_MAX_LENGTH = 4_096
const TRANSCRIPT_TEXT_MAX_LENGTH = 16 * 1_024
const LIVE_ASSISTANT_MAX_LENGTH = 16 * 1_024
const FINAL_TEXT_MAX_LENGTH = 64 * 1_024
const MAX_TRANSCRIPT_ITEMS = 512

function bounded(text: string) {
  return text.slice(0, ERROR_TEXT_MAX_LENGTH)
}
function boundedTranscriptText(text: string) {
  return text.slice(0, TRANSCRIPT_TEXT_MAX_LENGTH)
}
function appendTranscript(snapshot: MutableSnapshot, item: TranscriptItem) {
  snapshot.transcript.push(item)
  if (snapshot.transcript.length > MAX_TRANSCRIPT_ITEMS)
    snapshot.transcript.splice(
      0,
      snapshot.transcript.length - MAX_TRANSCRIPT_ITEMS,
    )
}

function abortError() {
  return new Error("Operation was aborted.")
}

function throwIfAborted(signal?: AbortSignal) {
  if (signal?.aborted) throw abortError()
}

function withTimeout<T>(operation: Promise<T>, timeoutMs: number) {
  let timer: ReturnType<typeof setTimeout> | undefined
  const timeout = new Promise<never>((_resolve, reject) => {
    timer = setTimeout(
      () => reject(new Error("Operation timed out.")),
      timeoutMs,
    )
  })
  return Promise.race([operation, timeout]).finally(() => {
    if (timer) clearTimeout(timer)
  })
}

function raceAbort<T>(
  operation: Promise<T>,
  signal?: AbortSignal,
  disposeLate?: (value: T) => Promise<void>,
) {
  if (!signal) return operation
  if (signal.aborted) {
    void operation.then((value) => disposeLate?.(value)).catch(() => {})
    return Promise.reject(abortError())
  }
  return new Promise<T>((resolve, reject) => {
    let settled = false
    const finish = (done: () => void) => {
      if (settled) return
      settled = true
      signal.removeEventListener("abort", onAbort)
      done()
    }
    const onAbort = () => {
      finish(() => reject(abortError()))
      void operation.then((value) => disposeLate?.(value)).catch(() => {})
    }
    signal.addEventListener("abort", onAbort, { once: true })
    void operation.then(
      (value) => finish(() => resolve(value)),
      (error) => finish(() => reject(error)),
    )
  })
}

interface MutableSnapshot {
  id: string
  origin: SubagentOrigin
  backend: BackendName
  title: string
  prompt: string
  cwd: string
  status: SubagentStatus
  createdAt: number
  settledAt?: number
  errorText?: string
  meta: SubagentMeta
  usage: { tokens?: number; contextWindow?: number }
  transcript: TranscriptItem[]
  liveAssistant?: { text: string; thinking: string }
  liveTools: LiveToolState[]
  queued: SubagentSnapshot["queued"]
  finalText: string
  turns: number
}

interface Entry {
  snapshot: MutableSnapshot
  session: SubagentSession
  pump?: Promise<void>
  liveToolMap: Map<string, LiveToolState>
  restarting?: boolean
}

export interface SubagentReadModel {
  list(): ReadonlyArray<SubagentSnapshot>
  get(id: string): SubagentSnapshot | undefined
  size(): number
  subscribe(listener: () => void): () => void
  subscribeTo(id: string, listener: () => void): () => void
  requestSend(id: string, text: string): void
  requestAbort(id: string): void
  setOnSettled(
    hook: ((snap: SubagentSnapshot, consumed: boolean) => void) | undefined,
  ): void
}

export interface CancelResult {
  readonly id: string
  readonly title: string
  readonly status: SubagentStatus
  readonly cancelled: boolean
}

export interface SubagentManagerShape {
  spawn(
    backend: BackendName,
    task: SpawnTask,
    signal?: AbortSignal,
  ): Promise<SubagentSnapshot>
  waitFor(
    ids: ReadonlyArray<string>,
    onPending?: (pending: string[]) => void,
    signal?: AbortSignal,
  ): Promise<void>
  cancel(
    ids: ReadonlyArray<string>,
    signal?: AbortSignal,
  ): Promise<ReadonlyArray<CancelResult>>
  send(id: string, text: string, signal?: AbortSignal): Promise<void>
  get(id: string): SubagentSnapshot | undefined
  list(): ReadonlyArray<SubagentSnapshot>
  disposeAll(): Promise<void>
  readonly view: SubagentReadModel
}

export function createSubagentManager(
  registry: ReadonlyMap<BackendName, SubagentBackend>,
): SubagentManagerShape {
  const entries = new Map<string, Entry>()
  const waitInterest = new Map<string, number>()
  const listeners = new Set<() => void>()
  const idListeners = new Map<string, Set<() => void>>()
  const cleanups = new Set<Promise<unknown>>()
  let globalNotifyTimer: ReturnType<typeof setTimeout> | undefined
  let lastGlobalNotifyAt = 0
  let changeWaiters: Array<() => void> = []
  let modelCounter = 0
  let btwCounter = 0
  let reserved = 0
  let disposed = false
  let onSettled:
    | ((snap: SubagentSnapshot, consumed: boolean) => void)
    | undefined

  const notifyGlobalListeners = () => {
    lastGlobalNotifyAt = Date.now()
    for (const listener of listeners)
      try {
        listener()
      } catch {}
  }
  const notify = (id?: string) => {
    const waiters = changeWaiters
    changeWaiters = []
    for (const waiter of waiters) waiter()
    if (!globalNotifyTimer) {
      const delay = Math.max(
        0,
        GLOBAL_NOTIFY_INTERVAL_MS - (Date.now() - lastGlobalNotifyAt),
      )
      globalNotifyTimer = setTimeout(() => {
        globalNotifyTimer = undefined
        notifyGlobalListeners()
      }, delay)
    }
    if (id)
      for (const listener of idListeners.get(id) ?? [])
        try {
          listener()
        } catch {}
  }
  const nextChange = (signal?: AbortSignal) =>
    new Promise<void>((resolve, reject) => {
      throwIfAborted(signal)
      const waiter = () => finish(resolve)
      const onAbort = () => finish(() => reject(abortError()))
      const finish = (done: () => void) => {
        const index = changeWaiters.indexOf(waiter)
        if (index >= 0) changeWaiters.splice(index, 1)
        signal?.removeEventListener("abort", onAbort)
        done()
      }
      changeWaiters.push(waiter)
      signal?.addEventListener("abort", onAbort, { once: true })
    })
  const runningCount = () =>
    [...entries.values()].filter(
      (entry) => entry.snapshot.status === "running" || entry.restarting,
    ).length
  const addInterest = (ids: ReadonlyArray<string>) => {
    for (const id of ids) waitInterest.set(id, (waitInterest.get(id) ?? 0) + 1)
  }
  const releaseInterest = (ids: ReadonlyArray<string>) => {
    for (const id of ids) {
      const count = (waitInterest.get(id) ?? 1) - 1
      if (count <= 0) waitInterest.delete(id)
      else waitInterest.set(id, count)
    }
  }
  const disposeEntry = (entry: Entry) => entry.session.dispose().catch(() => {})
  const trackCleanup = (cleanup: Promise<unknown>) => {
    cleanups.add(cleanup)
    void cleanup.finally(() => cleanups.delete(cleanup))
  }
  const pruneSettled = () => {
    if (entries.size <= MAX_TRACKED) return
    const candidates = [...entries.values()]
      .filter(
        (entry) =>
          entry.snapshot.status !== "running" &&
          !waitInterest.has(entry.snapshot.id),
      )
      .sort(
        (a, b) =>
          (a.snapshot.settledAt ?? a.snapshot.createdAt) -
          (b.snapshot.settledAt ?? b.snapshot.createdAt),
      )
    for (const entry of candidates) {
      if (entries.size <= MAX_TRACKED) break
      entries.delete(entry.snapshot.id)
      trackCleanup(disposeEntry(entry))
    }
  }
  const settle = (entry: Entry, outcome: RunOutcome) => {
    const snapshot = entry.snapshot
    entry.restarting = false
    if (snapshot.status !== "running") return
    snapshot.settledAt = Date.now()
    if (outcome._tag === "Completed") {
      snapshot.status = "done"
      snapshot.errorText = undefined
      snapshot.finalText = outcome.finalText.slice(0, FINAL_TEXT_MAX_LENGTH)
    } else if (outcome._tag === "Failed") {
      snapshot.status = "error"
      snapshot.errorText = bounded(outcome.errorText)
      snapshot.finalText = (outcome.partialText ?? "").slice(
        0,
        FINAL_TEXT_MAX_LENGTH,
      )
    } else {
      snapshot.status = "error"
      snapshot.errorText = "Run was aborted"
      snapshot.finalText = (outcome.partialText ?? "").slice(
        0,
        FINAL_TEXT_MAX_LENGTH,
      )
    }
    snapshot.liveAssistant = undefined
    entry.liveToolMap.clear()
    snapshot.liveTools = []
    snapshot.queued = []
    const consumed = (waitInterest.get(snapshot.id) ?? 0) > 0
    notify(snapshot.id)
    try {
      if (!disposed) onSettled?.(snapshot, consumed)
    } catch {}
    pruneSettled()
  }
  const foldEvent = (entry: Entry, event: SubagentEvent) => {
    const snapshot = entry.snapshot
    switch (event._tag) {
      case "RunStarted":
        entry.restarting = false
        snapshot.status = "running"
        snapshot.settledAt = undefined
        snapshot.errorText = undefined
        break
      case "RunSettled":
        settle(entry, event.outcome)
        return
      case "UserMessage":
        appendTranscript(snapshot, {
          kind: "user",
          text: boundedTranscriptText(event.text),
        })
        break
      case "AssistantDelta": {
        const live = snapshot.liveAssistant ?? { text: "", thinking: "" }
        snapshot.liveAssistant =
          event.kind === "text"
            ? {
                ...live,
                text: (live.text + event.delta).slice(
                  -LIVE_ASSISTANT_MAX_LENGTH,
                ),
              }
            : {
                ...live,
                thinking: (live.thinking + event.delta).slice(
                  -LIVE_ASSISTANT_MAX_LENGTH,
                ),
              }
        break
      }
      case "AssistantMessage":
        appendTranscript(snapshot, {
          kind: "assistant",
          parts: event.parts.map((part) =>
            part.type === "toolCall"
              ? {
                  ...part,
                  argsPreview: part.argsPreview
                    ? boundedTranscriptText(part.argsPreview)
                    : undefined,
                }
              : { ...part, text: boundedTranscriptText(part.text) },
          ),
        })
        snapshot.liveAssistant = undefined
        snapshot.turns++
        break
      case "ToolStart":
        entry.liveToolMap.set(event.toolId, {
          toolId: event.toolId,
          name: event.name,
          argsPreview: event.argsPreview
            ? boundedTranscriptText(event.argsPreview)
            : undefined,
        })
        snapshot.liveTools = [...entry.liveToolMap.values()]
        break
      case "ToolUpdate": {
        const current = entry.liveToolMap.get(event.toolId)
        if (current) {
          entry.liveToolMap.set(event.toolId, {
            ...current,
            outputPreview: event.outputPreview
              ? boundedTranscriptText(event.outputPreview)
              : current.outputPreview,
          })
          snapshot.liveTools = [...entry.liveToolMap.values()]
        }
        break
      }
      case "ToolEnd":
        entry.liveToolMap.delete(event.toolId)
        snapshot.liveTools = [...entry.liveToolMap.values()]
        appendTranscript(snapshot, {
          kind: "toolResult",
          toolId: event.toolId,
          name: event.name,
          isError: event.isError,
          outputPreview: event.outputPreview
            ? boundedTranscriptText(event.outputPreview)
            : undefined,
          displayResult: event.displayResult,
        })
        break
      case "QueueChanged":
        snapshot.queued = event.queued
        break
      case "UsageChanged":
        snapshot.usage = {
          tokens: event.tokens ?? snapshot.usage.tokens,
          contextWindow: event.contextWindow ?? snapshot.usage.contextWindow,
        }
        break
      case "MetaChanged":
        snapshot.meta = { ...snapshot.meta, ...event.meta }
        break
      case "BackendError":
        snapshot.errorText = bounded(event.message)
        break
    }
    notify(snapshot.id)
  }
  const pumpEvents = async (entry: Entry) => {
    try {
      for await (const event of entry.session.events) foldEvent(entry, event)
    } catch (error) {
      if (entry.snapshot.status === "running")
        settle(entry, {
          _tag: "Failed",
          errorText: error instanceof Error ? error.message : String(error),
        })
    } finally {
      if (entry.snapshot.status === "running")
        settle(entry, {
          _tag: "Failed",
          errorText: "Backend event stream ended unexpectedly",
        })
    }
  }

  const spawn = async (
    backendName: BackendName,
    task: SpawnTask,
    signal?: AbortSignal,
  ) => {
    throwIfAborted(signal)
    if (disposed)
      throw new SpawnError({ message: "Subagent manager is shutting down." })
    if (runningCount() + reserved >= MAX_RUNNING)
      throw new ConcurrencyLimitError({
        message: `Max ${MAX_RUNNING} subagents can run concurrently. Wait for one to finish before spawning another.`,
      })
    reserved++
    try {
      const backend = registry.get(backendName)
      if (!backend)
        throw new BackendUnavailableError({
          message: `Unknown backend "${backendName}".`,
        })
      if (!(await raceAbort(backend.available(), signal)))
        throw new BackendUnavailableError({
          message: `Backend "${backendName}" is not available on this machine (binary/SDK/credentials missing).`,
        })
      const session = await raceAbort(
        backend.spawn(task),
        signal,
        (lateSession) => lateSession.dispose().catch(() => {}),
      )
      if (disposed || signal?.aborted) {
        await session.dispose().catch(() => {})
        throw disposed
          ? new SpawnError({
              message: "Subagent manager shut down while spawning.",
            })
          : abortError()
      }
      const origin = task.origin ?? "model"
      const id =
        origin === "btw" ? `btw-${++btwCounter}` : `sa-${++modelCounter}`
      const meta = session.meta()
      const entry: Entry = {
        snapshot: {
          id,
          origin,
          backend: backendName,
          title: task.title,
          prompt: task.prompt,
          cwd: task.cwd,
          status: "running",
          createdAt: Date.now(),
          meta,
          usage: { contextWindow: meta.contextWindow },
          transcript: [],
          liveTools: [],
          queued: [],
          finalText: "",
          turns: 0,
        },
        session,
        liveToolMap: new Map(),
      }
      entries.set(id, entry)
      entry.pump = pumpEvents(entry)
      notify(id)
      return entry.snapshot
    } finally {
      reserved--
      notify()
    }
  }
  const waitFor = async (
    ids: ReadonlyArray<string>,
    onPending?: (pending: string[]) => void,
    signal?: AbortSignal,
  ) => {
    const unique = [...new Set(ids)]
    addInterest(unique)
    try {
      while (true) {
        throwIfAborted(signal)
        const pending = unique.filter(
          (id) => entries.get(id)?.snapshot.status === "running",
        )
        if (pending.length === 0) return
        onPending?.(pending)
        await nextChange(signal)
      }
    } finally {
      releaseInterest(unique)
      pruneSettled()
    }
  }
  const abortEntry = async (entry: Entry, signal?: AbortSignal) => {
    if (entry.snapshot.status !== "running") return
    throwIfAborted(signal)
    try {
      await withTimeout(entry.session.interrupt(), STOP_TIMEOUT_MS)
    } catch {
      settle(entry, { _tag: "Interrupted" })
      entry.snapshot.errorText =
        "Abort deadline exceeded; session was force-disposed"
      notify(entry.snapshot.id)
      await withTimeout(disposeEntry(entry), STOP_TIMEOUT_MS).catch(() => {})
    }
  }
  const cancel = async (ids: ReadonlyArray<string>, signal?: AbortSignal) => {
    const unique = [...new Set(ids)]
    const running = unique
      .map((id) => entries.get(id))
      .filter((entry): entry is Entry => entry?.snapshot.status === "running")
    const runningIds = running.map((entry) => entry.snapshot.id)
    addInterest(runningIds)
    try {
      await Promise.all(running.map((entry) => abortEntry(entry, signal)))
      while (running.some((entry) => entry.snapshot.status === "running"))
        await nextChange(signal)
    } finally {
      releaseInterest(runningIds)
      pruneSettled()
    }
    return unique.map((id) => {
      const snapshot = entries.get(id)?.snapshot
      return {
        id,
        title: snapshot?.title ?? "?",
        status: snapshot?.status ?? "error",
        cancelled: runningIds.includes(id),
      }
    })
  }
  const send = async (id: string, text: string, signal?: AbortSignal) => {
    throwIfAborted(signal)
    const entry = entries.get(id)
    if (!entry || disposed)
      throw new SendError({ message: `Subagent "${id}" is no longer tracked.` })
    if (entry.snapshot.status !== "running") {
      if (runningCount() + reserved >= MAX_RUNNING)
        throw new SendError({
          message: `Max ${MAX_RUNNING} subagents can run concurrently; restarting "${id}" would exceed that.`,
        })
      entry.restarting = true
      try {
        await entry.session.send(text)
      } catch (error) {
        entry.restarting = false
        throw error
      }
      return
    }
    await entry.session.send(text)
  }
  const disposeAll = async () => {
    if (disposed) return
    disposed = true
    if (globalNotifyTimer) clearTimeout(globalNotifyTimer)
    globalNotifyTimer = undefined
    const all = [...entries.values()]
    entries.clear()
    await Promise.all(
      all.map((entry) =>
        withTimeout(disposeEntry(entry), STOP_TIMEOUT_MS).catch(() => {}),
      ),
    )
    await Promise.all(
      [...cleanups].map((cleanup) =>
        withTimeout(cleanup, STOP_TIMEOUT_MS).catch(() => {}),
      ),
    )
    notify()
  }
  const view: SubagentReadModel = {
    list: () => [...entries.values()].map((entry) => entry.snapshot),
    get: (id) => entries.get(id)?.snapshot,
    size: () => entries.size,
    subscribe: (listener) => {
      listeners.add(listener)
      return () => listeners.delete(listener)
    },
    subscribeTo: (id, listener) => {
      const set = idListeners.get(id) ?? new Set<() => void>()
      idListeners.set(id, set)
      set.add(listener)
      return () => {
        set.delete(listener)
        if (set.size === 0) idListeners.delete(id)
      }
    },
    requestSend: (id, text) => {
      void send(id, text).catch(() => {})
    },
    requestAbort: (id) => {
      const entry = entries.get(id)
      if (entry) void abortEntry(entry).catch(() => {})
    },
    setOnSettled: (hook) => {
      onSettled = hook
    },
  }
  return {
    spawn,
    waitFor,
    cancel,
    send,
    get: view.get,
    list: view.list,
    disposeAll,
    view,
  }
}
