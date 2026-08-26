import assert from "node:assert/strict"
import test from "node:test"

import { expandDollarSkill } from "./index.ts"

test("expands recognized dollar skills", () => {
  assert.equal(
    expandDollarSkill("$react-doctor src", ["react-doctor"]),
    "/skill:react-doctor src",
  )
  assert.equal(
    expandDollarSkill("  $react-doctor", ["react-doctor"]),
    "  /skill:react-doctor",
  )
})

test("leaves unknown or inline dollar text alone", () => {
  assert.equal(expandDollarSkill("$missing", ["react-doctor"]), undefined)
  assert.equal(
    expandDollarSkill("Use $react-doctor", ["react-doctor"]),
    undefined,
  )
})
