import { spawn } from "node:child_process"

const MAX_STREAM_CHARS = 10 * 1_024 * 1_024
const TRUNCATED_MARKER = "\n[command output truncated]\n"

function appendBounded(current: string, chunk: string) {
  if (current.endsWith(TRUNCATED_MARKER)) return current
  if (current.length + chunk.length <= MAX_STREAM_CHARS) return current + chunk
  const remaining = Math.max(0, MAX_STREAM_CHARS - current.length)
  return `${current}${chunk.slice(0, remaining)}${TRUNCATED_MARKER}`
}

export interface CommandResult {
  code: number
  stderr: string
  stdout: string
}

function appendCommandFailure(stderr: string, command: string, error: Error) {
  const failure = `Failed to run ${command}: ${error.message}`
  return stderr ? `${stderr.trimEnd()}\n${failure}` : failure
}

function abortError() {
  return new Error("Operation was aborted.")
}

export function runCommand(
  command: string,
  args: string[],
  cwd: string,
  timeout: number,
  signal?: AbortSignal,
) {
  return new Promise<CommandResult>((resolve, reject) => {
    if (signal?.aborted) {
      reject(abortError())
      return
    }

    let stderr = ""
    let stdout = ""
    let settled = false
    const child = spawn(command, args, {
      cwd,
      stdio: ["ignore", "pipe", "pipe"],
    })

    const cleanup = () => {
      clearTimeout(timeoutTimer)
      signal?.removeEventListener("abort", onAbort)
    }
    const finish = (result: CommandResult) => {
      if (settled) return
      settled = true
      cleanup()
      resolve(result)
    }
    const fail = (error: Error) => {
      if (settled) return
      settled = true
      cleanup()
      reject(error)
    }
    const terminate = () => {
      if (child.exitCode !== null || child.signalCode !== null) return
      child.kill()
      const forceKillTimer = setTimeout(() => child.kill("SIGKILL"), 5_000)
      forceKillTimer.unref()
    }
    const onAbort = () => {
      terminate()
      fail(abortError())
    }
    const timeoutTimer = setTimeout(() => {
      terminate()
      finish({ code: -1, stderr, stdout })
    }, timeout)

    child.stdout.setEncoding("utf8")
    child.stderr.setEncoding("utf8")
    child.stdout.on("data", (chunk: string) => {
      stdout = appendBounded(stdout, chunk)
    })
    child.stderr.on("data", (chunk: string) => {
      stderr = appendBounded(stderr, chunk)
    })
    child.once("error", (error) => {
      finish({
        code: 1,
        stderr: appendCommandFailure(stderr, command, error),
        stdout,
      })
    })
    child.once("close", (code) => {
      finish({ code: code ?? 1, stderr, stdout })
    })

    signal?.addEventListener("abort", onAbort, { once: true })
  })
}
