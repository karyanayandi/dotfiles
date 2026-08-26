import { describe, expect, test } from "vitest"
import { visibleWidth } from "@earendil-works/pi-tui"

import { renderExtensionStatuses } from "./layout.js"

describe("renderExtensionStatuses", () => {
  test("sorts statuses and keeps each indicator on one line", () => {
    const lines = renderExtensionStatuses(
      new Map([
        ["subagents", "subagents: ■ 1 running\n · /subagents to view"],
        ["workflows", "■ 1 running"],
      ]),
      80,
    )

    expect(lines).toEqual([
      "subagents: ■ 1 running · /subagents to view ■ 1 running",
    ])
  })

  test("omits empty statuses and respects terminal width", () => {
    const lines = renderExtensionStatuses(
      new Map([
        ["empty", " \n\t"],
        ["subagents", "subagents: ■ 1 running"],
      ]),
      12,
    )

    expect(lines).toHaveLength(1)
    expect(visibleWidth(lines[0] ?? "")).toBeLessThanOrEqual(12)
    expect(renderExtensionStatuses(new Map(), 80)).toEqual([])
  })
})
