import { describe, expect, test, vi } from "vitest"
import {
  initTheme,
  ToolExecutionComponent,
  type Theme,
} from "@earendil-works/pi-coding-agent"
import { type TUI, visibleWidth, Text } from "@earendil-works/pi-tui"

import { installToolSpacing, registerCompactTools } from "./compact.js"

initTheme("dark")

const theme = {
  bold: (text: string) => text,
  fg: (_color: string, text: string) => text,
} as unknown as Theme

const tui = { requestRender: vi.fn() } as unknown as TUI

function createTools(getCompact: () => boolean) {
  const tools = new Map<string, any>()
  const pi = { registerTool: (tool: any) => tools.set(tool.name, tool) } as any
  registerCompactTools(pi, getCompact)
  return tools
}

function renderContext(args: unknown, state: Record<string, unknown> = {}) {
  return {
    args,
    argsComplete: true,
    cwd: "/tmp/example",
    executionStarted: true,
    expanded: false,
    invalidate: vi.fn(),
    isError: false,
    isPartial: true,
    lastComponent: undefined,
    showImages: true,
    state,
    toolCallId: "tool-1",
  }
}

const calls: Record<string, unknown> = {
  bash: { command: "npm test" },
  find: { path: "src", pattern: "*.ts" },
  grep: { path: "src", pattern: "registerTool" },
  ls: { path: "src" },
  read: { path: "src/index.ts" },
}

describe("registerCompactTools", () => {
  test("registers every built-in and selects the shell by layout", () => {
    const compact = createTools(() => true)
    expect([...compact.keys()].sort()).toEqual([
      "bash",
      "find",
      "grep",
      "ls",
      "read",
    ])
    // self shell (clean line) in compact layouts, default shell (bg box) otherwise
    for (const tool of compact.values()) expect(tool.renderShell).toBe("self")
    for (const tool of createTools(() => false).values()) {
      expect(tool.renderShell).toBe("default")
    }
  })

  test("collapsed call renders as one bounded line with subject and summary", () => {
    const tools = createTools(() => true)
    const tool = tools.get("read")
    const args = calls.read
    const state = {}
    const call = tool?.renderCall?.(args, theme, renderContext(args, state))
    const result = {
      content: [{ type: "text", text: "line one\nline two\nline three" }],
      details: undefined,
    }
    const collapsed = tool?.renderResult?.(
      result,
      { expanded: false, isPartial: false },
      theme,
      renderContext(args, state),
    )

    const lines = call?.render(80) ?? []
    expect(lines).toHaveLength(1)
    expect(lines[0]).toContain("read src/index.ts")
    expect(lines[0]).toContain("3 lines")
    // collapsed (non-expanded) result contributes no extra row
    expect(collapsed?.render(80) ?? []).toEqual([])
    expect(visibleWidth(lines[0] ?? "")).toBeLessThanOrEqual(80)
  })

  test("delegates to the original renderer when the layout is not compact", () => {
    const tools = createTools(() => false)
    const tool = tools.get("read")
    const args = calls.read
    const call = tool?.renderCall?.(args, theme, renderContext(args))
    // non-compact renderCall delegates to pi's built-in read renderer (a Text)
    const lines = call?.render(80) ?? []
    expect(lines.length).toBeGreaterThan(0)
    expect(lines.join("\n")).toContain("read")
  })
})

describe("installToolSpacing", () => {
  test("collapses a compact tool row to one non-empty line with a status prefix", () => {
    const tool = createTools(() => true).get("ls")
    const row = new ToolExecutionComponent(
      "ls",
      "tool-1",
      calls.ls,
      {},
      tool,
      tui,
      "/tmp/example",
    )
    row.setArgsComplete()
    row.markExecutionStarted()
    row.updateResult(
      { content: [{ type: "text", text: "index.ts" }], isError: false },
      false,
    )

    const restore = installToolSpacing(() => true, theme)
    try {
      const lines = row.render(80)
      expect(lines).toHaveLength(1)
      expect(lines[0]).toContain("✓")
      expect(visibleWidth(lines[0] ?? "")).toBeGreaterThan(0)
    } finally {
      restore()
    }
  })

  test("reuses settled compact rows until invalidated", () => {
    const tool = createTools(() => true).get("ls")
    const row = new ToolExecutionComponent(
      "ls",
      "tool-1",
      calls.ls,
      {},
      tool,
      tui,
      "/tmp/example",
    )
    const restore = installToolSpacing(() => true, theme)
    try {
      row.setArgsComplete()
      row.markExecutionStarted()
      row.updateResult(
        { content: [{ type: "text", text: "index.ts" }], isError: false },
        false,
      )

      const first = row.render(80)
      expect(row.render(80)).toBe(first)
      expect(row.render(79)).not.toBe(first)

      const beforeInvalidate = row.render(80)
      row.invalidate()
      expect(row.render(80)).not.toBe(beforeInvalidate)
    } finally {
      restore()
    }
  })

  test("does not stack status prefixes when installed more than once", () => {
    const tool = createTools(() => true).get("ls")
    const row = new ToolExecutionComponent(
      "ls",
      "tool-1",
      calls.ls,
      {},
      tool,
      tui,
      "/tmp/example",
    )
    row.setArgsComplete()
    row.markExecutionStarted()
    row.updateResult(
      { content: [{ type: "text", text: "index.ts" }], isError: false },
      false,
    )

    const restoreFirst = installToolSpacing(() => true, theme)
    const restoreSecond = installToolSpacing(() => true, theme)
    try {
      const line = row.render(80)[0] ?? ""
      expect(line.match(/✓/g)).toHaveLength(1)
    } finally {
      restoreSecond()
      restoreFirst()
    }
  })

  test("leaves rows untouched when the layout is not compact", () => {
    const tool = createTools(() => true).get("ls")
    const row = new ToolExecutionComponent(
      "ls",
      "tool-1",
      calls.ls,
      {},
      tool,
      tui,
      "/tmp/example",
    )
    row.setArgsComplete()
    row.markExecutionStarted()
    row.updateResult(
      { content: [{ type: "text", text: "index.ts" }], isError: false },
      false,
    )

    const restore = installToolSpacing(() => false, theme)
    try {
      // self-rendered compact tool still yields its single content line
      const lines = row.render(80)
      expect(lines.length).toBeGreaterThanOrEqual(1)
      expect(lines[0] ?? "").not.toContain("✓")
    } finally {
      restore()
    }
  })

  test("wraps long rows to the next line instead of truncating on a narrow terminal", () => {
    const tool = createTools(() => true).get("grep")
    const row = new ToolExecutionComponent(
      "grep",
      "tool-1",
      calls.grep,
      {},
      tool,
      tui,
      "/tmp/example",
    )
    row.setArgsComplete()
    row.markExecutionStarted()
    row.updateResult(
      {
        content: [{ type: "text", text: "match\nsecond match" }],
        isError: false,
      },
      false,
    )

    const restore = installToolSpacing(() => true, theme)
    try {
      for (const width of [8, 12, 24, 3]) {
        const lines = row.render(width)
        // may wrap onto several rows, but every row fits the terminal width
        expect(lines.length, `width ${width}`).toBeGreaterThanOrEqual(1)
        for (const line of lines) {
          expect(visibleWidth(line), `width ${width}`).toBeLessThanOrEqual(
            width,
          )
        }
      }
      // long text is preserved (wrapped), not truncated to "…"
      const wide = row.render(24).join("\n")
      expect(wide.replace(/\x1b\[[0-9;]*m/g, "")).toContain("registerTool")
      expect(wide).not.toContain("…")
    } finally {
      restore()
    }
  })

  test("falls back to the original renderer when compact rendering throws", () => {
    const tool = createTools(() => true).get("ls")
    const row = new ToolExecutionComponent(
      "ls",
      "tool-1",
      calls.ls,
      {},
      tool,
      tui,
      "/tmp/example",
    )
    row.setArgsComplete()
    row.markExecutionStarted()
    row.updateResult(
      { content: [{ type: "text", text: "index.ts" }], isError: false },
      false,
    )
    // Force the compact path to throw (e.g. a hostile args getter).
    Object.defineProperty(row, "args", {
      get() {
        throw new Error("boom")
      },
    })

    const restore = installToolSpacing(() => true, theme)
    try {
      expect(() => row.render(80)).not.toThrow()
      // falls back to the original renderer's output rather than crashing
      expect(row.render(80).length).toBeGreaterThanOrEqual(1)
    } finally {
      restore()
    }
  })

  test("shows code tools with code-block marker instead of fence marker", () => {
    const tool: any = {
      name: "ctx_execute",
      label: "ctx_execute",
      description: "run code",
      parameters: {},
      renderShell: "default",
      renderCall: () => new Text("ctx_execute · ```python", 0, 0),
      async execute() {
        return { content: [], details: undefined }
      },
    }
    const row = new ToolExecutionComponent(
      "ctx_execute",
      "tool-1",
      { language: "python", code: "print('hello')", cwd: "/tmp/project" },
      {},
      tool,
      tui,
      "/tmp/example",
    )
    row.setArgsComplete()

    const restore = installToolSpacing(() => true, theme)
    try {
      const text = row
        .render(120)
        .join("\n")
        .replace(/\x1b\[[0-9;]*m/g, "")
      expect(text).toContain("</> python")
      expect(text).not.toContain("```")
      expect(text).not.toContain("print('hello')")
    } finally {
      restore()
    }
  })

  test("truncates rows to width so a padded line can never overflow the terminal", () => {
    // A tool with renderShell "self" whose renderCall returns a wide Text: the
    // original renderer's Box pads it to full width, and the compact !isBgShell
    // branch prepends "  · " — without truncation that overflows the terminal
    // and force-closes pi (the crash the user hit with playwriter).
    const wideTool: any = {
      name: "playwriter_execute",
      label: "playwriter_execute",
      description: "run playwright",
      parameters: {},
      renderShell: "self",
      renderCall: () => new Text("playwriter_execute", 0, 0),
      async execute() {
        return { content: [{ type: "text", text: "x" }], details: undefined }
      },
    }
    const row = new ToolExecutionComponent(
      "playwriter_execute",
      "tool-1",
      { code: "x" },
      {},
      wideTool,
      tui,
      "/tmp/example",
    )
    row.setArgsComplete()
    row.markExecutionStarted()

    const restore = installToolSpacing(() => true, theme)
    try {
      for (const width of [67, 40, 20]) {
        const lines = row.render(width)
        expect(lines.length, `width ${width}`).toBeGreaterThanOrEqual(1)
        for (const line of lines) {
          expect(visibleWidth(line), `width ${width}`).toBeLessThanOrEqual(
            width,
          )
        }
      }
    } finally {
      restore()
    }
  })
})
