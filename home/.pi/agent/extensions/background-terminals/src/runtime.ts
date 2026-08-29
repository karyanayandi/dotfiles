/** Plain Promise boundary for tool handlers. */

import { createTerminalManager, type TerminalManagerShape } from "./manager.ts"

export interface TerminalRuntime {
  readonly manager: TerminalManagerShape
  dispose(): Promise<void>
}

export function createTerminalRuntime(): TerminalRuntime {
  const manager = createTerminalManager()
  return { manager, dispose: () => manager.disposeAll() }
}

export function runTool<A>(
  operation: Promise<A>,
  options: { signal?: AbortSignal; interruptMessage?: string } = {},
) {
  const { signal, interruptMessage = "Operation was aborted." } = options
  if (!signal) return operation
  if (signal.aborted) {
    void operation.catch(() => {})
    return Promise.reject(new Error(interruptMessage))
  }
  return new Promise<A>((resolve, reject) => {
    const onAbort = () => reject(new Error(interruptMessage))
    signal.addEventListener("abort", onAbort, { once: true })
    void operation
      .then(resolve, reject)
      .finally(() => signal.removeEventListener("abort", onAbort))
  })
}
