import { describe, expect, test } from "vitest"
import { visibleWidth } from "@earendil-works/pi-tui"
import { stripVTControlCharacters } from "node:util"

import { renderExtensionStatuses } from "./layout.js"

describe("renderExtensionStatuses", () => {
  test("sorts statuses and keeps each indicator on one line", () => {
    const lines = renderExtensionStatuses(
      new Map([
        ["tasks", "tasks: ■ 1 running\n · /tasks to view"],
        ["workflows", "■ 1 running"],
      ]),
      80,
    )

    expect(lines).toEqual(["tasks: ■ 1 running · /tasks ↗    ■ 1 running"])
  })

  test("omits empty statuses and respects terminal width", () => {
    const lines = renderExtensionStatuses(
      new Map([
        ["empty", " \n\t"],
        ["workflows", "workflows: ■ 1 running"],
      ]),
      12,
    )

    expect(lines).toHaveLength(1)
    expect(visibleWidth(lines[0] ?? "")).toBeLessThanOrEqual(12)
    expect(renderExtensionStatuses(new Map(), 80)).toEqual([])
  })

  test("compacts activity labels and wraps without losing statuses on tiny screens", () => {
    const statuses = new Map([
      [
        "background-terminals",
        "◜ 2 background terminals running • /ps to view",
      ],
      [
        "subagents",
        "\u001b[36msubagents:\u001b[39m ◝ 3 running · ✓ 4 done · ✕ 5 failed · /subagents to view",
      ],
      ["workflows", "workflows: ◞ 6 running · /workflows to view"],
    ])
    expect(renderExtensionStatuses(statuses, 250)).toHaveLength(1)
    expect(renderExtensionStatuses(statuses, 250).join("")).toContain(
      "background terminals running",
    )
    const full = stripVTControlCharacters(
      renderExtensionStatuses(statuses, 250).join(""),
    )
    expect(full).not.toContain("to view")
    expect(full).toContain("/ps ↗    subagents:")
    expect(full).toContain("/subagents ↗    workflows:")
    expect(full).toContain("/workflows ↗")
    const compact = renderExtensionStatuses(statuses, 100)
    expect(compact).toHaveLength(1)
    expect(compact.join("")).not.toMatch(
      /running|done|failed|to view|background terminals|subagents:/,
    )
    const compactText = stripVTControlCharacters(compact.join(""))
    expect(compactText).toContain(">_  ◜ 2")
    expect(compactText).toContain("/ps ↗    ⌘  ◝ 3")
    expect(compactText).toContain("/subagents ↗    ⑂  ◞ 6")
    expect(compactText).toContain("/workflows ↗")
    expect(compactText).not.toMatch(/\/\w+ {2,}↗/)
    for (const width of [1, 2, 4, 8, 12, 20, 40, 60, 80, 100, 160]) {
      const lines = renderExtensionStatuses(statuses, width)
      expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)
      const text = stripVTControlCharacters(lines.join("")).replace(/\s/g, "")
      for (const value of [
        "◜2",
        "◝3",
        "✓4",
        "✕5",
        "◞6",
        "/ps",
        "/subagents",
        "/workflows",
      ])
        expect(text).toContain(value)
      expect(text).not.toContain("…")
    }
    expect(renderExtensionStatuses(statuses, 0)).toEqual([])
  })

  test("uses two spaces after every section icon on wrapped rows", () => {
    const lines = renderExtensionStatuses(
      new Map([
        [
          "background-terminals",
          "◜ 1 background terminal running · /ps to view",
        ],
        ["subagents", "subagents: ◜ 1 running · /subagents to view"],
        ["workflows", "workflows: ◜ 1 running · /workflows to view"],
      ]),
      30,
    ).map(stripVTControlCharacters)
    expect(lines).toEqual([
      ">_  ◜ 1 · /ps ↗",
      "⌘  ◜ 1 · /subagents ↗",
      "⑂  ◜ 1 · /workflows ↗",
    ])
    for (const line of lines) expect(line).toMatch(/^(?:>_|⌘|⑂) {2}◜/)
  })

  test("dims separators and view arrows without changing other colors or width", () => {
    const statuses = new Map([
      [
        "subagents",
        "subagents: ◝ 3 running · \u001b[36m/subagents\u001b[39m to view",
      ],
      ["workflows", "workflows: ◞ 6 running · /workflows to view"],
    ])
    for (const width of [30, 80, 250]) {
      const plain = renderExtensionStatuses(statuses, width)
      const styled = renderExtensionStatuses(
        statuses,
        width,
        (text) => `\u001b[2m${text}\u001b[22m`,
      )
      expect(styled.map(stripVTControlCharacters)).toEqual(
        plain.map(stripVTControlCharacters),
      )
      expect(styled.every((line) => visibleWidth(line) <= width)).toBe(true)
      expect(styled.join("")).toContain("\u001b[2m·\u001b[22m")
      expect(styled.join("")).toContain("\u001b[2m↗\u001b[22m")
      expect(styled.join("")).toContain("\u001b[36m/subagents\u001b[39m")
    }
  })

  test("keeps unknown extension statuses when wrapping", () => {
    const lines = renderExtensionStatuses(
      new Map([["other", "custom 界 status"]]),
      8,
    )
    expect(lines.every((line) => visibleWidth(line) <= 8)).toBe(true)
    expect(lines.join("").replace(/\s/g, "")).toBe("custom界status")
  })
})
