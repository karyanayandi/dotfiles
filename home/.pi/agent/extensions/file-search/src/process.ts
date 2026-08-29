import { spawn } from "node:child_process"
import { createWriteStream } from "node:fs"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { dirname, join } from "node:path"
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  truncateHead,
} from "@earendil-works/pi-coding-agent"
import type { CapturedOutput } from "./output.ts"

const STDERR_MAX_BYTES = 64 * 1024

interface PreviewState {
  readonly decoder: TextDecoder
  preview: string
  totalBytes: number
  lineBreaks: number
  trailingLineBreaks: number
  truncated: boolean
}

function makePreviewState(): PreviewState {
  return {
    decoder: new TextDecoder(),
    preview: "",
    totalBytes: 0,
    lineBreaks: 0,
    trailingLineBreaks: 0,
    truncated: false,
  }
}

function observeStdout(state: PreviewState, chunk: Uint8Array) {
  state.totalBytes += chunk.byteLength
  for (const byte of chunk) {
    if (byte === 0x0a) {
      state.lineBreaks++
      state.trailingLineBreaks++
    } else {
      state.trailingLineBreaks = 0
    }
  }

  if (state.truncated) return
  state.preview += state.decoder.decode(chunk, { stream: true })
  const truncation = truncateHead(state.preview, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  })
  if (truncation.truncated) {
    state.preview = truncation.content
    state.truncated = true
  }
}

function finishStdout(state: PreviewState, fullOutputPath: string) {
  if (!state.truncated) state.preview += state.decoder.decode()
  const totalBytes = state.totalBytes - state.trailingLineBreaks
  const lineCount =
    totalBytes === 0 ? 0 : state.lineBreaks - state.trailingLineBreaks + 1
  return {
    preview: state.preview,
    lineCount,
    totalBytes,
    truncated: state.truncated,
    fullOutputPath: state.truncated ? fullOutputPath : undefined,
  } satisfies CapturedOutput
}

function abortError() {
  return new DOMException("The operation was aborted", "AbortError")
}

export async function executeSearchProcess(options: {
  readonly command: string
  readonly args: readonly string[]
  readonly cwd: string
  readonly tempPrefix: string
  readonly signal?: AbortSignal
}) {
  const directory = await mkdtemp(join(tmpdir(), options.tempPrefix))
  const fullOutputPath = join(directory, "output.txt")
  let retainDirectory = false

  try {
    if (options.signal?.aborted) throw abortError()

    const process = spawn(options.command, options.args, {
      cwd: options.cwd,
      stdio: ["ignore", "pipe", "pipe"],
    })
    const output = createWriteStream(fullOutputPath)
    const preview = makePreviewState()
    const stderr: Buffer[] = []
    let stderrBytes = 0

    const close = new Promise<number | null>((resolve, reject) => {
      process.once("error", reject)
      process.once("close", resolve)
    })
    const outputClosed = new Promise<void>((resolve, reject) => {
      output.once("error", reject)
      output.once("close", resolve)
    })
    const abort = () => process.kill()
    options.signal?.addEventListener("abort", abort, { once: true })
    if (options.signal?.aborted) abort()

    process.stdout.on("data", (chunk: Buffer) => {
      observeStdout(preview, chunk)
      if (!output.write(chunk)) process.stdout.pause()
    })
    output.on("drain", () => process.stdout.resume())
    process.stdout.once("end", () => output.end())
    process.stderr.on("data", (chunk: Buffer) => {
      if (stderrBytes >= STDERR_MAX_BYTES) return
      const captured = chunk.subarray(0, STDERR_MAX_BYTES - stderrBytes)
      stderr.push(captured)
      stderrBytes += captured.byteLength
    })

    try {
      const code = await close
      await outputClosed
      if (options.signal?.aborted) throw abortError()
      const captured = finishStdout(preview, fullOutputPath)
      retainDirectory = captured.truncated
      return {
        code: code ?? -1,
        stderr: Buffer.concat(stderr, stderrBytes).toString("utf8"),
        output: captured,
      }
    } finally {
      options.signal?.removeEventListener("abort", abort)
      if (!output.closed) output.destroy()
      if (!process.killed && options.signal?.aborted) process.kill()
    }
  } finally {
    if (!retainDirectory) await rm(directory, { recursive: true, force: true })
  }
}

export async function discardCapturedOutput(output: CapturedOutput) {
  if (!output.fullOutputPath) return
  await rm(dirname(output.fullOutputPath), { recursive: true, force: true })
}
