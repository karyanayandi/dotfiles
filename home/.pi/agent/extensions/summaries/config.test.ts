import assert from "node:assert/strict"
import test from "node:test"
import { DEFAULT_SUMMARY_CONFIG, parseSummaryConfig } from "./src/config.ts"

test("summary config defaults to Codex gpt-6-luna", () => {
  assert.deepEqual(parseSummaryConfig(undefined), DEFAULT_SUMMARY_CONFIG)
  assert.deepEqual(DEFAULT_SUMMARY_CONFIG, {
    provider: "openai-codex",
    model: "gpt-6-luna",
    reasoning: "off",
  })
})

test("summary config validates persisted input and trims names", () => {
  for (const value of [
    null,
    [],
    {},
    { provider: "", model: "m", reasoning: "off" },
    { provider: "p", model: " ", reasoning: "off" },
    { provider: "p", model: "m", reasoning: "invalid" },
  ]) {
    assert.deepEqual(parseSummaryConfig(value), DEFAULT_SUMMARY_CONFIG)
  }

  assert.deepEqual(
    parseSummaryConfig({ provider: " p ", model: " m ", reasoning: "high" }),
    {
      provider: "p",
      model: "m",
      reasoning: "high",
    },
  )
})
