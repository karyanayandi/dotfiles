import { stripVTControlCharacters } from "node:util"
import { describe, expect, test, vi } from "vitest"
import type { AssistantMessage } from "@earendil-works/pi-ai"
import {
  AssistantMessageComponent,
  initTheme,
  getMarkdownTheme,
  ToolExecutionComponent,
  Theme,
  type ExtensionAPI,
  type AgentToolResult,
  type ToolDefinition,
  UserMessageComponent,
} from "@earendil-works/pi-coding-agent"
import {
  Markdown,
  ProcessTerminal,
  visibleWidth,
  Text,
} from "@earendil-works/pi-tui"
import { TuiMainScreen } from "@earendil-works/pi-tui/dist/tui-main-screen.js"
import { Type } from "typebox"

import {
  installCompactMessages,
  installToolSpacing,
  registerCompactTools,
} from "./compact.js"

initTheme("dark")

const theme = new Theme(
  {
    accent: "",
    border: "",
    borderAccent: "",
    borderMuted: "",
    success: "",
    error: "",
    warning: "",
    muted: "",
    dim: "",
    text: "",
    thinkingText: "",
    userMessageText: "",
    customMessageText: "",
    customMessageLabel: "",
    toolTitle: "",
    toolOutput: "",
    mdHeading: "",
    mdLink: "",
    mdLinkUrl: "",
    mdCode: "",
    mdCodeBlock: "",
    mdCodeBlockBorder: "",
    mdQuote: "",
    mdQuoteBorder: "",
    mdHr: "",
    mdListBullet: "",
    toolDiffAdded: "",
    toolDiffRemoved: "",
    toolDiffContext: "",
    syntaxComment: "",
    syntaxKeyword: "",
    syntaxFunction: "",
    syntaxVariable: "",
    syntaxString: "",
    syntaxNumber: "",
    syntaxType: "",
    syntaxOperator: "",
    syntaxPunctuation: "",
    thinkingOff: "",
    thinkingMinimal: "",
    thinkingLow: "",
    thinkingMedium: "",
    thinkingHigh: "",
    thinkingXhigh: "",
    bashMode: "",
  },
  {
    selectedBg: "",
    userMessageBg: "",
    customMessageBg: "",
    toolPendingBg: "",
    toolSuccessBg: "",
    toolErrorBg: "",
  },
  "truecolor",
)

vi.spyOn(theme, "bg").mockImplementation((_color, text) => text)

vi.spyOn(theme, "fg").mockImplementation((_color, text) => text)

vi.spyOn(theme, "bold").mockImplementation((text) => text)

vi.spyOn(theme, "italic").mockImplementation((text) => text)

const tui = new TuiMainScreen(new ProcessTerminal())

vi.spyOn(tui, "requestRender").mockImplementation(() => undefined)

function createTools(getCompact: () => boolean) {
  const tools = new Map<
    string,
    NonNullable<ConstructorParameters<typeof ToolExecutionComponent>[4]>
  >()

  const pi: Pick<ExtensionAPI, "registerTool"> = {
    registerTool: (tool) => {
      tools.set(tool.name, tool)
    },
  }

  registerCompactTools(pi, getCompact)

  return tools
}

function renderContext<TArgs>(args: TArgs, state = {}) {
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

const assistantMessage: AssistantMessage = {
  role: "assistant",
  content: [{ type: "text", text: "hello" }],
  api: "openai-responses",
  provider: "test",
  model: "test",
  usage: {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    totalTokens: 0,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
  },
  stopReason: "stop",
  timestamp: 0,
}

const calls = {
  bash: { command: "npm test" },
  find: { path: "src", pattern: "*.ts" },
  grep: { path: "src", pattern: "registerTool" },
  ls: { path: "src" },
  read: { path: "src/index.ts" },
}

describe("registerCompactTools", () => {
  test("renders partial built-in args and sanitizes control bytes", () => {
    const tools = createTools(() => true)

    for (const tool of tools.values()) {
      const args = {}
      expect(() =>
        tool.renderCall?.(args, theme, renderContext(args)),
      ).not.toThrow()
    }

    const args = {
      path: "src/\u001b[31mfile\u0000\u202e.ts",
      offset: 2,
      limit: 3,
    }

    const call = tools
      .get("read")
      ?.renderCall?.(args, theme, renderContext(args))

    expect(call?.render(80).join("\n")).toContain(
      "src/�[31mfile��.ts lines 2–4",
    )
  })

  test("registers every built-in and selects the shell by layout", () => {
    const compact = createTools(() => true)
    expect([...compact.keys()].sort()).toEqual([
      "bash",
      "find",
      "grep",
      "ls",
      "read",
    ])

    // Compact layouts use self shell. Other layouts use default shell.
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

    const result: AgentToolResult<undefined> = {
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
    expect(call?.render(80)).toBe(lines)
    expect(lines[0]).toContain("read src/index.ts")
    expect(lines[0]).toContain("3 lines")
    // Collapsed result adds no row.
    expect(collapsed?.render(80) ?? []).toEqual([])
    expect(visibleWidth(lines[0] ?? "")).toBeLessThanOrEqual(80)
  })

  test("delegates to the original renderer when the layout is not compact", () => {
    const tools = createTools(() => false)
    const tool = tools.get("read")
    const args = calls.read
    const call = tool?.renderCall?.(args, theme, renderContext(args))
    // Non-compact renderCall uses pi's built-in read renderer.
    const lines = call?.render(80) ?? []
    expect(lines.length).toBeGreaterThan(0)
    expect(lines.join("\n")).toContain("read")
  })
})

describe("installCompactMessages", () => {
  test("hides only the compact thinking-level label", () => {
    const restore = installCompactMessages(theme, () => true)

    try {
      const label = new Text("\u001b[2mThinking level: medium\u001b[0m", 0, 0)
      const body = new Text(`${"x".repeat(256)} Thinking level: medium`, 0, 0)
      expect(label.render(80)).toEqual([])
      expect(body.render(80).length).toBeGreaterThan(0)
    } finally {
      restore()
    }
  })

  test("reuses compact user message rendering until invalidated", () => {
    const restore = installCompactMessages(theme, () => true)
    const message = new UserMessageComponent("hello")

    try {
      const first = message.render(80)
      expect(message.render(80)).toBe(first)

      message.invalidate()
      expect(message.render(80)).not.toBe(first)
    } finally {
      restore()
    }
  })

  test("renders assistant code panels without fences and restores native Markdown", () => {
    let compact = true
    const restore = installCompactMessages(theme, () => compact)

    const source =
      'Before\n\n```json\n{"message":"hello"}\n```\n\nAfter\n\n````js\nconst fence = "```"\n````'

    const markdown = new Markdown(source, 0, 0, getMarkdownTheme())

    const message = new AssistantMessageComponent({
      ...assistantMessage,
      content: [{ type: "text", text: source }],
    })

    try {
      for (const width of [1, 4, 40, 120]) {
        const lines = message.render(width)
        expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)

        if (width < 40) continue
        const output = lines.map(stripVTControlCharacters).join("\n")
        expect(output).toContain("</> json")
        expect(output).toContain("</> js")
        expect(output).toContain('const fence = "```"')
        expect(output).toContain("Before")
        expect(output).toContain("After")
        expect(output).not.toMatch(/^\s*```(?:json|js)?\s*$/m)
        expect(output).toContain("│")
      }

      expect(
        markdown.render(80).map(stripVTControlCharacters).join("\n"),
      ).toContain("</> json")
      compact = false
      expect(
        markdown.render(80).map(stripVTControlCharacters).join("\n"),
      ).toContain("```json")
      compact = true
      markdown.render(80)
    } finally {
      restore()
    }

    expect(
      markdown.render(80).map(stripVTControlCharacters).join("\n"),
    ).toContain("```json")
  })

  test("reuses finalized assistant rendering until invalidated", () => {
    const restore = installCompactMessages(theme, () => true)
    const message = new AssistantMessageComponent(assistantMessage)

    try {
      const first = message.render(80)
      expect(message.render(80)).toBe(first)

      message.invalidate()
      expect(message.render(80)).not.toBe(first)
    } finally {
      restore()
    }
  })
})

describe("installToolSpacing", () => {
  test("keeps long read paths and summaries visible collapsed and expanded", () => {
    const args = {
      path: "/home/example/" + "nested/".repeat(12) + "file.ts",
      offset: 2,
      limit: 3,
    }

    const row = new ToolExecutionComponent(
      "read",
      "long-read",
      args,
      {},
      createTools(() => true).get("read"),
      tui,
      "/tmp/example",
    )

    const restore = installToolSpacing(() => true, theme)

    try {
      row.setArgsComplete()
      row.updateResult({
        content: [{ type: "text", text: "one\ntwo\nthree" }],
        isError: false,
      })

      for (const expanded of [false, true]) {
        row.setExpanded(expanded)

        for (const width of [8, 24, 80, 120]) {
          const lines = row.render(width)
          expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)
          expect(lines.join("")).not.toContain("…")

          const text = lines
            .map((line) => stripVTControlCharacters(line).trim())
            .join("")
            .replace(/\s/g, "")

          expect(text).toContain(args.path)
          expect(text).toContain("3lines")

          if (expanded) expect(text).toContain("onetwothree")
          else expect(text).not.toContain("onetwothree")
        }
      }
    } finally {
      restore()
    }
  })

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
      // Self-rendered compact tool still yields one content line.
      const lines = row.render(80)
      expect(lines.length).toBeGreaterThanOrEqual(1)
      expect(lines[0] ?? "").not.toContain("✓")
    } finally {
      restore()
    }
  })

  test("wraps long rows on a narrow terminal", () => {
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
      expect(row.render(0)).toEqual([])

      for (const width of [1, 3, 4]) {
        const lines = row.render(width)
        expect(lines, `width ${width}`).toHaveLength(1)
        expect(visibleWidth(lines[0] ?? "")).toBeLessThanOrEqual(width)
      }

      for (const width of [8, 12, 24]) {
        const lines = row.render(width)
        expect(lines.length).toBeGreaterThan(1)
        expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)
        expect(lines.join("")).not.toContain("…")
        expect(
          lines.map((line) => stripVTControlCharacters(line).trim()).join(""),
        ).toContain("registerTool")
      }

      expect(row.render(80)[0]).toContain("registerTool")
      expect(row.render(80)[0]).not.toContain("…")
    } finally {
      restore()
    }
  })

  test("wraps custom tool headers with ANSI and wide characters", () => {
    const row = new ToolExecutionComponent(
      "custom_tool",
      "tool-custom",
      { path: "界😀".repeat(40) },
      {},
      undefined,
      tui,
      "/tmp/example",
    )

    row.setArgsComplete()
    const native = row.render(24)
    let compact = true
    const restore = installToolSpacing(() => compact, theme)

    try {
      for (const width of [8, 24, 80]) {
        const lines = row.render(width)
        expect(lines.length).toBeGreaterThan(1)
        expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)
        expect(lines.join("")).not.toContain("…")
        expect(
          lines.map((line) => stripVTControlCharacters(line).trim()).join(""),
        ).toContain("界😀".repeat(40))
      }

      row.setExpanded(true)
      expect(row.render(24)).toEqual(native)
      row.setExpanded(false)
      compact = false
      expect(row.render(24)).toEqual(native)
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
    // Force compact path to throw, as hostile args getter would.
    Object.defineProperty(row, "args", {
      get() {
        throw new Error("boom")
      },
    })

    const restore = installToolSpacing(() => true, theme)

    try {
      expect(() => row.render(80)).not.toThrow()
      // Uses original renderer output instead of crashing.
      expect(row.render(80).length).toBeGreaterThanOrEqual(1)
    } finally {
      restore()
    }
  })

  test("renders workflow script as code in compact layouts and restores native rows", () => {
    const script = 'const value = "' + "x".repeat(100) + '"\nreturn value'

    const row = new ToolExecutionComponent(
      "workflow",
      "tool-workflow",
      { script, background: true },
      {},
      undefined,
      tui,
      "/tmp/example",
    )

    row.setArgsComplete()
    const original = row.render(120)
    let compact = true
    const restore = installToolSpacing(() => compact, theme)

    try {
      for (const width of [40, 120]) {
        const lines = row.render(width)
        const text = stripVTControlCharacters(lines.join("\n"))
        expect(text).toContain("workflow </> javascript")
        expect(text).not.toContain("script:")

        if (width === 40) {
          expect(lines.length).toBeGreaterThan(3)
          expect(lines.join("")).not.toContain("…")
        } else {
          expect(text).toContain("background:true")
          expect(
            lines
              .slice(1)
              .map((line) => line.trimStart())
              .join("\n"),
          ).toBe(script)
        }

        expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)
      }

      compact = false
      expect(row.render(120)).toEqual(original)
    } finally {
      restore()
    }
  })

  test.each([
    ["codemode", "default"],
    ["codemode", "self"],
    ["workflow", "self"],
  ] as const)("styles %s code with %s shell like ctx", (name, renderShell) => {
    const code = 'const value = "' + "x".repeat(100) + '"\nreturn value'
    const args = name === "workflow" ? { script: code } : { code }

    const tool = {
      name,
      label: name,
      description: "run script",
      parameters: Type.Object({}),
      renderShell,
      renderCall: () => new Text("```js workflow\n" + code, 0, 0),
      execute() {
        return Promise.resolve({ content: [], details: undefined })
      },
    } satisfies ToolDefinition

    const row = new ToolExecutionComponent(
      name,
      "tool-script",
      args,
      {},
      tool,
      tui,
      "/tmp/example",
    )

    row.setArgsComplete()
    const native = row.render(120)
    let compact = true
    const restore = installToolSpacing(() => compact, theme)

    try {
      for (const width of [4, 40, 120]) {
        const lines = row.render(width)
        expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)

        if (width <= 4) continue
        expect(stripVTControlCharacters(lines[0] ?? "")).toContain(
          `${name} </> javascript`,
        )
        expect(lines.join("\n")).not.toContain("```")

        if (width === 40) {
          expect(lines.length).toBeGreaterThan(3)
          expect(lines.join("")).not.toContain("…")
        } else
          expect(
            lines
              .slice(1)
              .map((line) => line.trimStart())
              .join("\n"),
          ).toBe(code)
      }

      row.setExpanded(true)
      expect(row.render(120)).toEqual(native)
      row.setExpanded(false)
      compact = false
      expect(row.render(120)).toEqual(native)
    } finally {
      restore()
    }
  })

  test("shows workflow JSON result panel collapsed and expanded", () => {
    const tool = {
      name: "workflow",
      label: "workflow",
      description: "script",
      parameters: Type.Object({}),
      renderCall: () => new Text("workflow", 0, 0),
      renderResult: () =>
        new Markdown(
          '```json\n{"values":[2,4,6]}\n```',
          0,
          0,
          getMarkdownTheme(),
        ),
      execute() {
        return Promise.resolve({ content: [], details: undefined })
      },
    } satisfies ToolDefinition

    const row = new ToolExecutionComponent(
      "workflow",
      "result-test",
      { script: "return { values: [2, 4, 6] }" },
      {},
      tool,
      tui,
      "/tmp/example",
    )

    const restoreMessages = installCompactMessages(theme, () => true)
    const restoreTools = installToolSpacing(() => true, theme)

    try {
      row.setArgsComplete()
      row.updateResult({
        content: [],
        details: { result: { values: [2, 4, 6] } },
        isError: false,
      })

      for (const expanded of [false, true]) {
        row.setExpanded(expanded)

        for (const width of [1, 4, 40, 120]) {
          const lines = row.render(width)
          expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true)

          if (width < 40) continue
          const output = lines.map(stripVTControlCharacters).join("\n")
          expect(output).toContain("</> json")
          expect(output).toContain('"values"')
          expect(output).not.toContain("```")
        }
      }
    } finally {
      restoreTools()
      restoreMessages()
    }
  })

  test("preserves native image rows and escape sequences in compact layout", () => {
    const imageLines = [
      "",
      "  read screenshot.png",
      "\u001b_Gimage-data\u001b\\",
      "",
      "",
    ]

    const originalRender = vi
      .spyOn(ToolExecutionComponent.prototype, "render")
      .mockReturnValue(imageLines)

    const row = new ToolExecutionComponent(
      "read",
      "tool-image",
      { path: "screenshot.png" },
      {},
      undefined,
      tui,
      "/tmp/example",
    )

    const restore = installToolSpacing(() => true, theme)

    try {
      row.updateResult({
        content: [
          { type: "image", data: "iVBORw0KGgo=", mimeType: "image/png" },
        ],
        isError: false,
      })
      expect(row.render(120)).toEqual(imageLines)
    } finally {
      restore()
      originalRender.mockRestore()
    }
  })

  test("shows executed code beneath code-tool header in compact layout", () => {
    const tool = {
      name: "ctx_execute",
      label: "ctx_execute",
      description: "run code",
      parameters: Type.Object({}),
      renderShell: "default",
      renderCall: () => new Text("ctx_execute · ```python", 0, 0),
      execute() {
        return Promise.resolve({ content: [], details: undefined })
      },
    } satisfies ToolDefinition

    const row = new ToolExecutionComponent(
      "ctx_execute",
      "tool-1",
      {
        language: "python",
        code: "value = 42\nprint(value)",
        cwd: "/tmp/project",
      },
      {},
      tool,
      tui,
      "/tmp/example",
    )

    row.setArgsComplete()

    const restore = installToolSpacing(() => true, theme)

    try {
      const text = stripVTControlCharacters(row.render(120).join("\n"))

      expect(text).toContain("</> python")
      expect(text).toContain("  value = 42\n  print(value)")
      expect(text).not.toContain("```")
    } finally {
      restore()
    }
  })

  test("wraps long executed code without losing source", () => {
    const code = `print('${"x".repeat(100)}')`

    const tool = {
      name: "ctx_execute",
      label: "ctx_execute",
      description: "run code",
      parameters: Type.Object({}),
      renderShell: "default",
      renderCall: () => new Text("ctx_execute", 0, 0),
      execute() {
        return Promise.resolve({ content: [], details: undefined })
      },
    } satisfies ToolDefinition

    const row = new ToolExecutionComponent(
      "ctx_execute",
      "tool-1",
      { language: "python", code },
      {},
      tool,
      tui,
      "/tmp/example",
    )

    row.setArgsComplete()
    const restore = installToolSpacing(() => true, theme)

    try {
      const lines = row.render(40)
      expect(lines.length).toBeGreaterThan(2)
      expect(lines[1]).toContain("print('")
      expect(lines.join("")).not.toContain("…")
      expect(
        lines
          .slice(1)
          .map((line) => line.slice(2))
          .join(""),
      ).toBe(code)
      expect(lines.every((line) => visibleWidth(line) <= 40)).toBe(true)
    } finally {
      restore()
    }
  })

  test("truncates rows to width so a padded line can never overflow the terminal", () => {
    // Self-shell tool returns wide Text. Original renderer's Box pads it to full
    // width and compact !isBgShell branch prepends "  · ". Without truncation,
    // row overflows terminal and force-closes pi.
    const wideTool = {
      name: "playwriter_execute",
      label: "playwriter_execute",
      description: "run playwright",
      parameters: Type.Object({}),
      renderShell: "self",
      renderCall: () => new Text("playwriter_execute", 0, 0),
      execute() {
        return Promise.resolve({
          content: [{ type: "text", text: "x" }],
          details: undefined,
        })
      },
    } satisfies ToolDefinition

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
