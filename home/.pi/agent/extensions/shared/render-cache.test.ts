import assert from "node:assert/strict"
import { test } from "node:test"
import { cacheRenderer } from "./render-cache.ts"

test("caches render output by width until invalidated", () => {
  let renders = 0
  let invalidations = 0
  const component = cacheRenderer(
    (width) => {
      renders += 1
      return [`${width}`]
    },
    () => {
      invalidations += 1
    },
  )

  const first = component.render(80)
  assert.equal(component.render(80), first)
  assert.deepEqual(component.render(40), ["40"])
  assert.equal(renders, 2)

  component.invalidate()
  assert.deepEqual(component.render(80), ["80"])
  assert.equal(renders, 3)
  assert.equal(invalidations, 1)
})
