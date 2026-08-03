import assert from "node:assert/strict"
import test from "node:test"
import { DEFAULT_SUMMARY_CONFIG, parseSummaryConfig } from "./src/config.ts"

test("summary config defaults to Copilot gpt-4.1", () => {
  assert.deepEqual(parseSummaryConfig(undefined), DEFAULT_SUMMARY_CONFIG)
  assert.deepEqual(DEFAULT_SUMMARY_CONFIG, {
    provider: "github-copilot",
    model: "gpt-4.1",
    reasoning: "off",
  })
})
