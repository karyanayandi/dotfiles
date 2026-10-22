import assert from "node:assert/strict"
import { test } from "node:test"
import { stripVTControlCharacters } from "node:util"
import { visibleWidth } from "@earendil-works/pi-tui"
import {
  ACTIVITY_FRAME_MS,
  activityIndicator,
} from "@pi/shared/activity-status"
import { theme } from "@pi/shared/test-theme"
import {
  stateGlyph,
  statusGlyph,
  type AgentState,
  type WorkflowStatus,
} from "./model.ts"

await test("workflow indicators use shared states and animate running frames", () => {
  const originalNow = Date.now
  let now = 0
  Date.now = () => now

  try {
    const agents: Record<AgentState, string> = {
      running: "◜",
      done: "✓",
      error: "✕",
    }

    const runs: Record<WorkflowStatus, string> = {
      running: "◜",
      completed: "✓",
      failed: "✕",
      aborted: "▪",
    }

    for (const state of ["running", "done", "error"] as const) {
      const rendered = stateGlyph(state, theme)
      assert.equal(rendered, activityIndicator(theme, state))
      assert.equal(stripVTControlCharacters(rendered), agents[state])
      assert.equal(visibleWidth(rendered), 1)
    }

    for (const status of [
      "running",
      "completed",
      "failed",
      "aborted",
    ] as const) {
      const rendered = statusGlyph(status, theme)

      const sharedState =
        status === "completed"
          ? "done"
          : status === "failed"
            ? "error"
            : status === "aborted"
              ? "stopped"
              : "running"

      assert.equal(rendered, activityIndicator(theme, sharedState))
      assert.equal(stripVTControlCharacters(rendered), runs[status])
      assert.equal(visibleWidth(rendered), 1)
    }

    now = ACTIVITY_FRAME_MS
    assert.equal(stripVTControlCharacters(stateGlyph("running", theme)), "◝")
    assert.equal(stripVTControlCharacters(statusGlyph("running", theme)), "◝")
  } finally {
    Date.now = originalNow
  }
})
