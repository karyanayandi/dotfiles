import assert from "node:assert/strict"
import { test } from "node:test"
import { stripVTControlCharacters } from "node:util"
import { visibleWidth } from "@earendil-works/pi-tui"
import { theme } from "../subagents/test-theme.ts"
import {
  stateGlyph,
  statusGlyph,
  type AgentState,
  type WorkflowStatus,
} from "./model.ts"

test("workflow status glyphs match compact task indicators", () => {
  const agents: Record<AgentState, string> = {
    running: "·",
    done: "✓",
    error: "✕",
  }
  const runs: Record<WorkflowStatus, string> = {
    running: "·",
    completed: "✓",
    failed: "✕",
    aborted: "✕",
  }

  for (const state of ["running", "done", "error"] as const) {
    const rendered = stateGlyph(state, theme)
    assert.equal(stripVTControlCharacters(rendered), agents[state])
    assert.equal(visibleWidth(rendered), 1)
  }

  for (const status of ["running", "completed", "failed", "aborted"] as const) {
    const rendered = statusGlyph(status, theme)
    assert.equal(stripVTControlCharacters(rendered), runs[status])
    assert.equal(visibleWidth(rendered), 1)
  }
})
