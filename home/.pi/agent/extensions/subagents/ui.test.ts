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

function setup() {
  const snap = snapshot()
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
    snap,
    sent,
    aborted,
    view,
    tui,
    keys: new KeybindingsManager(TUI_KEYBINDINGS),
  }
}

for (const width of [0, 1, 2, 8, 24, 80]) {
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

        if (width >= 8) {
          assert.ok(stripVTControlCharacters(lines[0]).startsWith("┌"))
          assert.ok(
            lines.some((line) =>
              stripVTControlCharacters(line).startsWith("└"),
            ),
          )
          assert.doesNotMatch(lines.join("\n"), /[╭╮╰╯]/)
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

  assert.match(text, / {2}› hello/)
  assert.match(text, / {2}✓ read file.ts/)
  assert.match(text, / {2}saved output/)
  assert.match(text, / {2}· bash/)
  assert.match(text, /queued steer/)
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
