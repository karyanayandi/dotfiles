# background-terminals implementation guide

## Architecture

This extension runs detached shell commands. It keeps bounded output for `bg_start`, `bg_status`, `bg_list`, and `bg_kill`.

- `index.ts` registers tools, UI, lifecycle hooks, and result delivery.
- `src/manager.ts` owns process entries, concurrency limits, output capture, settlement, listeners, and cleanup.
- `src/runtime.ts` creates one `TerminalManagerShape` for extension lifetime and exposes `runTool` for tool errors.
- `src/domain.ts` defines snapshots and typed errors.
- `src/output.ts` keeps a bounded tail and can write full output to disk.

Use plain TypeScript, native promises, `AbortSignal`, and `node:child_process`. No async runtime or TypeScript compiler plugin.

## Manager invariants

- At most `MAX_RUNNING` commands run concurrently.
- Every process settles once: exit, spawn failure, or kill.
- `kill()` sends SIGTERM, waits for its deadline, then sends SIGKILL if needed.
- Process-group kill is used on POSIX so descendants do not leak.
- Memory output stays bounded. Spill files retain full output when enabled.
- Settled results deliver once unless consumed by a status or kill request.
- `disposeAll()` stops all tracked processes and removes private spill files.

## Promise patterns

`start`, `status`, `kill`, and `disposeAll` are async. Use `Promise.allSettled` for parallel best-effort cleanup. Use local timeout helpers for child shutdown and spill flushing. Detach listeners and clear timers after completion.

Tool-handler cancellation stops request waiting, not detached command lifetime. A background terminal continues after `bg_start` returns. Only `bg_kill`, shutdown, or natural exit settles it.

## Tests

```sh
bun run check
bun run test
```

Tests cover stream capture, settlement, signal escalation, process-tree cleanup, concurrency, output retention, result delivery, and dashboard rendering.

## Change checklist

1. Preserve one-time settlement and result delivery.
2. Keep timeouts bounded.
3. For lifecycle changes, test cancellation and child-process cleanup.
4. Run check, tests, format, and lint before merging.
