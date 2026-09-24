import assert from "node:assert/strict"
import test from "node:test"

import { expandDollarSkill, searchSkills } from "./index.ts"

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

test("searches skill names and descriptions with literal case-insensitive terms", () => {
  const commands = [
    { name: "skill:react-doctor", description: "Diagnose React issues" },
    {
      name: "skill:accessibility",
      description: "Keyboard navigation and WCAG",
    },
  ]

  assert.deepEqual(searchSkills("doctor", commands), ["react-doctor"])
  assert.deepEqual(searchSkills("KEYBOARD", commands), ["accessibility"])
  assert.deepEqual(searchSkills("WCAG", commands), ["accessibility"])
  assert.deepEqual(searchSkills(".", commands), [])
  assert.deepEqual(searchSkills("0", commands), [])
  assert.deepEqual(searchSkills("", commands), [
    "react-doctor",
    "accessibility",
  ])
})
