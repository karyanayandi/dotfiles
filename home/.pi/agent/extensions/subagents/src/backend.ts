/** Shared promise-based backend contracts. */

import type {
  BackendName,
  SpawnTask,
  SubagentEvent,
  SubagentMeta,
} from "./domain.ts"

export class AsyncEventQueue<T> implements AsyncIterable<T> {
  #items: T[] = []
  #waiters: Array<(result: IteratorResult<T>) => void> = []
  #closed = false

  push(item: T) {
    const waiter = this.#waiters.shift()
    if (waiter) waiter({ value: item, done: false })
    else if (!this.#closed) this.#items.push(item)
  }

  clear() {
    const items = this.#items
    this.#items = []
    return items
  }

  close() {
    if (this.#closed) return
    this.#closed = true
    for (const waiter of this.#waiters.splice(0))
      waiter({ done: true, value: undefined })
  }

  async next(): Promise<IteratorResult<T>> {
    const item = this.#items.shift()
    if (item !== undefined) return { value: item, done: false }
    if (this.#closed) return { done: true, value: undefined }
    return new Promise((resolve) => this.#waiters.push(resolve))
  }

  [Symbol.asyncIterator]() {
    return this
  }
}

export interface BackendCapabilities {
  readonly steering: boolean
  readonly modelSelection: boolean
  readonly reasoningEffort: boolean
}

export interface SubagentSession {
  readonly meta: () => SubagentMeta
  readonly events: AsyncIterable<SubagentEvent>
  send(text: string): Promise<void>
  readonly interrupt: () => Promise<void>
  /** Ends events and kills/releases backend-owned resources. Idempotent. */
  readonly dispose: () => Promise<void>
}

export interface SubagentBackend {
  readonly name: BackendName
  readonly capabilities: BackendCapabilities
  readonly available: () => Promise<boolean>
  spawn(task: SpawnTask): Promise<SubagentSession>
}
