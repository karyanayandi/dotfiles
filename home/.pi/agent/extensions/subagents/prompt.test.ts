import assert from "node:assert/strict"
import test from "node:test"
import {
  buildSubagentSpawnResult,
  SUBAGENT_SPAWN_TOOL_DESCRIPTION,
  SUBAGENT_SPAWN_PROMPT_SNIPPET,
  SUBAGENT_SPAWN_PROMPT_GUIDELINES,
  SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS,
  SUBAGENT_LIST_TOOL_DESCRIPTION,
} from "./src/prompt.ts"

void test("tool instructions describe Pi sessions without harness choice", () => {
  const instructions = [
    SUBAGENT_SPAWN_TOOL_DESCRIPTION,
    SUBAGENT_SPAWN_PROMPT_SNIPPET,
    ...SUBAGENT_SPAWN_PROMPT_GUIDELINES,
    ...Object.values(SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS),
    SUBAGENT_LIST_TOOL_DESCRIPTION,
  ].join("\n")

  assert.doesNotMatch(instructions, /codex|harness/i)
  assert.match(SUBAGENT_SPAWN_TOOL_DESCRIPTION, /in.process/i)
  assert.equal("harness" in SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS, false)
})

void test("spawn result retains task details and collection instructions", () => {
  const result = buildSubagentSpawnResult({
    id: "sa-1",
    title: "demo",
    modelLabel: "provider/model",
    cwd: "/tmp/project",
  })

  assert.match(result, /sa-1 "demo"/)
  assert.match(result, /provider\/model/)
  assert.match(result, /\/tmp\/project/)
  assert.match(result, /subagent_wait/)
  assert.doesNotMatch(result, /codex|harness/i)
})
