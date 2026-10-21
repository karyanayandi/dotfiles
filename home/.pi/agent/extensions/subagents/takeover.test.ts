import assert from "node:assert/strict"
import { stripVTControlCharacters } from "node:util"
import test from "node:test"
import { theme } from "./test-theme.ts"
import type { SubagentSnapshot } from "./src/domain.ts"
import { buildTranscriptLines } from "./src/ui/transcript.ts"
import {
  reconcileDashboardSelection,
  type DashboardSelection,
} from "./src/ui/takeover.ts"

void test("detail transcript follows compact Pi message spacing", () => {
  const snapshot: SubagentSnapshot = {
    id: "sa-1",
    origin: "model",
    backend: "pi",
    title: "spacing demo",
    prompt: "show spacing",
    cwd: "/tmp/project",
    status: "done",
    createdAt: 0,
    meta: { backend: "pi" },
    usage: {},
    transcript: [
      { kind: "user", text: "prompt" },
      {
        kind: "assistant",
        parts: [
          { type: "thinking", text: "reasoning" },
          { type: "text", text: "answer" },
        ],
      },
      { kind: "user", text: "follow-up" },
    ],
    liveTools: [],
    queued: [],
    finalText: "answer",
    turns: 1,
  }

  const lines = buildTranscriptLines(snapshot, 80, theme).map((line) =>
    stripVTControlCharacters(line).trimEnd(),
  )

  assert.deepEqual(lines, [
    "  User: prompt",
    "",
    " reasoning",
    "",
    " answer",
    "  User: follow-up",
  ])
})

void test("dashboard selection follows its subagent id and falls back by row", () => {
  const selection: DashboardSelection = { id: "sa-7", index: 6 }

  reconcileDashboardSelection(selection, [
    { id: "sa-new" },
    ...Array.from({ length: 8 }, (_, index) => ({ id: `sa-${index + 1}` })),
  ])
  assert.deepEqual(selection, { id: "sa-7", index: 7 })

  reconcileDashboardSelection(selection, [
    ...Array.from({ length: 6 }, (_, index) => ({ id: `sa-${index + 1}` })),
    { id: "sa-8" },
    { id: "sa-9" },
  ])
  assert.deepEqual(selection, { id: "sa-9", index: 7 })

  reconcileDashboardSelection(selection, [{ id: "sa-1" }, { id: "sa-2" }])
  assert.deepEqual(selection, { id: "sa-2", index: 1 })

  reconcileDashboardSelection(selection, [])
  assert.deepEqual(selection, { id: undefined, index: 0 })
})

void test("takeover delegates rich tool rows to an installed transcript renderer", () => {
  const key = Symbol.for("pi-subagents.transcriptToolRenderer.v1")

  const globals: typeof globalThis & {
    [key]?: (request: {
      call: { displayArgs?: unknown }
      result?: { displayResult?: unknown }
    }) => string[] | undefined
  } = globalThis

  const previous = globals[key]
  globals[key] = ({ call, result }) => [
    `display call ${JSON.stringify(call.displayArgs)}`,
    `display result ${JSON.stringify(result?.displayResult)}`,
  ]

  const snapshot: SubagentSnapshot = {
    id: "sa-1",
    origin: "model",
    backend: "pi",
    title: "edit demo",
    prompt: "edit a file",
    cwd: "/tmp/project",
    status: "done",
    createdAt: 0,
    meta: { backend: "pi" },
    usage: {},
    transcript: [
      {
        kind: "assistant",
        parts: [
          {
            type: "toolCall",
            toolId: "tool-1",
            name: "edit",
            argsPreview: '{"path":"demo.ts"}',
            displayArgs: { path: "demo.ts" },
          },
        ],
      },
      {
        kind: "toolResult",
        toolId: "tool-1",
        name: "edit",
        isError: false,
        outputPreview: "updated demo.ts",
        displayResult: { details: { diff: "+new" } },
      },
    ],
    liveTools: [],
    queued: [],
    finalText: "",
    turns: 1,
  }

  try {
    const rendered = buildTranscriptLines(snapshot, 120, theme).join("\n")
    assert.match(rendered, /display call \{"path":"demo.ts"\}/)
    assert.match(rendered, /display result \{"details":\{"diff":"\+new"\}\}/)
    assert.doesNotMatch(rendered, /output: updated demo\.ts/)
  } finally {
    if (previous) globals[key] = previous
    else delete globals[key]
  }
})
