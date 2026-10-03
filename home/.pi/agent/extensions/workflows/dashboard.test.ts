import assert from "node:assert/strict"
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { loadRunEntries } from "./dashboard.ts"

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
