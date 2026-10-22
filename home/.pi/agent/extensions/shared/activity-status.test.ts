import assert from "node:assert/strict"
import { test } from "node:test"
import { stripVTControlCharacters } from "node:util"
import { visibleWidth } from "@earendil-works/pi-tui"
import { theme } from "../subagents/test-theme.ts"
import {
  ACTIVITY_FRAME_MS,
  activityIndicator,
  inputActivityIndicator,
  formatActivityStatus,
} from "./activity-status.ts"

test("task activity uses a single-column arc spinner at 120 ms", () => {
  const frames = ["◜", "◝", "◞", "◟"]
  assert.equal(ACTIVITY_FRAME_MS, 120)
  for (let index = 0; index < frames.length * 2; index++) {
    const now = index * ACTIVITY_FRAME_MS
    const indicator = activityIndicator(theme, "running", now)
    assert.equal(
      stripVTControlCharacters(indicator),
      frames[index % frames.length],
    )
    assert.equal(visibleWidth(indicator), 1)
    assert.equal(
      activityIndicator(theme, "running", now + ACTIVITY_FRAME_MS - 1),
      indicator,
    )
  }
})

test("input alone uses the main Pi spinner and idle pipe", () => {
  const frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  for (let index = 0; index < frames.length * 2; index++) {
    const now = index * ACTIVITY_FRAME_MS
    const indicator = inputActivityIndicator(theme, true, now)
    assert.equal(
      stripVTControlCharacters(indicator),
      frames[index % frames.length],
    )
    assert.equal(visibleWidth(indicator), 1)
    assert.equal(
      inputActivityIndicator(theme, true, now + ACTIVITY_FRAME_MS - 1),
      indicator,
    )
    assert.notEqual(indicator, activityIndicator(theme, "running", now))
    assert.equal(
      inputActivityIndicator(theme, false, now),
      theme.fg("text", "┃"),
    )
  }
})

test("settled and queued indicators do not animate", () => {
  for (const [state, glyph] of [
    ["done", "✓"],
    ["error", "✕"],
    ["stopped", "▪"],
    ["queued", "○"],
  ] as const) {
    assert.equal(
      stripVTControlCharacters(activityIndicator(theme, state, 0)),
      glyph,
    )
    assert.equal(visibleWidth(activityIndicator(theme, state, 0)), 1)
    assert.equal(
      activityIndicator(theme, state, 0),
      activityIndicator(theme, state, 120),
    )
  }
})

test("activity summary keeps counts and links without square status marks", () => {
  const text = stripVTControlCharacters(
    formatActivityStatus(theme, "workflows", {
      running: 2,
      done: 1,
      failed: 3,
    }),
  )
  assert.match(text, /[◜◝◞◟] 2 running/)
  assert.match(text, /✓ 1 done/)
  assert.match(text, /✕ 3 failed/)
  assert.match(text, /\/workflows.*to view/)
  assert.doesNotMatch(text, /■/)
})

test("terminal summary uses its own label, counts, and ps hint", () => {
  const text = stripVTControlCharacters(
    formatActivityStatus(theme, "background terminal", {
      running: 0,
      done: 2,
      failed: 1,
    }),
  )
  assert.equal(text, "background terminal: ✓ 2 done · ✕ 1 failed · /ps to view")
})
