import assert from "node:assert/strict"
import test from "node:test"
import type { Theme } from "@earendil-works/pi-coding-agent"
import type { SubagentSnapshot } from "./src/domain.ts"
import { buildTranscriptLines } from "./src/ui/transcript.ts"
import {
  reconcileDashboardSelection,
  type DashboardSelection,
} from "./src/ui/takeover.ts"

const theme = {
  bold: (text: string) => text,
  fg: (_color: string, text: string) => text,
  italic: (text: string) => text,
} as unknown as Theme

test("dashboard selection follows its subagent id and falls back by row", () => {
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

test("takeover delegates rich tool rows to an installed transcript renderer", () => {
  const key = Symbol.for("pi-subagents.transcriptToolRenderer.v1")
  const globals = globalThis as typeof globalThis & {
    [key]?: (request: {
      call: { displayArgs?: unknown }
      result?: { displayResult?: unknown }
    }) => string[] | undefined
  }
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
