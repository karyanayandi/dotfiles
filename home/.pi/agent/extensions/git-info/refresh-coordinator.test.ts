import assert from "node:assert/strict"
import test from "node:test"
import { makeRefreshCoordinator } from "./src/refresh-coordinator.ts"

function deferred() {
  let resolve: () => void = () => {}
  const promise = new Promise<void>((done) => {
    resolve = done
  })
  return { promise, resolve }
}

test("an explicit refresh waits for an active background refresh", async () => {
  const coordinator = makeRefreshCoordinator()
  let state = 0
  const started = deferred()
  const release = deferred()

  const background = coordinator.run(async () => {
    started.resolve()
    await release.promise
    state = 1
  })

  await started.promise
  await coordinator.runIfIdle(async () => {
    state = 99
  })

  const forced = coordinator.run(async () => {
    state += 1
    return state
  })

  release.resolve()
  await background
  assert.equal(await forced, 2)
  assert.equal(state, 2)
})

test("failed refresh does not block later refreshes", async () => {
  const coordinator = makeRefreshCoordinator()

  await assert.rejects(
    coordinator.run(async () => Promise.reject(new Error("no"))),
  )
  assert.equal(await coordinator.run(async () => 1), 1)
})
