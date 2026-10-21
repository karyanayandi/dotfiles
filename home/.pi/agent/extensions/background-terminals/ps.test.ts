import assert from "node:assert/strict"
import test from "node:test"
import { stripVTControlCharacters } from "node:util"
import type {
  ExtensionCommandContext,
  Theme,
} from "@earendil-works/pi-coding-agent"
import {
  KeybindingsManager,
  ProcessTerminal,
  TUI_KEYBINDINGS,
  visibleWidth,
  type Component,
  type TUI,
} from "@earendil-works/pi-tui"
import { TuiMainScreen } from "@earendil-works/pi-tui/dist/tui-main-screen.js"
import type { TerminalSnapshot } from "./src/domain.ts"
import type { TerminalReadModel } from "./src/manager.ts"
import { openTerminalPicker, reconcileDashboardSelection } from "./src/ps.ts"
import {
  buildOutputLines,
  createOutputLineCache,
  sanitizeText,
} from "./src/ui/output-view.ts"
import { ACTIVITY_FRAME_MS } from "@pi/shared/activity-status"
import { theme } from "../subagents/test-theme.ts"

interface CapturedComponent extends Component {
  dispose?(): void
}

type PickerTestUI = Pick<ExtensionCommandContext["ui"], "notify"> & {
  custom<T>(
    factory: (
      tui: TUI,
      theme: Theme,
      keybindings: Pick<KeybindingsManager, "getKeys" | "matches">,
      done: (result: T) => void,
    ) => CapturedComponent | Promise<CapturedComponent>,
    options?: Parameters<ExtensionCommandContext["ui"]["custom"]>[1],
  ): Promise<T>
}

function terminal(
  id: string,
  status: TerminalSnapshot["status"] = "running",
  overrides: Partial<TerminalSnapshot> = {},
): TerminalSnapshot {
  const createdAt = Date.now() - 35_000
  const stdoutText = Array.from(
    { length: 40 },
    (_, index) => `stdout line ${index}`,
  ).join("\n")
  const stderrText = Array.from(
    { length: 40 },
    (_, index) => `stderr line ${index}`,
  ).join("\n")
  const base: TerminalSnapshot = {
    id,
    command: "printf 'hello world'",
    title: "Worker 界",
    cwd: "/tmp/worker 界",
    pid: 1234,
    status,
    createdAt,
    stdout: {
      text: stdoutText,
      totalBytes: Buffer.byteLength(stdoutText),
      truncatedBytes: 0,
    },
    stderr: {
      text: stderrText,
      totalBytes: Buffer.byteLength(stderrText),
      truncatedBytes: 0,
    },
  }

  if (status === "done") {
    Object.assign(base, { settledAt: Date.now(), exitCode: 0 })
  } else if (status === "failed") {
    Object.assign(base, { settledAt: Date.now(), exitCode: 1 })
  } else if (status === "killed") {
    Object.assign(base, { settledAt: Date.now(), signal: "SIGTERM" })
  }

  return { ...base, ...overrides }
}

function createHarness(
  initial: readonly TerminalSnapshot[],
  renderTheme: Theme = theme,
) {
  const snapshots = new Map(initial.map((snap) => [snap.id, snap]))
  const components: CapturedComponent[] = []
  const killed: string[] = []
  const notifications: string[] = []
  const globalListeners = new Set<() => void>()
  const detailListeners = new Map<string, Set<() => void>>()
  let globalUnsubscribes = 0
  let detailUnsubscribes = 0
  let renderRequests = 0

  const view: TerminalReadModel = {
    list: () => [...snapshots.values()],
    get: (id) => snapshots.get(id),
    size: () => snapshots.size,
    subscribe(listener) {
      globalListeners.add(listener)

      return () => {
        globalListeners.delete(listener)
        globalUnsubscribes++
      }
    },
    subscribeTo(id, listener) {
      const listeners = detailListeners.get(id) ?? new Set<() => void>()
      listeners.add(listener)
      detailListeners.set(id, listeners)

      return () => {
        listeners.delete(listener)
        detailUnsubscribes++
      }
    },
    requestKill(id) {
      killed.push(id)
    },
    setOnSettled: () => undefined,
  }

  const tui = new TuiMainScreen(new ProcessTerminal())
  tui.requestRender = () => {
    renderRequests++
  }

  const keybindings = new KeybindingsManager(TUI_KEYBINDINGS)
  const ui: PickerTestUI = {
    custom<T>(
      factory: (
        tui: TUI,
        theme: Theme,
        keybindings: Pick<KeybindingsManager, "getKeys" | "matches">,
        done: (result: T) => void,
      ) => CapturedComponent | Promise<CapturedComponent>,
    ) {
      return new Promise<T>((resolve, reject) => {
        let component: CapturedComponent | undefined
        let doneCalled = false
        const done = (value: T) => {
          doneCalled = true
          component?.dispose?.()
          resolve(value)
        }

        Promise.resolve(factory(tui, renderTheme, keybindings, done)).then(
          (created) => {
            component = created
            components.push(created)
            if (doneCalled) created.dispose?.()
          },
          reject,
        )
      })
    },
    notify(message) {
      notifications.push(message)
    },
  }

  return {
    components,
    killed,
    notifications,
    tui,
    view,
    get globalUnsubscribes() {
      return globalUnsubscribes
    },
    get detailUnsubscribes() {
      return detailUnsubscribes
    },
    get renderRequests() {
      return renderRequests
    },
    setSnapshot(snap: TerminalSnapshot) {
      snapshots.set(snap.id, snap)
      for (const listener of globalListeners) listener()
      for (const listener of detailListeners.get(snap.id) ?? []) listener()
    },
    removeSnapshot(id: string) {
      snapshots.delete(id)
      for (const listener of globalListeners) listener()
      for (const listener of detailListeners.get(id) ?? []) listener()
    },
    run: () => openTerminalPicker({ ui }, view),
  }
}

async function componentAt(
  harness: ReturnType<typeof createHarness>,
  index: number,
): Promise<CapturedComponent> {
  for (let attempt = 0; attempt < 10 && !harness.components[index]; attempt++) {
    await new Promise<void>((resolve) => setTimeout(resolve, 0))
  }

  const component = harness.components[index]
  assert.ok(component, `component ${index} was not created`)

  return component
}

function send(component: Component, data: string) {
  assert.ok(component.handleInput, "component accepts keyboard input")
  component.handleInput(data)
}

function plainLines(component: Component, width: number) {
  return component.render(width).map(stripVTControlCharacters)
}

function plainText(component: Component, width = 80) {
  return plainLines(component, width).join("\n")
}

function withBoldAnsi(): Theme {
  return new Proxy(theme, {
    get(target, property, receiver) {
      if (property === "bold") {
        return (text: string) => `\u001b[1m${text}\u001b[22m`
      }

      return Reflect.get(target, property, receiver)
    },
  })
}

function assertBounded(lines: readonly string[], width: number) {
  for (const line of lines) {
    assert.ok(
      visibleWidth(line) <= width,
      `width ${width}: ${JSON.stringify(line)}`,
    )
  }
}

test("dashboard selection follows its terminal id and falls back by row", () => {
  const selection = { id: "bt-7", index: 6 }

  reconcileDashboardSelection(selection, [
    { id: "bt-new" },
    ...Array.from({ length: 8 }, (_, index) => ({ id: `bt-${index + 1}` })),
  ])
  assert.deepEqual(selection, { id: "bt-7", index: 7 })

  reconcileDashboardSelection(selection, [
    ...Array.from({ length: 6 }, (_, index) => ({ id: `bt-${index + 1}` })),
    { id: "bt-8" },
    { id: "bt-9" },
  ])
  assert.deepEqual(selection, { id: "bt-9", index: 7 })

  reconcileDashboardSelection(selection, [{ id: "bt-1" }, { id: "bt-2" }])
  assert.deepEqual(selection, { id: "bt-2", index: 1 })

  reconcileDashboardSelection(selection, [])
  assert.deepEqual(selection, { id: undefined, index: 0 })
})

test("dashboard and detail are borderless, bounded, and fixed-height", async () => {
  const harness = createHarness([
    terminal("bt-running", "running", { title: "Running 界" }),
    terminal("bt-done", "done", { title: "Finished" }),
    terminal("bt-failed", "failed", { title: "Broken" }),
    terminal("bt-killed", "killed", { title: "Stopped" }),
  ])
  const run = harness.run()

  try {
    const dashboard = await componentAt(harness, 0)
    send(dashboard, "\r")
    const detail = await componentAt(harness, 1)

    for (const width of [0, 1, 2, 8, 24, 80]) {
      for (const component of [dashboard, detail]) {
        const lines = component.render(width)
        assertBounded(lines, width)
        if (width === 0) assert.deepEqual(lines, [])

        const text = lines.map(stripVTControlCharacters).join("\n")
        assert.doesNotMatch(text, /[┌┐└┘│─╭╮╰╯]/)
      }
    }

    const dashboardText = plainText(dashboard)
    assert.match(dashboardText, /^  /)
    assert.match(dashboardText, /1\/4 running/)
    assert.match(dashboardText, /[◜◝◞◟] Running 界/)
    assert.match(dashboardText, /✓ Finished/)
    assert.match(dashboardText, /✕ Broken/)
    assert.match(dashboardText, /▪ Stopped.*killed/)
    assert.equal((dashboardText.match(/›/g) ?? []).length, 1)

    const detailLines = plainLines(detail, 80)
    assert.equal(detailLines.length, 23)
    assert.match(
      detailLines[0],
      /^  [◜◝◞◟] Background process · bt-running · Running 界/,
    )
    assert.match(detailLines[1], /running.*pid 1234.*worker 界/)
    assert.match(detailLines[2], /^  \$ printf 'hello world'/)
    assert.ok(detailLines.some((line) => /stdout \(/.test(line)))
    assert.ok(detailLines.at(-1)?.startsWith("  "))

    for (const rows of [1, 2, 3, 4, 8, 24, 40]) {
      Object.defineProperty(harness.tui.terminal, "rows", {
        value: rows,
        configurable: true,
      })
      for (const component of [dashboard, detail]) {
        const lines = component.render(80)
        assert.ok(lines.length <= Math.max(0, rows - 1))
        assertBounded(lines, 80)
        if (rows >= 24) assert.equal(lines.length, rows - 1)
      }
    }

    send(detail, "\u001b")
    const reopened = await componentAt(harness, 2)
    send(reopened, "\u001b")
    await run
  } finally {
    for (const component of harness.components) component.dispose?.()
  }
})

test("dashboard navigation opens and returns from selected detail, and kills running terminal", async () => {
  const harness = createHarness(
    [
      terminal("bt-running"),
      terminal("bt-done", "done", { title: "Finished" }),
      terminal("bt-other"),
    ],
    withBoldAnsi(),
  )
  const run = harness.run()

  try {
    const dashboard = await componentAt(harness, 0)
    send(dashboard, "x")
    send(dashboard, "j")
    const dashboardText = plainText(dashboard)
    const selectedLine =
      dashboard
        .render(80)
        .find((line) => stripVTControlCharacters(line).includes("Finished")) ??
      ""
    assert.match(dashboardText, /✓ Finished/)
    assert.equal((dashboardText.match(/›/g) ?? []).length, 1)
    assert.match(stripVTControlCharacters(selectedLine), /^› ✓ Finished/)
    assert.doesNotMatch(selectedLine, /\u001b\[(?:1|4\d)m/)
    assert.match(selectedLine, /\u001b\[39m/)
    send(dashboard, "\r")

    const detail = await componentAt(harness, 1)
    assert.match(plainText(detail), /bt-done.*Finished/)
    send(detail, "\u001b")

    const reopened = await componentAt(harness, 2)
    send(reopened, "\u001b")
    await run

    assert.deepEqual(harness.killed, ["bt-running"])
    assert.equal(harness.globalUnsubscribes, 2)
    assert.equal(harness.detailUnsubscribes, 1)
  } finally {
    for (const component of harness.components) component.dispose?.()
  }
})

test("status indicators animate while running and stop their tickers on cleanup", async (context) => {
  context.mock.timers.enable({ apis: ["Date", "setInterval"], now: 0 })
  const running = terminal("bt-running", "running", { title: "Running" })
  const harness = createHarness([
    running,
    terminal("bt-done", "done", { title: "Finished" }),
    terminal("bt-failed", "failed", { title: "Broken" }),
    terminal("bt-killed", "killed", { title: "Stopped" }),
  ])
  const run = harness.run()

  try {
    const dashboard = await componentAt(harness, 0)
    assert.match(plainText(dashboard), /◜ Running/)
    const beforeDashboardTick = harness.renderRequests
    context.mock.timers.tick(ACTIVITY_FRAME_MS)
    assert.equal(harness.renderRequests, beforeDashboardTick + 1)

    const dashboardText = plainText(dashboard)
    assert.match(dashboardText, /◝ Running/)
    assert.match(dashboardText, /✓ Finished/)
    assert.match(dashboardText, /✕ Broken/)
    assert.match(dashboardText, /▪ Stopped.*killed/)
    assert.equal((dashboardText.match(/›/g) ?? []).length, 1)

    send(dashboard, "\r")
    const detail = await componentAt(harness, 1)
    assert.match(
      plainLines(detail, 80)[0],
      /^  ◝ Background process · bt-running · Running$/,
    )

    const beforeDetailTick = harness.renderRequests
    context.mock.timers.tick(ACTIVITY_FRAME_MS)
    assert.equal(harness.renderRequests, beforeDetailTick + 1)
    assert.match(
      plainLines(detail, 80)[0],
      /^  ◞ Background process · bt-running · Running$/,
    )

    harness.setSnapshot({
      ...running,
      status: "done",
      settledAt: Date.now(),
      exitCode: 0,
    })
    await new Promise<void>((resolve) => setTimeout(resolve, 60))
    assert.match(
      plainLines(detail, 80)[0],
      /^  ✓ Background process · bt-running · Running$/,
    )
    const settledRequests = harness.renderRequests
    context.mock.timers.tick(ACTIVITY_FRAME_MS)
    assert.equal(harness.renderRequests, settledRequests)

    send(detail, "\u001b")
    const reopened = await componentAt(harness, 2)
    const idleRequests = harness.renderRequests
    context.mock.timers.tick(ACTIVITY_FRAME_MS)
    assert.equal(harness.renderRequests, idleRequests)
    send(reopened, "\u001b")
    await run

    const closedRequests = harness.renderRequests
    context.mock.timers.tick(ACTIVITY_FRAME_MS * 2)
    assert.equal(harness.renderRequests, closedRequests)
  } finally {
    for (const component of harness.components) component.dispose?.()
  }
})

test("detail switches streams, scrolls, follows live output, shows notices, and cleans up missing snapshots", async () => {
  const initial = terminal("bt-detail")
  const harness = createHarness([initial])
  const run = harness.run()

  try {
    const dashboard = await componentAt(harness, 0)
    send(dashboard, "\r")
    const detail = await componentAt(harness, 1)
    const initialLines = plainLines(detail, 80)
    assert.equal(initialLines.length, 23)
    assert.ok(initialLines.some((line) => line.includes("stdout line 39")))

    send(detail, "t")
    assert.match(plainText(detail), /stderr line 39/)
    assert.doesNotMatch(plainText(detail), /stdout line 39/)

    send(detail, "k")
    assert.match(plainText(detail), /lines below/)
    send(detail, "g")
    assert.match(plainText(detail), /stderr line 0/)
    send(detail, "G")
    assert.match(plainText(detail), /stderr line 39/)

    send(detail, "t")
    const liveText = `${initial.stdout.text}\nstdout live output`
    const liveSnapshot = {
      ...initial,
      stdout: {
        ...initial.stdout,
        text: liveText,
        totalBytes: Buffer.byteLength(liveText),
      },
    }
    const requestsBeforeUpdate = harness.renderRequests
    harness.setSnapshot(liveSnapshot)
    await new Promise<void>((resolve) => setTimeout(resolve, 75))
    assert.ok(harness.renderRequests > requestsBeforeUpdate)
    assert.match(plainText(detail), /stdout live output/)

    const withNotices = {
      ...liveSnapshot,
      errorText: "process failed",
      stdout: {
        ...liveSnapshot.stdout,
        truncatedBytes: 1024,
        spillPath: "/tmp/full.log",
      },
    }
    harness.setSnapshot(withNotices)
    const noticeText = plainText(detail)
    assert.match(noticeText, /error: process failed/)
    assert.match(noticeText, /dropped from view/)
    assert.match(noticeText, /\/tmp\/full\.log/)

    harness.removeSnapshot("bt-detail")
    const missingLines = plainLines(detail, 80)
    assert.equal(missingLines.length, 23)
    assert.match(missingLines.join("\n"), /bt-detail is no longer tracked/)
    assertBounded(missingLines, 80)
    send(detail, "\u001b")
    await run

    assert.equal(harness.globalUnsubscribes, 1)
    assert.equal(harness.detailUnsubscribes, 1)
    assert.deepEqual(harness.notifications, ["No background terminals"])
  } finally {
    for (const component of harness.components) component.dispose?.()
  }
})

test("sanitizeText strips ANSI, tabs, and control characters", () => {
  assert.equal(sanitizeText("\u001b[31mred\u001b[0m"), "red")
  assert.equal(sanitizeText("\u001b[12345Cshifted"), "shifted")
  assert.equal(sanitizeText("\u001b]0;window title\u0007output"), "output")
  assert.equal(
    sanitizeText("\u001b]8;;https://example.com\u001b\\link\u001b]8;;\u001b\\"),
    "link",
  )
  assert.equal(sanitizeText("\u001b]0;title\u009coutput"), "output")
  assert.equal(sanitizeText("\u009d0;title\u0007output"), "output")
  assert.equal(sanitizeText("a\u0085b"), "ab")
  assert.equal(sanitizeText("a\tb"), "a  b")
  assert.equal(sanitizeText("a\u0007b\u0000c"), "abc")
})

test("output line cache reuses a version/width key and invalidates either dimension", () => {
  const cache = createOutputLineCache()
  const first = cache.get("first", 1, 80)
  const sameKey = cache.get("different text is intentionally ignored", 1, 80)
  assert.equal(sameKey, first)
  assert.deepEqual(sameKey, ["first"])

  const newVersion = cache.get("second", 2, 80)
  assert.notEqual(newVersion, first)
  assert.deepEqual(newVersion, ["second"])

  const newWidth = cache.get("x".repeat(25), 2, 10)
  assert.notEqual(newWidth, newVersion)
  assert.ok(newWidth.length > 1)
})

test("buildOutputLines wraps long lines and keeps only the final CR segment", () => {
  const lines = buildOutputLines("progress 1\rprogress 2\rdone\nnext", 80)
  assert.deepEqual(lines, ["done", "next"])
  assert.deepEqual(buildOutputLines("progress 1\rprogress 2\r", 80), [
    "progress 2",
  ])

  const wrapped = buildOutputLines("x".repeat(25), 10)
  assert.ok(wrapped.length > 1)
  assert.equal(wrapped.join(""), "x".repeat(25))
})

test("buildOutputLines drops one trailing empty line from a trailing newline", () => {
  assert.deepEqual(buildOutputLines("a\nb\n", 80), ["a", "b"])
  assert.deepEqual(buildOutputLines("a\n\n", 80), ["a", ""])
})
