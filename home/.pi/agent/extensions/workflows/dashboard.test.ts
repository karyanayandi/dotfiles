import assert from "node:assert/strict"
import {
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { stripVTControlCharacters } from "node:util"
import {
  KeybindingsManager,
  ProcessTerminal,
  TUI_KEYBINDINGS,
  visibleWidth,
} from "@earendil-works/pi-tui"
import { TuiMainScreen } from "@earendil-works/pi-tui/dist/tui-main-screen.js"
import { theme } from "../subagents/test-theme.ts"
import { WorkflowDashboard, loadRunEntries } from "./dashboard.ts"

function workflowArtifact() {
  const transcript = [
    {
      role: "user",
      text: "Please inspect \u001b]0;hidden title\u0007src.",
    },
    {
      role: "assistant",
      text: "## **A result**\nThe plan is **ready**; `safe`.",
    },
    { role: "thinking", text: "**Check assumptions** before acting." },
    { role: "tool", name: "read", text: "src/main.ts" },
    { role: "toolResult", name: "read", text: "Read finished" },
    ...Array.from({ length: 45 }, (_, index) => ({
      role: index % 2 === 0 ? "assistant" : "user",
      text: `archive-${index} ${"wrapped detail ".repeat(12)}`,
    })),
  ]

  return {
    sessionId: "fixture-session",
    status: "completed",
    startedAt: 1_000,
    finishedAt: 61_000,
    name: "Build plan 界",
    description: "Inspect the source and verify the result.",
    phases: [{ title: "Gather" }, { title: "Verify" }],
    result: { ok: true },
    agents: [
      {
        index: 1,
        label: "planner 界",
        phase: "Gather",
        state: "done",
        model: "gpt-5",
        contextWindow: 128_000,
        startedAt: 2_000,
        finishedAt: 31_000,
        usage: {
          input: 1_200,
          output: 300,
          contextTokens: 1_500,
          cost: 0.01,
          turns: 2,
        },
        transcript,
      },
      {
        index: 2,
        label: "broken worker",
        phase: "Gather",
        state: "error",
        error: "tool failed",
        startedAt: 3_000,
        finishedAt: 4_000,
        usage: { input: 0, output: 0 },
        transcript: [
          {
            role: "toolResult",
            name: "exec",
            text: "permission denied",
            isError: true,
          },
        ],
      },
      {
        index: 3,
        label: "verifier",
        phase: "Verify",
        state: "done",
        model: "gpt-5",
        startedAt: 5_000,
        finishedAt: 6_000,
        usage: { input: 0, output: 0 },
        transcript: [],
      },
    ],
  }
}

function createDashboardHarness(includeRuns = true) {
  const directory = mkdtempSync(join(tmpdir(), "pi-workflow-dashboard-ui-"))
  const previous = process.env.PI_CODING_AGENT_DIR
  process.env.PI_CODING_AGENT_DIR = directory

  if (includeRuns) {
    const workflows = [
      { runId: "wf_fixture", artifact: workflowArtifact() },
      {
        runId: "wf_empty",
        artifact: {
          sessionId: "fixture-session",
          status: "failed",
          startedAt: 0,
          finishedAt: 1,
          name: "Empty run",
          error: "script failed",
          phases: [],
          agents: [],
        },
      },
    ]

    for (const { runId, artifact } of workflows) {
      const runDir = join(directory, "workflows", runId)
      mkdirSync(runDir, { recursive: true })
      writeFileSync(join(runDir, "workflow.json"), JSON.stringify(artifact))
    }
  }

  const tui = new TuiMainScreen(new ProcessTerminal())
  tui.requestRender = () => undefined
  const dashboard = new WorkflowDashboard(
    tui,
    theme,
    new KeybindingsManager(TUI_KEYBINDINGS),
    () => new Map(),
    "fixture-session",
    new Set(),
    () => undefined,
  )

  return {
    dashboard,
    tui,
    directory,
    dispose() {
      dashboard.dispose()
      if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR
      else process.env.PI_CODING_AGENT_DIR = previous
      rmSync(directory, { recursive: true, force: true })
    },
  }
}

function setRows(tui: TuiMainScreen, rows: number) {
  Object.defineProperty(tui.terminal, "rows", {
    value: rows,
    configurable: true,
  })
}

function plainText(dashboard: WorkflowDashboard, width = 80) {
  return dashboard.render(width).map(stripVTControlCharacters).join("\n")
}

function assertScreen(
  dashboard: WorkflowDashboard,
  width: number,
  rows: number,
) {
  const lines = dashboard.render(width)

  if (width === 0) {
    assert.deepEqual(lines, [])

    return
  }

  assert.equal(lines.length, rows - 1)
  for (const line of lines)
    assert.ok(
      visibleWidth(line) <= width,
      `width ${width}: ${JSON.stringify(line)}`,
    )

  const text = lines.map(stripVTControlCharacters).join("\n")
  assert.doesNotMatch(text, /[┌┐└┘│─╭╮╰╯]/)
  assert.doesNotMatch(text, /■/)
}

test("dashboard loads legacy artifacts, filters sessions, and recovers stale runs", () => {
  const directory = mkdtempSync(join(tmpdir(), "pi-workflow-dashboard-"))
  const previous = process.env.PI_CODING_AGENT_DIR
  process.env.PI_CODING_AGENT_DIR = directory

  try {
    const runDir = join(directory, "workflows", "wf_fixture")
    mkdirSync(runDir, { recursive: true })
    writeFileSync(
      join(runDir, "workflow.json"),
      JSON.stringify({
        sessionId: "fixture-session",
        status: "running",
        startedAt: 10,
        meta: {
          name: "legacy",
          description: "fixture",
          phases: [{ title: "Scan", detail: "files" }],
        },
        agents: [
          null,
          {
            state: "running",
            label: "worker",
            startedAt: 11,
            usage: { input: 20, output: 5, contextTokens: 25 },
            contextWindow: 100,
          },
        ],
        transcriptArtifact: "transcripts.json",
        resultArtifact: "result.json",
      }),
    )
    writeFileSync(
      join(runDir, "transcripts.json"),
      JSON.stringify({
        "1": [
          null,
          { role: "invalid", text: "ignored" },
          { role: "assistant", text: "hello", timestamp: 12 },
        ],
      }),
    )
    writeFileSync(join(runDir, "result.json"), '{"ok":true}')

    assert.deepEqual(loadRunEntries(new Map(), "other-session", new Set()), [])
    const entries = loadRunEntries(new Map(), "fixture-session", new Set())
    assert.equal(entries.length, 1)
    const details = entries[0].details
    assert.equal(details.name, "legacy")
    assert.equal(details.description, "fixture")
    assert.deepEqual(details.phases, [{ title: "Scan", detail: "files" }])
    assert.equal(details.status, "aborted")
    assert.equal(details.agents[0].state, "error")
    assert.equal(details.agents[0].index, 1)
    assert.equal(details.agents[0].usage.input, 20)
    assert.equal(details.agents[0].usage.contextTokens, 25)
    assert.deepEqual(details.result, { ok: true })
    assert.deepEqual(details.agents[0].transcript, [
      {
        role: "assistant",
        text: "hello",
        name: undefined,
        isError: false,
        timestamp: 12,
      },
    ])
    assert.equal(
      loadRunEntries(new Map(), "other-session", new Set(["wf_fixture"]))
        .length,
      1,
    )
  } finally {
    if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR
    else process.env.PI_CODING_AGENT_DIR = previous
    rmSync(directory, { recursive: true, force: true })
  }
})

test("workflow screens stay borderless, bounded, and fixed-height", () => {
  const harness = createDashboardHarness()
  const { dashboard, tui } = harness

  try {
    for (const rows of [4, 8, 24, 40]) {
      setRows(tui, rows)
      for (const width of [0, 1, 2, 8, 24, 80, 160])
        assertScreen(dashboard, width, rows)
    }

    const list = plainText(dashboard)
    assert.match(list, /^  Workflows/m)
    assert.match(list, /› ✓ Build plan 界/)
    assert.doesNotMatch(list, /■/)
    setRows(tui, 4)
    const shortList = dashboard.render(80).map(stripVTControlCharacters)
    assert.match(shortList.join("\n"), /› ✓ Build plan 界/)
    assert.match(shortList.at(-1) ?? "", /select/)

    dashboard.handleInput("\r")
    for (const rows of [4, 8, 24, 40]) {
      setRows(tui, rows)
      for (const width of [0, 1, 2, 8, 24, 80, 160])
        assertScreen(dashboard, width, rows)
    }

    const detail = plainText(dashboard)
    assert.match(detail, /Gather/)
    assert.match(detail, /planner 界/)
    assert.match(detail, /Verify/)
    assert.match(detail, /gpt-5/)
    assert.match(detail, /1\.2k in/)
    setRows(tui, 4)
    const shortDetail = dashboard.render(80).map(stripVTControlCharacters)
    assert.match(shortDetail.join("\n"), /› .*Gather/)
    assert.match(shortDetail.at(-1) ?? "", /back/)
  } finally {
    harness.dispose()
  }
})

test("phase and agent focus navigate to a compact Markdown transcript", () => {
  const harness = createDashboardHarness()
  const { dashboard, tui } = harness
  setRows(tui, 24)

  try {
    dashboard.handleInput("\r")
    dashboard.handleInput("j")
    assert.match(plainText(dashboard), /› .*Verify/)
    assert.match(plainText(dashboard), /verifier/)
    dashboard.handleInput("l")
    dashboard.handleInput("\r")
    assert.match(plainText(dashboard), /transcript unavailable/)
    dashboard.handleInput("\u001b")

    dashboard.handleInput("h")
    dashboard.handleInput("k")
    dashboard.handleInput("l")
    assert.match(plainText(dashboard), /› .*planner 界/)
    dashboard.handleInput("j")
    assert.match(plainText(dashboard), /› .*broken worker/)
    assert.match(plainText(dashboard), /tool failed/)
    dashboard.handleInput("\r")
    assert.match(plainText(dashboard), /permission denied/)
    dashboard.handleInput("\u001b")
    dashboard.handleInput("k")
    dashboard.handleInput("\r")

    for (const rows of [4, 8, 24, 40]) {
      setRows(tui, rows)
      for (const width of [0, 1, 2, 8, 24, 80, 160])
        assertScreen(dashboard, width, rows)
    }
    setRows(tui, 24)

    const top = plainText(dashboard)
    assert.match(top, /Please inspect src/)
    assert.match(top, /A result/)
    assert.match(top, /Check assumptions/)
    assert.match(top, /read.*src\/main\.ts/)
    assert.match(top, /Read finished/)
    assert.doesNotMatch(top, /USER|ASSISTANT|THINKING|\*\*|`/)
    assert.doesNotMatch(top, /hidden title|\u001b/)

    dashboard.handleInput("j")
    assert.notEqual(plainText(dashboard), top)
    dashboard.handleInput("k")
    assert.equal(plainText(dashboard), top)
    dashboard.handleInput("\u0004")
    assert.notEqual(plainText(dashboard), top)
    dashboard.handleInput("G")
    assert.match(plainText(dashboard), /archive-44/)
    dashboard.handleInput("g")
    assert.match(plainText(dashboard), /Please inspect src/)
    dashboard.handleInput("\u001b")
    assert.match(plainText(dashboard), /planner 界/)
    dashboard.handleInput("h")
    assert.match(plainText(dashboard), /› .*Gather/)
  } finally {
    harness.dispose()
  }
})

test("empty and failed runs render notices and save an inspectable report", () => {
  const emptyHarness = createDashboardHarness(false)

  try {
    setRows(emptyHarness.tui, 24)
    assert.match(plainText(emptyHarness.dashboard), /no workflow runs yet/)
    assert.doesNotMatch(plainText(emptyHarness.dashboard), /[┌┐└┘│─╭╮╰╯]/)
  } finally {
    emptyHarness.dispose()
  }

  const harness = createDashboardHarness()
  const { dashboard, directory, tui } = harness
  setRows(tui, 24)

  try {
    dashboard.handleInput("j")
    dashboard.handleInput("\r")
    assert.match(plainText(dashboard), /Empty run/)
    assert.match(plainText(dashboard), /script failed/)
    assert.match(plainText(dashboard), /no agents/i)
    dashboard.handleInput("\u001b")
    dashboard.handleInput("k")
    dashboard.handleInput("\r")
    dashboard.handleInput("s")

    const report = readFileSync(
      join(directory, "workflows", "wf_fixture", "report.md"),
      "utf8",
    )
    assert.match(report, /^# Workflow Build plan 界/m)
    assert.match(report, /Status: done/)
    assert.match(report, /## Gather/)
    assert.match(report, /tool failed/)
    assert.match(plainText(dashboard), /saved .*report\.md/)
  } finally {
    harness.dispose()
  }
})
