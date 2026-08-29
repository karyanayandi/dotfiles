# Building pi extensions with TypeScript promises

## Rule

Use ordinary TypeScript and native platform APIs. Keep async work as `Promise`s; use `AbortSignal` for cancellation and `Error` subclasses when callers need to distinguish failures.

Do not add an effect runtime, compiler patch, service container, stream library, or queue dependency unless native APIs demonstrably cannot meet a requirement.

## Toolchain

Each extension uses TypeScript directly:

```json
{
  "scripts": {
    "check": "tsc --noEmit -p ."
  }
}
```

No TypeScript plugin or prepare script is required.

## Async boundary

Tool handlers are `async` functions. Pass tool-provided `AbortSignal`s to APIs that accept them. For operations without native signal support, race or subscribe to the signal and always remove listeners when work settles.

```ts
async function load(url: string, signal: AbortSignal) {
  const response = await fetch(url, { signal })
  if (!response.ok) throw new Error(`Request failed: ${response.status}`)
  return response.json()
}
```

Use `AbortSignal.timeout(ms)` or `AbortSignal.any([...])` for bounded work. `Promise.all` is enough for independent work; `Promise.allSettled` is useful during cleanup.

## Resource ownership

Code that creates a child process, timer, listener, temporary file, or async iterator owns cleanup:

- Kill child processes in `finally` after timeout or cancellation.
- Clear timers and detach listeners when promise settles.
- Close async queues during shutdown so waiters complete.
- Remove temporary files after use, including failures.

Keep cleanup local to creator. Do not create a global runtime only to centralize cleanup.

## Errors

Throw normal `Error`s. Use small subclasses only where branching needs a stable category:

```ts
class SpawnError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options)
    this.name = "SpawnError"
  }
}
```

Preserve original failure through `{ cause }`. Convert errors to tool-facing messages only at tool boundary.

## Verify

```sh
bun run check
bun run test
bun run fmt:check
bun run lint
```

Test cancellation and cleanup where code starts processes, polls, or owns a queue.
