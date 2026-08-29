/** Serializes explicit refreshes while allowing background refreshes to coalesce. */
export function makeRefreshCoordinator() {
  let pending = 0
  let tail = Promise.resolve()

  const run = <T>(task: () => Promise<T>) => {
    pending += 1
    const result = tail.then(task)
    tail = result.then(
      () => undefined,
      () => undefined,
    )
    return result.finally(() => {
      pending -= 1
    })
  }

  return {
    run,
    runIfIdle: (task: () => Promise<unknown>) => {
      if (pending > 0) return Promise.resolve()
      return run(task).then(() => undefined)
    },
  }
}
