# Promise and Node notes for Subagents

`extensions/subagents` uses native promises, async iterables, `AbortController`, and Node child processes.

## Core contracts

- `Backend` in `src/backend.ts` exposes `available()`, `spawn()`, and a `SubagentSession`.
- `SubagentSession` exposes current metadata, an async event stream, `send()`, `interrupt()`, and `dispose()`.
- `createSubagentManager()` in `src/manager.ts` owns active entries, concurrency reservation, result delivery, and shutdown.
- `src/domain.ts` contains snapshots, events, task input, and typed `Error` subclasses.

## Cancellation and timeouts

Accept `AbortSignal` at caller boundary. Combine deadline and caller cancellation with `AbortSignal.any()` when API supports signals. Child-process shutdown uses explicit SIGTERM, bounded wait, then SIGKILL if needed.

A cancelled wait must not cancel its running subagent. A cancelled session must stop its process and close its event queue.

## Async event queues

`AsyncEventQueue` provides backpressure-free in-memory event delivery for one session. Call `close()` exactly once during cleanup; queued items drain before readers see completion.

## Errors

Use `SpawnError`, `SendError`, `BackendUnavailableError`, and `ConcurrencyLimitError` from `src/domain.ts` when caller behavior differs. Wrap unknown failures with `{ cause }` rather than losing source error.

## Cleanup

Backend owns its child session. Manager owns backend session lifecycle. `disposeAll()` interrupts all running entries, waits only up to shutdown limits, closes queues, and notifies listeners.

## Checks

```sh
bun run check
bun run test
bun run test:live
```
