import assert from "node:assert/strict"
import test from "node:test"
import { DEFAULT_SUMMARY_CONFIG, parseSummaryConfig } from "./src/config.ts"

test("summary config defaults to Codex Luna at medium reasoning", () => {
  assert.deepEqual(parseSummaryConfig(undefined), DEFAULT_SUMMARY_CONFIG)
  assert.deepEqual(DEFAULT_SUMMARY_CONFIG, {
    provider: "opencode",
    model: "deepseek-v4-flash-free",
    reasoning: "high",
  })
})
