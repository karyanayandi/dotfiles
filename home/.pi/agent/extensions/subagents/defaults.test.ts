import assert from "node:assert/strict"
import test from "node:test"
import {
  DEFAULT_SUBAGENT_DEFAULTS,
  parseSubagentDefaults,
} from "./src/defaults.ts"

test("subagent defaults retain valid harnesses and models", () => {
  assert.deepEqual(
    parseSubagentDefaults({
      harness: "codex",
      models: { pi: "openai-codex/gpt-5.6-sol", codex: "gpt-5.6-sol" },
    }),
    {
      harness: "codex",
      models: { pi: "openai-codex/gpt-5.6-sol", codex: "gpt-5.6-sol" },
    },
  )
  assert.deepEqual(
    parseSubagentDefaults({ harness: "other" }),
    DEFAULT_SUBAGENT_DEFAULTS,
  )
})
