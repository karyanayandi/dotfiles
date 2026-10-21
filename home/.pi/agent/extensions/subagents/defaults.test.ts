import assert from "node:assert/strict"
import test from "node:test"
import {
  DEFAULT_SUBAGENT_DEFAULTS,
  parseSubagentDefaults,
} from "./src/defaults.ts"

void test("subagent defaults keep Pi model and reasoning effort", () => {
  assert.deepEqual(
    parseSubagentDefaults({
      model: " provider/model ",
      reasoningEffort: "medium",
    }),
    { model: "provider/model", reasoningEffort: "medium" },
  )
  assert.deepEqual(parseSubagentDefaults({}), DEFAULT_SUBAGENT_DEFAULTS)
})

void test("legacy defaults keep Pi values regardless of selected harness", () => {
  for (const harness of ["pi", "codex", "other"]) {
    assert.deepEqual(
      parseSubagentDefaults({
        harness,
        models: { pi: " provider/model ", codex: "ignored-model" },
        reasoningEfforts: { pi: "medium", codex: "high" },
      }),
      { model: "provider/model", reasoningEffort: "medium" },
    )
  }

  assert.deepEqual(
    parseSubagentDefaults({
      harness: "codex",
      models: { codex: "ignored-model" },
    }),
    DEFAULT_SUBAGENT_DEFAULTS,
  )
})

void test("current defaults take precedence over legacy Pi values", () => {
  assert.deepEqual(
    parseSubagentDefaults({
      model: "new/model",
      reasoningEffort: "off",
      models: { pi: "old/model" },
      reasoningEfforts: { pi: "high" },
    }),
    { model: "new/model", reasoningEffort: "off" },
  )
})

void test("invalid defaults fall back to parent inheritance", () => {
  for (const value of [
    null,
    [],
    "pi",
    42,
    { model: "   ", reasoningEffort: "invalid" },
    { model: 10, reasoningEffort: false },
    { models: [], reasoningEfforts: "high" },
  ]) {
    assert.deepEqual(parseSubagentDefaults(value), DEFAULT_SUBAGENT_DEFAULTS)
  }
})
