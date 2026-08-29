# background-terminals implementation guide

## Architecture

This extension runs detached shell commands and keeps bounded output for `bg_start`, `bg_status`, `bg_list`, and `bg_kill`.

- `index.ts` registers tools, UI, lifecycle hooks, and result delivery.
- `src/manager.ts` owns process entries, concurrency limits, output capture, settlement, listeners, and cleanup.
- `src/runtime.ts` creates one `TerminalManagerShape` for extension lifetime and exposes `runTool` for consistent tool errors.
- `src/domain.ts` defines snapshots and typed errors.
- `src/output.ts` retains a bounded tail and optionally spills complete output to disk.

Use plain TypeScript, native promises, `AbortSignal`, and `node:child_process`. No async runtime or TypeScript compiler plugin is needed.

## Manager invariants

- At most `MAX_RUNNING` commands run concurrently.
- Every process settles once: exit, spawn failure, or kill.
- `kill()` sends SIGTERM, waits within bound, then escalates to SIGKILL when needed.
- Process-group kill is used on POSIX so descendants do not leak.
- Output stays bounded in memory; spill files preserve full output when enabled.
- Settled results deliver once unless consumed by a status or kill request.
- `disposeAll()` stops all tracked processes and removes private spill files.

## Promise patterns

`start`, `status`, `kill`, and `disposeAll` are async methods. Use `Promise.allSettled` for best-effort parallel cleanup. Use small local timeout helpers around child shutdown and spill flushing. Always detach listeners and clear timers after completion.

Cancellation from tool handler applies to request waiting, not detached command lifetime. A running background terminal continues after `bg_start` returns; only `bg_kill`, shutdown, or natural exit settles it.

## Tests

```sh
bun run check
bun run test
```

Tests cover stream capture, terminal settlement, signal escalation, process-tree cleanup, concurrency, output retention, result delivery, and dashboard rendering.

## Change checklist

1. Preserve one-time settlement and result delivery.
2. Keep timeout values bounded.
3. Test cancellation and child-process cleanup for lifecycle changes.
4. Run check, tests, format, and lint before merging.
