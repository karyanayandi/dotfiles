/**
 * TerminalManager owns background process lifetime, captured output, and
 * synchronous read model used by TUI.
 */

import { spawn, type ChildProcess } from "node:child_process"
import * as fs from "node:fs"
import * as os from "node:os"
import * as path from "node:path"
import {
  ConcurrencyLimitError,
  formatExit,
  SpawnError,
  UnknownTerminalError,
  type TerminalSnapshot,
  type TerminalStatus,
} from "./domain.ts"
import { OutputBuffer } from "./output.ts"

export const MAX_RUNNING = 8
export const MAX_TRACKED = 32
const MAX_SETTLED_HISTORY = MAX_TRACKED * 4
export const RETAINED_PER_STREAM = 2 * 1024 * 1024
export const MAX_SPILL_BYTES_PER_STREAM = 256 * 1024 * 1024
const STOP_TIMEOUT_MS = 5_000
const FORCE_KILL_AFTER_MS = 2_000
const SETTLE_GRACE_MS = 1_000
const SPILL_FLUSH_TIMEOUT_MS = 1_500
const GLOBAL_NOTIFY_INTERVAL_MS = 100
const ERROR_TEXT_MAX_LENGTH = 4_096

function bounded(text: string) {
  return text.slice(0, ERROR_TEXT_MAX_LENGTH)
}

function boundedError(error: unknown) {
  return bounded(error instanceof Error ? error.message : String(error))
}

function withTimeout<T>(promise: Promise<T>, timeoutMs: number) {
  let timer: number | undefined
  const timeout = new Promise<undefined>((resolve) => {
    timer = setTimeout(resolve, timeoutMs)
  })
  return Promise.race([promise, timeout]).finally(() => {
    if (timer) clearTimeout(timer)
  })
}

function waitForClose(
  child: ChildProcess,
  closed: () => boolean,
  timeoutMs: number,
) {
  if (closed()) return Promise.resolve(true)
  return new Promise<boolean>((resolve) => {
    const onClose = () => finish(true)
    const timer = setTimeout(() => finish(false), timeoutMs)
    const finish = (didClose: boolean) => {
      clearTimeout(timer)
      child.off("close", onClose)
      resolve(didClose)
    }
    child.once("close", onClose)
  })
}

interface Deferred {
  readonly promise: Promise<void>
  resolve(): void
}

function deferred(): Deferred {
  let resolve!: () => void
  const promise = new Promise<void>((done) => {
    resolve = done
  })
  return { promise, resolve }
}

interface MutableSnapshot extends TerminalSnapshot {
  status: TerminalStatus
  pid?: number
  settledAt?: number
  exitCode?: number
  signal?: string
  errorText?: string
}

interface Entry {
  snapshot: MutableSnapshot
  child: ChildProcess
  stdoutBuf: OutputBuffer
  stderrBuf: OutputBuffer
  spillStreams: fs.WriteStream[]
  killSignaled: boolean
  processErrored: boolean
  exited: boolean
  stdioClosed: boolean
  settling: boolean
  exitCleanupStarted: boolean
  settled: Deferred
  closing?: Promise<void>
}

export interface StartOptions {
  readonly command: string
  readonly title: string
  readonly cwd: string
}

export interface KillResult {
  readonly id: string
  readonly title: string
  readonly status: TerminalStatus
  readonly wasRunning: boolean
  readonly killed: boolean
  readonly exit: string
}

export interface TerminalReadModel {
  list(): ReadonlyArray<TerminalSnapshot>
  get(id: string): TerminalSnapshot | undefined
  size(): number
  subscribe(listener: () => void): () => void
  subscribeTo(id: string, listener: () => void): () => void
  requestKill(id: string): void
  setOnSettled(
    hook: ((snap: TerminalSnapshot, consumed: boolean) => void) | undefined,
  ): void
}

export interface TerminalManagerShape {
  start(options: StartOptions): Promise<TerminalSnapshot>
  status(id: string): Promise<TerminalSnapshot>
  kill(ids: ReadonlyArray<string>): Promise<ReadonlyArray<KillResult>>
  list(): ReadonlyArray<TerminalSnapshot>
  disposeAll(): Promise<void>
  readonly view: TerminalReadModel
}

function shellInvocation(command: string) {
  if (process.platform === "win32") {
    return {
      shell: process.env.ComSpec ?? "cmd.exe",
      args: ["/d", "/s", "/c", command],
    }
  }
  return { shell: "/bin/sh", args: ["-c", command] }
}

function killTree(child: ChildProcess, signal: NodeJS.Signals) {
  if (process.platform === "win32" && child.pid) {
    try {
      const killer = spawn(
        "taskkill",
        [
          "/pid",
          String(child.pid),
          "/T",
          ...(signal === "SIGKILL" ? ["/F"] : []),
        ],
        { stdio: "ignore", windowsHide: true },
      )
      const fallback = () => {
        try {
          child.kill(signal)
        } catch {
          // Process already exited.
        }
      }
      killer.once("error", fallback)
      killer.once("exit", (code) => {
        if (code !== 0) fallback()
      })
      killer.unref()
      return
    } catch {
      // Fall through to direct signal.
    }
  }
  if (process.platform !== "win32" && child.pid) {
    try {
      process.kill(-child.pid, signal)
      return
    } catch {
      // Group already exited.
    }
  }
  try {
    child.kill(signal)
  } catch {
    // Process already exited.
  }
}

export function createTerminalManager(): TerminalManagerShape {
  const entries = new Map<string, Entry>()
  const settledHistory = new Map<
    string,
    Pick<KillResult, "title" | "status" | "exit">
  >()
  const killInterest = new Map<string, number>()
  const listeners = new Set<() => void>()
  const idListeners = new Map<string, Set<() => void>>()
  const cleanup = new Set<Promise<void>>()
  let globalNotifyTimer: ReturnType<typeof setTimeout> | undefined
  let lastGlobalNotifyAt = 0
  let counter = 0
  let reserved = 0
  let disposed = false
  let spillDir: string | undefined | null
  let onSettled:
    | ((snap: TerminalSnapshot, consumed: boolean) => void)
    | undefined

  const runCleanup = (task: Promise<void>) => {
    cleanup.add(task)
    void task.catch(() => {}).finally(() => cleanup.delete(task))
  }

  const notifyGlobalListeners = () => {
    lastGlobalNotifyAt = Date.now()
    for (const listener of listeners) {
      try {
        listener()
      } catch {
        // UI listeners cannot change terminal lifecycle.
      }
    }
  }

  const notify = (id?: string) => {
    if (!globalNotifyTimer) {
      globalNotifyTimer = setTimeout(
        () => {
          globalNotifyTimer = undefined
          notifyGlobalListeners()
        },
        Math.max(
          0,
          GLOBAL_NOTIFY_INTERVAL_MS - (Date.now() - lastGlobalNotifyAt),
        ),
      )
    }
    if (id) {
      for (const listener of idListeners.get(id) ?? []) {
        try {
          listener()
        } catch {
          // UI listeners cannot change terminal lifecycle.
        }
      }
    }
  }

  const runningCount = () =>
    [...entries.values()].filter((entry) => entry.snapshot.status === "running")
      .length

  const addKillInterest = (ids: ReadonlyArray<string>) => {
    for (const id of ids) killInterest.set(id, (killInterest.get(id) ?? 0) + 1)
  }

  const releaseKillInterest = (ids: ReadonlyArray<string>) => {
    for (const id of ids) {
      const remaining = (killInterest.get(id) ?? 1) - 1
      if (remaining <= 0) killInterest.delete(id)
      else killInterest.set(id, remaining)
    }
  }

  const pruneSettled = () => {
    if (entries.size <= MAX_TRACKED) return
    const candidates = [...entries.values()]
      .filter(
        (entry) =>
          entry.snapshot.status !== "running" &&
          !killInterest.has(entry.snapshot.id),
      )
      .sort(
        (a, b) =>
          (a.snapshot.settledAt ?? a.snapshot.createdAt) -
          (b.snapshot.settledAt ?? b.snapshot.createdAt),
      )
    for (const entry of candidates) {
      if (entries.size <= MAX_TRACKED) break
      entries.delete(entry.snapshot.id)
    }
  }

  const flushSpillStreams = async (entry: Entry) => {
    const streams = entry.spillStreams
    entry.spillStreams = []
    const flush = Promise.all(
      streams.map(
        (stream) =>
          new Promise<void>((resolve) => {
            try {
              stream.end(resolve)
            } catch {
              resolve()
            }
          }),
      ),
    )
    let timer: NodeJS.Timeout | undefined
    const completed = await Promise.race([
      flush.then(() => true),
      new Promise<false>((resolve) => {
        timer = setTimeout(() => resolve(false), SPILL_FLUSH_TIMEOUT_MS)
      }),
    ])
    if (timer) clearTimeout(timer)
    if (completed) return
    entry.stdoutBuf.spillPath = undefined
    entry.stderrBuf.spillPath = undefined
    entry.snapshot.errorText ??=
      "Full-log spill flush timed out; full output may be incomplete"
  }

  const settle = (entry: Entry) => {
    const snap = entry.snapshot
    if (snap.status !== "running") return
    snap.settledAt = Date.now()
    snap.status = entry.killSignaled
      ? "killed"
      : entry.processErrored
        ? "failed"
        : snap.exitCode === 0
          ? "done"
          : "failed"
    settledHistory.set(snap.id, {
      title: snap.title,
      status: snap.status,
      exit: formatExit(snap),
    })
    while (settledHistory.size > MAX_SETTLED_HISTORY) {
      const oldest = settledHistory.keys().next().value
      if (oldest === undefined) break
      settledHistory.delete(oldest)
    }
    const consumed = (killInterest.get(snap.id) ?? 0) > 0
    entry.settled.resolve()
    notify(snap.id)
    try {
      if (!disposed) onSettled?.(snap, consumed)
    } catch {
      // Session may be gone.
    }
    pruneSettled()
  }

  const settleAfterFlush = (entry: Entry) => {
    if (entry.settling || entry.snapshot.status !== "running") return
    entry.settling = true
    runCleanup(
      flushSpillStreams(entry)
        .then(() => settle(entry))
        .catch((error) => {
          entry.snapshot.errorText ??= boundedError(error)
          settle(entry)
        }),
    )
  }

  const closeEntry = (entry: Entry) => {
    if (entry.closing) return entry.closing
    entry.closing = (async () => {
      if (!entry.stdioClosed) {
        entry.killSignaled ||=
          !entry.exited && entry.snapshot.status === "running"
        killTree(entry.child, "SIGTERM")
        if (
          !(await waitForClose(
            entry.child,
            () => entry.stdioClosed,
            FORCE_KILL_AFTER_MS,
          ))
        ) {
          killTree(entry.child, "SIGKILL")
          await waitForClose(entry.child, () => entry.stdioClosed, 500)
        }
      }
      if (entry.snapshot.status === "running") {
        await withTimeout(entry.settled.promise, SETTLE_GRACE_MS)
      }
      if (entry.snapshot.status === "running" && !entry.settling) {
        if (!entry.stdioClosed) {
          entry.snapshot.errorText ??=
            "stdio did not close after termination; output may be incomplete"
        }
        entry.settling = true
        await flushSpillStreams(entry)
        settle(entry)
      }
    })()
    return entry.closing
  }

  const scheduleExitCleanup = (entry: Entry) => {
    if (entry.exitCleanupStarted) return
    entry.exitCleanupStarted = true
    runCleanup(
      new Promise<void>((resolve) => setTimeout(resolve, SETTLE_GRACE_MS)).then(
        () => {
          if (entry.snapshot.status !== "running" || entry.stdioClosed) return
          return withTimeout(closeEntry(entry), STOP_TIMEOUT_MS).then(() => {})
        },
      ),
    )
  }

  const resolveSpillDir = () => {
    if (spillDir !== undefined) return spillDir ?? undefined
    try {
      const base = path.join(os.tmpdir(), "pi-background-terminals")
      fs.mkdirSync(base, { recursive: true, mode: 0o700 })
      fs.chmodSync(base, 0o700)
      spillDir = fs.mkdtempSync(path.join(base, "session-"))
      fs.chmodSync(spillDir, 0o700)
    } catch {
      spillDir = null
    }
    return spillDir ?? undefined
  }

  const makeSpill = (
    entryForId: () => Entry | undefined,
    id: string,
    stream: "stdout" | "stderr",
    resumeSource: () => void,
  ) => {
    const dir = resolveSpillDir()
    if (!dir) return undefined
    const spillPath = path.join(dir, `${id}.${stream}.log`)
    try {
      const file = fs.createWriteStream(spillPath, { flags: "a", mode: 0o600 })
      let broken = false
      let capped = false
      let writtenBytes = 0
      file.on("error", (error) => {
        broken = true
        resumeSource()
        const entry = entryForId()
        if (!entry) return
        const buffer = stream === "stdout" ? entry.stdoutBuf : entry.stderrBuf
        buffer.spillPath = undefined
        entry.snapshot.errorText ??= bounded(
          `Full-log spill to ${spillPath} failed: ${boundedError(error)}`,
        )
      })
      return {
        spillPath,
        file,
        write: (chunk: string) => {
          if (broken || capped || file.writableEnded) return true
          const chunkBytes = Buffer.byteLength(chunk, "utf8")
          if (writtenBytes + chunkBytes > MAX_SPILL_BYTES_PER_STREAM) {
            capped = true
            const entry = entryForId()
            if (entry) {
              const buffer =
                stream === "stdout" ? entry.stdoutBuf : entry.stderrBuf
              buffer.spillPath = undefined
              entry.snapshot.errorText ??= bounded(
                `${stream} full-log spill reached the ${MAX_SPILL_BYTES_PER_STREAM}-byte safety limit`,
              )
            }
            return true
          }
          writtenBytes += chunkBytes
          const accepted = file.write(chunk)
          if (!accepted) file.once("drain", resumeSource)
          return accepted
        },
      }
    } catch {
      return undefined
    }
  }

  const start = async (options: StartOptions) => {
    if (disposed)
      throw new SpawnError("Background terminal manager is shutting down.")
    if (runningCount() + reserved >= MAX_RUNNING) {
      throw new ConcurrencyLimitError(
        `Max ${MAX_RUNNING} background terminals can run concurrently. Stop one with bg_kill before starting another.`,
      )
    }
    reserved++
    try {
      const { shell, args } = shellInvocation(options.command)
      let child: ChildProcess
      try {
        child = spawn(shell, args, {
          cwd: options.cwd,
          env: process.env,
          stdio: ["ignore", "pipe", "pipe"],
          detached: process.platform !== "win32",
        })
      } catch (error) {
        throw new SpawnError(boundedError(error))
      }

      const id = `bt-${++counter}`
      const entryForId = () => entries.get(id)
      const stdoutSpill = makeSpill(entryForId, id, "stdout", () =>
        child.stdout?.resume(),
      )
      const stderrSpill = makeSpill(entryForId, id, "stderr", () =>
        child.stderr?.resume(),
      )
      const stdoutBuf = new OutputBuffer(
        RETAINED_PER_STREAM,
        stdoutSpill?.write,
      )
      const stderrBuf = new OutputBuffer(
        RETAINED_PER_STREAM,
        stderrSpill?.write,
      )
      stdoutBuf.spillPath = stdoutSpill?.spillPath
      stderrBuf.spillPath = stderrSpill?.spillPath
      const snapshot: MutableSnapshot = {
        id,
        command: options.command,
        title: options.title,
        cwd: options.cwd,
        pid: child.pid,
        status: "running",
        createdAt: Date.now(),
        get stdout() {
          return stdoutBuf.view()
        },
        get stderr() {
          return stderrBuf.view()
        },
      }
      const entry: Entry = {
        snapshot,
        child,
        stdoutBuf,
        stderrBuf,
        spillStreams: [stdoutSpill?.file, stderrSpill?.file].filter(
          (file): file is fs.WriteStream => file !== undefined,
        ),
        killSignaled: false,
        processErrored: false,
        exited: false,
        stdioClosed: false,
        settling: false,
        exitCleanupStarted: false,
        settled: deferred(),
      }

      child.stdout?.setEncoding("utf8")
      child.stdout?.on("data", (chunk: string) => {
        if (!stdoutBuf.push(chunk)) child.stdout?.pause()
        notify(id)
      })
      child.stderr?.setEncoding("utf8")
      child.stderr?.on("data", (chunk: string) => {
        if (!stderrBuf.push(chunk)) child.stderr?.pause()
        notify(id)
      })
      child.once("error", (error) => {
        entry.processErrored = true
        snapshot.errorText ??= boundedError(error)
        entry.exited = true
        settleAfterFlush(entry)
      })
      child.once("exit", (code, signal) => {
        entry.exited = true
        snapshot.exitCode = code ?? undefined
        snapshot.signal = signal ?? undefined
        scheduleExitCleanup(entry)
      })
      child.once("close", (code, signal) => {
        entry.exited = true
        entry.stdioClosed = true
        if (!entry.processErrored) {
          snapshot.exitCode ??= code ?? undefined
          snapshot.signal ??= signal ?? undefined
        }
        settleAfterFlush(entry)
      })

      if (disposed) {
        await closeEntry(entry)
        throw new SpawnError(
          "Background terminal manager shut down while starting.",
        )
      }
      entries.set(id, entry)
      notify(id)
      return snapshot as TerminalSnapshot
    } finally {
      reserved--
      notify()
    }
  }

  const status = async (id: string) => {
    const entry = entries.get(id)
    if (!entry) {
      throw new UnknownTerminalError(
        `Unknown terminal id "${id}". Known: ${[...entries.keys()].join(", ") || "none"}.`,
      )
    }
    return entry.snapshot as TerminalSnapshot
  }

  const killEntry = (entry: Entry) => {
    if (entry.snapshot.status !== "running") return
    runCleanup(withTimeout(closeEntry(entry), STOP_TIMEOUT_MS).then(() => {}))
  }

  const kill = async (ids: ReadonlyArray<string>) => {
    const unique = [...new Set(ids)]
    const byId = new Map(
      unique
        .map((id) => entries.get(id))
        .filter((entry): entry is Entry => entry !== undefined)
        .map((entry) => [entry.snapshot.id, entry]),
    )
    const running = [...byId.values()].filter(
      (entry) => entry.snapshot.status === "running",
    )
    const runningIds = running.map((entry) => entry.snapshot.id)
    addKillInterest(runningIds)
    try {
      for (const entry of running) killEntry(entry)
      await Promise.all(running.map((entry) => entry.settled.promise))
      return unique.map((id): KillResult => {
        const snapshot = byId.get(id)?.snapshot
        const history = settledHistory.get(id)
        const finalStatus = snapshot?.status ?? history?.status ?? "killed"
        const wasRunning = runningIds.includes(id)
        return {
          id,
          title: snapshot?.title ?? history?.title ?? "?",
          status: finalStatus,
          wasRunning,
          killed: wasRunning && finalStatus === "killed",
          exit: snapshot ? formatExit(snapshot) : (history?.exit ?? "unknown"),
        }
      })
    } finally {
      releaseKillInterest(runningIds)
      pruneSettled()
    }
  }

  const disposeAll = async () => {
    if (disposed) return
    disposed = true
    if (globalNotifyTimer) clearTimeout(globalNotifyTimer)
    globalNotifyTimer = undefined
    const all = [...entries.values()]
    entries.clear()
    await Promise.all(
      all.map((entry) => withTimeout(closeEntry(entry), STOP_TIMEOUT_MS)),
    )
    const deadline = Date.now() + STOP_TIMEOUT_MS
    while (cleanup.size > 0 && Date.now() < deadline) {
      await withTimeout(Promise.allSettled(cleanup), deadline - Date.now())
    }
    const dir = spillDir
    spillDir = null
    if (dir) fs.rmSync(dir, { recursive: true, force: true })
    notify()
  }

  const view: TerminalReadModel = {
    list: () => [...entries.values()].map((entry) => entry.snapshot),
    get: (id) => entries.get(id)?.snapshot,
    size: () => entries.size,
    subscribe: (listener) => {
      listeners.add(listener)
      return () => listeners.delete(listener)
    },
    subscribeTo: (id, listener) => {
      let subscribers = idListeners.get(id)
      if (!subscribers) {
        subscribers = new Set()
        idListeners.set(id, subscribers)
      }
      subscribers.add(listener)
      return () => {
        subscribers.delete(listener)
        if (subscribers.size === 0) idListeners.delete(id)
      }
    },
    requestKill: (id) => {
      const entry = entries.get(id)
      if (entry) killEntry(entry)
    },
    setOnSettled: (hook) => {
      onSettled = hook
    },
  }

  return { start, status, kill, list: view.list, disposeAll, view }
}
