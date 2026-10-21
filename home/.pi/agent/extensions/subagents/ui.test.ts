import assert from "node:assert/strict"
import test from "node:test"
import { stripVTControlCharacters } from "node:util"
import { ProcessTerminal, visibleWidth } from "@earendil-works/pi-tui"
import type { SubagentSnapshot } from "./src/domain.ts"
import type { SubagentReadModel } from "./src/manager.ts"
import { SubagentDashboard, TakeoverView } from "./src/ui/takeover.ts"
import { buildTranscriptLines } from "./src/ui/transcript.ts"
import { subagentToolRenderers } from "./src/ui/tools.ts"
import { theme } from "./test-theme.ts"

import { KeybindingsManager, TUI_KEYBINDINGS } from "@earendil-works/pi-tui"
import { TuiMainScreen } from "@earendil-works/pi-tui/dist/tui-main-screen.js"

function snapshot(): SubagentSnapshot {
  return {
    id: "sa-1",
    origin: "model",
    backend: "pi",
    title: "Wide 界 agent",
    prompt: "work",
    cwd: "/tmp",
    status: "running",
    createdAt: Date.now(),
    meta: { backend: "pi", modelLabel: "model" },
    usage: {},
    turns: 1,
    transcript: [
      { kind: "user", text: "hello" },
      {
        kind: "assistant",
        parts: [
          {
            type: "toolCall",
            toolId: "t",
            name: "read",
            argsPreview: "file.ts",
          },
        ],
      },
      {
        kind: "toolResult",
        toolId: "t",
        name: "read",
        isError: false,
        outputPreview: "saved output",
      },
    ],
    liveTools: [{ toolId: "live", name: "bash", done: false }],
    queued: [{ kind: "steer", text: "queued message" }],
    finalText: "",
  }
}

function setup(initial = snapshot()) {
  let snap = initial
  const sent: string[] = []
  const aborted: string[] = []

  const view: SubagentReadModel = {
    list: () => [snap],
    get: () => snap,
    size: () => 1,
    subscribe: () => () => undefined,
    subscribeTo: () => () => undefined,
    requestSend: (_id, text) => {
      sent.push(text)
    },
    requestAbort: (id) => {
      aborted.push(id)
    },
    setOnSettled: () => undefined,
  }

  const tui = new TuiMainScreen(new ProcessTerminal())
  tui.requestRender = () => undefined

  return {
    setSnapshot(next: SubagentSnapshot) {
      snap = next
    },
    sent,
    aborted,
    view,
    tui,
    keys: new KeybindingsManager(TUI_KEYBINDINGS),
  }
}

void test("dashboard and detail hide context metrics but keep metadata and usage tracking", () => {
  const snap = {
    ...snapshot(),
    usage: { tokens: 12_000, contextWindow: 100_000 },
  }
  const { tui, keys, view } = setup(snap)
  const dashboard = new SubagentDashboard(
    tui,
    theme,
    keys,
    view,
    { index: 0 },
    () => undefined,
  )
  const takeover = new TakeoverView(
    tui,
    theme,
    keys,
    snap.id,
    view,
    () => undefined,
  )
  try {
    for (const component of [dashboard, takeover]) {
      const text = component
        .render(200)
        .map(stripVTControlCharacters)
        .join("\n")
      assert.doesNotMatch(text, /12%|100k|12[,.]?000|context|tokens/i)
      assert.match(text, /pi/)
      assert.match(text, /model/)
      assert.match(text, /running/)
    }
    assert.deepEqual(view.get(snap.id)?.usage, {
      tokens: 12_000,
      contextWindow: 100_000,
    })
  } finally {
    dashboard.dispose()
    takeover.dispose()
  }
})

for (const width of [0, 1, 2, 8, 24, 80, 160]) {
  void test(`dashboard and takeover fit width ${width}`, () => {
    const { tui, keys, view } = setup()

    const dashboard = new SubagentDashboard(
      tui,
      theme,
      keys,
      view,
      { index: 0 },
      () => undefined,
    )

    const takeover = new TakeoverView(
      tui,
      theme,
      keys,
      "sa-1",
      view,
      () => undefined,
    )

    try {
      for (const component of [dashboard, takeover]) {
        const lines = component.render(width)

        for (const line of lines)
          assert.ok(visibleWidth(line) <= width, JSON.stringify(line))

        if (width === 0) assert.deepEqual(lines, [])

        assert.doesNotMatch(
          stripVTControlCharacters(lines.join("\n")),
          /[┌┐└┘│─╭╮╰╯]/,
        )

        if (width >= 24) {
          assert.ok(stripVTControlCharacters(lines[0]).startsWith("  "))
        }
      }

      for (const line of buildTranscriptLines(snapshot(), width, theme))
        assert.ok(visibleWidth(line) <= width)
    } finally {
      dashboard.dispose()
      takeover.dispose()
    }
  })
}

void test("dashboard and takeover keep input actions", () => {
  const { tui, keys, view, sent, aborted } = setup()
  let picked: string | null = null

  const dashboard = new SubagentDashboard(
    tui,
    theme,
    keys,
    view,
    { index: 0 },
    (id) => {
      picked = id
    },
  )

  dashboard.handleInput("x")
  dashboard.handleInput("\r")
  assert.equal(picked, "sa-1")
  assert.deepEqual(aborted, ["sa-1"])

  const takeover = new TakeoverView(
    tui,
    theme,
    keys,
    "sa-1",
    view,
    () => undefined,
  )

  try {
    takeover.focused = true
    takeover.handleInput("hello")
    takeover.render(24)
    takeover.handleInput("\r")
    assert.deepEqual(sent, ["hello"])
    assert.equal(takeover.focused, true)
  } finally {
    dashboard.dispose()
    takeover.dispose()
  }
})

void test("transcript uses compact tool and message gutters", () => {
  const text = buildTranscriptLines(snapshot(), 100, theme)
    .map(stripVTControlCharacters)
    .join("\n")

  assert.match(text, / {2}User: hello/)
  assert.doesNotMatch(text, /›|❯|> /)
  assert.match(text, / {2}✓ read file.ts/)
  assert.match(text, / {2}saved output/)
  assert.match(text, / {2}[◜◝◞◟] bash/)
  assert.match(text, /queued steer/)
})

void test("borderless views keep fixed height across resize, scroll, and updates", () => {
  const snap: SubagentSnapshot = {
    ...snapshot(),
    transcript: Array.from({ length: 100 }, (_, index) => ({
      kind: "user",
      text: `message ${index}`,
    })),
    liveTools: [],
    queued: [],
  }
  const { tui, keys, view, setSnapshot } = setup(snap)
  const dashboard = new SubagentDashboard(
    tui,
    theme,
    keys,
    view,
    { index: 0 },
    () => undefined,
  )
  const takeover = new TakeoverView(
    tui,
    theme,
    keys,
    "sa-1",
    view,
    () => undefined,
  )

  try {
    for (const rows of [4, 8, 24, 40]) {
      Object.defineProperty(tui.terminal, "rows", {
        value: rows,
        configurable: true,
      })
      for (const component of [dashboard, takeover]) {
        const lines = component.render(100)
        assert.equal(lines.length, rows - 1)
        assert.ok(lines.every((line) => visibleWidth(line) <= 100))
      }
      if (rows < 24) continue
      const tail = takeover.render(100).map(stripVTControlCharacters).join("\n")
      assert.match(tail, /message 99/)
      takeover.handleInput("\u001b[A")
      const scrolled = takeover
        .render(100)
        .map(stripVTControlCharacters)
        .join("\n")
      assert.match(scrolled, /lines below/)
      takeover.handleInput("\u001b[B")
      assert.match(
        takeover.render(100).map(stripVTControlCharacters).join("\n"),
        /message 99/,
      )
      setSnapshot({ ...snap, errorText: "backend failed" })
      assert.match(
        takeover.render(100).map(stripVTControlCharacters).join("\n"),
        /error: backend failed/,
      )
      setSnapshot(snap)
    }
  } finally {
    dashboard.dispose()
    takeover.dispose()
  }
})

void test("takeover keeps metadata and an unboxed input", () => {
  const { tui, keys, view } = setup()
  const takeover = new TakeoverView(
    tui,
    theme,
    keys,
    "sa-1",
    view,
    () => undefined,
    { badge: "side task" },
  )
  try {
    const lines = takeover.render(160).map(stripVTControlCharacters)
    assert.match(lines[0], /Subagent.*sa-1.*Wide 界 agent/)
    assert.match(lines[0], /running/)
    assert.match(lines[1], /pi.*model.*side task/)
    assert.doesNotMatch(lines.join("\n"), /Message/)
    assert.match(lines.at(-2) ?? "", /^  [⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏] /)
    assert.doesNotMatch(lines.join("\n"), /›|❯|> /)
    assert.match(lines.at(-1) ?? "", /send.*back.*abort run.*scroll/)
  } finally {
    takeover.dispose()
  }
})

void test("subagent state keeps status icons and marks selection with an arrow", (context) => {
  context.mock.timers.enable({ apis: ["Date", "setInterval"], now: 0 })
  context.mock.method(
    theme,
    "bold",
    (text: string) => `\u001b[1m${text}\u001b[22m`,
  )
  context.mock.method(
    theme,
    "bg",
    (color: Parameters<typeof theme.bg>[0], text: string) => {
      assert.notEqual(color, "selectedBg")
      return text
    },
  )
  const { tui, keys, view, setSnapshot } = setup({
    ...snapshot(),
    createdAt: 0,
  })
  const dashboard = new SubagentDashboard(
    tui,
    theme,
    keys,
    view,
    { index: 0 },
    () => undefined,
  )
  const takeover = new TakeoverView(
    tui,
    theme,
    keys,
    "sa-1",
    view,
    () => undefined,
  )
  const frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  const taskFrames = ["◜", "◝", "◞", "◟"]
  try {
    setSnapshot({
      ...snapshot(),
      status: "done",
      transcript: [],
      liveTools: [],
    })
    assert.match(
      takeover.render(160).map(stripVTControlCharacters).at(-2) ?? "",
      /^  ┃ /,
    )
    setSnapshot({ ...snapshot(), createdAt: 0 })
    for (let index = 0; index < frames.length; index++) {
      const lines = takeover.render(160).map(stripVTControlCharacters)
      assert.match(lines[0], new RegExp(taskFrames[index % taskFrames.length]))
      assert.match(
        dashboard.render(160).map(stripVTControlCharacters).join("\n"),
        new RegExp(taskFrames[index % taskFrames.length]),
      )
      assert.match(lines.at(-2) ?? "", new RegExp(`^  ${frames[index]} `))
      context.mock.timers.tick(120)
    }
    const selectedRow = dashboard
      .render(160)
      .find((line) => line.includes("sa-1"))
    assert.ok(selectedRow)
    assert.match(
      stripVTControlCharacters(selectedRow),
      /^› [◜◝◞◟] Wide 界 agent/,
    )
    assert.doesNotMatch(selectedRow, /\u001b\[1m/)
    assert.ok(dashboard.render(160).some((line) => line.includes("\u001b[1m")))
    for (const [status, glyph] of [
      ["done", "✓"],
      ["error", "✕"],
    ] as const) {
      setSnapshot({ ...snapshot(), status })
      const lines = takeover.render(160).map(stripVTControlCharacters)
      assert.match(lines[0], new RegExp(glyph))
      assert.match(lines.at(-2) ?? "", /^  ┃ /)
      assert.doesNotMatch(lines.at(-2) ?? "", /✓|✕/)
      assert.doesNotMatch(lines.join("\n"), /›|❯|> /)
    }
  } finally {
    dashboard.dispose()
    takeover.dispose()
  }
})

void test("missing subagents render a bounded borderless notice", () => {
  const { tui, keys, view } = setup()
  const missing = { ...view, get: () => undefined }
  const takeover = new TakeoverView(
    tui,
    theme,
    keys,
    "sa-missing",
    missing,
    () => undefined,
  )
  try {
    for (const width of [0, 1, 8, 80]) {
      const lines = takeover.render(width)
      assert.ok(lines.every((line) => visibleWidth(line) <= width))
      assert.doesNotMatch(lines.join("\n"), /[┌┐└┘│─╭╮╰╯]/)
      if (width === 80)
        assert.match(lines.join("\n"), /sa-missing is no longer tracked/)
    }
  } finally {
    takeover.dispose()
  }
})

void test("transcript renders assistant Markdown without raw emphasis", () => {
  const snap: SubagentSnapshot = {
    ...snapshot(),
    transcript: [
      {
        kind: "assistant",
        parts: [
          { type: "thinking", text: "**Checking bindings**" },
          { type: "text", text: "**Result** uses `model`." },
        ],
      },
    ],
    liveTools: [],
    queued: [],
    liveAssistant: { thinking: "**Next step**", text: "**Working**" },
  }
  const lines = buildTranscriptLines(snap, 80, theme).map(
    stripVTControlCharacters,
  )
  const text = lines.join("\n")
  assert.match(text, /Checking bindings/)
  assert.match(text, /Result uses model/)
  assert.match(text, /Next step/)
  assert.match(text, /Working/)
  assert.doesNotMatch(text, /\*\*|`/)
  assert.doesNotMatch(text, /~ /)
})

void test("tool renderers wrap calls and show result and errors", () => {
  const renderers = subagentToolRenderers("subagent_wait")
  const call = renderers.renderCall({ ids: ["sa-1", "sa-2"] }, theme)
  assert.match(
    stripVTControlCharacters(call.render(80).join("\n")),
    /subagent_wait sa-1, sa-2/,
  )

  const result = {
    content: [{ type: "text" as const, text: "failure\nmore output" }],
    details: undefined,
  }

  for (const width of [0, 1, 8, 40]) {
    for (const line of call.render(width))
      assert.ok(
        visibleWidth(line) <= width,
        `width ${width}: ${JSON.stringify(line)}`,
      )

    for (const line of renderers
      .renderResult(result, { expanded: true }, theme, { isError: true })
      .render(width))
      assert.ok(visibleWidth(line) <= width)
  }

  assert.match(
    stripVTControlCharacters(
      renderers
        .renderResult(result, { expanded: false }, theme, { isError: true })
        .render(80)
        .join("\n"),
    ),
    /failure/,
  )
})

void test("dashboard running icons request redraws and stop after settle or disposal", (context) => {
  context.mock.timers.enable({ apis: ["Date", "setInterval"], now: 0 })
  const { tui, keys, view, setSnapshot } = setup()
  const redraw = context.mock.method(tui, "requestRender", () => undefined)
  const dashboard = new SubagentDashboard(
    tui,
    theme,
    keys,
    view,
    { index: 0 },
    () => undefined,
  )
  try {
    assert.match(dashboard.render(160).join("\n"), /◜/)
    context.mock.timers.tick(120)
    assert.equal(redraw.mock.callCount(), 1)
    assert.match(dashboard.render(160).join("\n"), /◝/)
    setSnapshot({ ...snapshot(), status: "done" })
    context.mock.timers.tick(120)
    assert.equal(redraw.mock.callCount(), 1)
    assert.match(dashboard.render(160).join("\n"), /✓/)
    setSnapshot(snapshot())
    dashboard.dispose()
    context.mock.timers.tick(120)
    assert.equal(redraw.mock.callCount(), 1)
  } finally {
    dashboard.dispose()
  }
})
