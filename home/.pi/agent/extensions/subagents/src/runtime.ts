/** Promise entry points for subagent tools. */

import type { SubagentBackend } from "./backend.ts"
import { piBackend } from "./backends/pi.ts"
import { createSubagentManager, type SubagentManager } from "./manager.ts"

export interface SubagentRuntime {
  readonly manager: SubagentManager
  dispose(): Promise<void>
}

export function createSubagentRuntime(
  backend: SubagentBackend = piBackend,
): SubagentRuntime {
  const manager = createSubagentManager(backend)

  return { manager, dispose: () => manager.disposeAll() }
}

export async function runTool<A>(
  operation: Promise<A>,
  options: { signal?: AbortSignal; interruptMessage?: string } = {},
) {
  const { signal } = options

  if (!signal) return operation

  if (signal.aborted)
    throw new Error(options.interruptMessage ?? "Operation was aborted.")

  return await new Promise<A>((resolve, reject) => {
    const onAbort = () =>
      reject(new Error(options.interruptMessage ?? "Operation was aborted."))

    signal.addEventListener("abort", onAbort, { once: true })
    void operation
      .then(resolve, reject)
      .finally(() => signal.removeEventListener("abort", onAbort))
  })
}
