/** Promise entry points for subagent tools. */

import type { SubagentBackend } from "./backend.ts"
import { codexBackend } from "./backends/codex.ts"
import { piBackend } from "./backends/pi.ts"
import type { BackendName } from "./domain.ts"
import { createSubagentManager, type SubagentManagerShape } from "./manager.ts"

export interface SubagentRuntime {
  readonly manager: SubagentManagerShape
  dispose(): Promise<void>
}

export function createSubagentRuntime(
  backends: readonly SubagentBackend[] = [piBackend, codexBackend],
): SubagentRuntime {
  const registry = new Map<BackendName, SubagentBackend>(
    backends.map((backend) => [backend.name, backend]),
  )
  const manager = createSubagentManager(registry)
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
  return new Promise<A>((resolve, reject) => {
    const onAbort = () =>
      reject(new Error(options.interruptMessage ?? "Operation was aborted."))
    signal.addEventListener("abort", onAbort, { once: true })
    void operation
      .then(resolve, reject)
      .finally(() => signal.removeEventListener("abort", onAbort))
  })
}
