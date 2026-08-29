/** Promise-based manager integration tests with real child processes. */

import assert from "node:assert/strict"
import * as fs from "node:fs"
import * as os from "node:os"
import * as path from "node:path"
import test from "node:test"
import type { TerminalSnapshot } from "./src/domain.ts"
import {
  MAX_RUNNING,
  MAX_TRACKED,
  type TerminalManagerShape,
} from "./src/manager.ts"
import { createTerminalRuntime, runTool } from "./src/runtime.ts"

const cwd = process.cwd()

function nodeCmd(script: string) {
  return `node -e '${script}'`
}

async function withManager(
  run: (manager: TerminalManagerShape) => Promise<void>,
) {
  const runtime = createTerminalRuntime()
  try {
    await run(runtime.manager)
  } finally {
    await runtime.dispose()
  }
}

function settlement(manager: TerminalManagerShape, id: string) {
  return new Promise<TerminalSnapshot>((resolve) => {
    const existing = manager.view.get(id)
    if (existing && existing.status !== "running") return resolve(existing)
    const unsubscribe = manager.view.subscribeTo(id, () => {
      const snap = manager.view.get(id)
      if (snap && snap.status !== "running") {
        unsubscribe()
        resolve(snap)
      }
    })
  })
}

function processGone(pid: number) {
  try {
    process.kill(pid, 0)
    return false
  } catch {
    return true
  }
}

async function pollUntil(check: () => boolean, timeoutMs = 5_000) {
  const deadline = Date.now() + timeoutMs
  while (!check()) {
    if (Date.now() > deadline) return false
    await new Promise((resolve) => setTimeout(resolve, 25))
  }
  return true
}

test("captures streams, settles once, and flushes full spill before notifying", async () => {
  await withManager(async (manager) => {
    const settled: TerminalSnapshot[] = []
    manager.view.setOnSettled((snap) => settled.push(snap))
    const snap = await manager.start({
      command: nodeCmd(
        'process.stdout.write("out\\n"); process.stderr.write("err\\n")',
      ),
      title: "happy",
      cwd,
    })
    const done = await settlement(manager, snap.id)

    assert.equal(done.status, "done")
    assert.equal(done.exitCode, 0)
    assert.equal(done.stdout.text, "out\n")
    assert.equal(done.stderr.text, "err\n")
    assert.deepEqual(
      settled.map(({ id, status }) => ({ id, status })),
      [{ id: snap.id, status: "done" }],
    )
    if (done.stdout.spillPath)
      assert.equal(fs.readFileSync(done.stdout.spillPath, "utf8"), "out\n")
  })
})

test("non-zero exit and spawn error settle failed with truthful details", async () => {
  await withManager(async (manager) => {
    const failed = await manager.start({
      command: nodeCmd("process.exit(3)"),
      title: "fails",
      cwd,
    })
    assert.equal((await settlement(manager, failed.id)).exitCode, 3)
    assert.equal((await manager.status(failed.id)).status, "failed")

    const badCwd = await manager.start({
      command: "true",
      title: "bad-cwd",
      cwd: "/definitely/not/a/real/dir-12345",
    })
    const spawnError = await settlement(manager, badCwd.id)
    assert.equal(spawnError.status, "failed")
    assert.match(spawnError.errorText ?? "", /ENOENT/)
    assert.equal(spawnError.exitCode, undefined)
  })
})

test("kill waits for settlement, reports repeat kills, and does not duplicate result", async () => {
  await withManager(async (manager) => {
    const consumed: boolean[] = []
    manager.view.setOnSettled((_snap, wasConsumed) =>
      consumed.push(wasConsumed),
    )
    const snap = await manager.start({
      command: nodeCmd("setInterval(() => {}, 1000)"),
      title: "immortal",
      cwd,
    })
    const [first] = await manager.kill([snap.id])
    const [second] = await manager.kill([snap.id])

    assert.deepEqual(
      {
        status: first.status,
        wasRunning: first.wasRunning,
        killed: first.killed,
      },
      { status: "killed", wasRunning: true, killed: true },
    )
    assert.deepEqual(
      {
        status: second.status,
        wasRunning: second.wasRunning,
        killed: second.killed,
      },
      { status: "killed", wasRunning: false, killed: false },
    )
    assert.deepEqual(consumed, [true])
  })
})

test("kill abort stops waiting but detached termination continues", async () => {
  await withManager(async (manager) => {
    const snap = await manager.start({
      command:
        process.platform === "win32"
          ? nodeCmd("setInterval(() => {}, 1000)")
          : `exec ${nodeCmd('process.on("SIGTERM", () => {}); setInterval(() => {}, 1000)')}`,
      title: "abort-race",
      cwd,
    })
    assert.ok(snap.pid)
    const controller = new AbortController()
    const kill = runTool(manager.kill([snap.id]), {
      signal: controller.signal,
      interruptMessage: "aborted",
    })
    controller.abort()
    await assert.rejects(kill, /aborted/)

    const after = await settlement(manager, snap.id)
    assert.equal(after.status, "killed")
    assert.ok(await pollUntil(() => processGone(snap.pid!)))
  })
})

test(
  "SIGTERM-resistant process is escalated within bounded teardown",
  { skip: process.platform === "win32" },
  async () => {
    await withManager(async (manager) => {
      const snap = await manager.start({
        command: `exec ${nodeCmd('process.on("SIGTERM", () => process.stdout.write("term\\n")); process.stdout.write("ready\\n"); setInterval(() => {}, 1000)')}`,
        title: "resistant",
        cwd,
      })
      assert.ok(
        await pollUntil(() =>
          (manager.view.get(snap.id)?.stdout.text ?? "").includes("ready"),
        ),
      )
      const started = Date.now()
      const [result] = await manager.kill([snap.id])
      assert.equal(result.status, "killed")
      assert.equal(manager.view.get(snap.id)?.signal, "SIGKILL")
      assert.ok(Date.now() - started >= 1_500)
      assert.ok(Date.now() - started < 4_500)
    })
  },
)

test(
  "kills POSIX process group and reaps inherited-pipe descendant",
  { skip: process.platform === "win32" },
  async () => {
    await withManager(async (manager) => {
      const sentinelDir = fs.mkdtempSync(
        path.join(os.tmpdir(), "bt-tree-test-"),
      )
      const sentinel = path.join(sentinelDir, "heartbeat")
      try {
        const snap = await manager.start({
          command: `node -e 'const fs = require("node:fs"); const file = ${JSON.stringify(sentinel)}; setInterval(() => fs.writeFileSync(file, String(Date.now())), 25)' & echo "child:$!"; wait`,
          title: "tree",
          cwd,
        })
        assert.ok(
          await pollUntil(() =>
            /child:\d+/.test(manager.view.get(snap.id)?.stdout.text ?? ""),
          ),
        )
        const match = /child:(\d+)/.exec(
          manager.view.get(snap.id)?.stdout.text ?? "",
        )
        assert.ok(match)
        const grandchild = Number(match[1])
        await manager.kill([snap.id])
        assert.ok(await pollUntil(() => processGone(grandchild)))
      } finally {
        fs.rmSync(sentinelDir, { recursive: true, force: true })
      }
    })
  },
)

test("concurrency cap is atomic and settled entries do not consume slots", async () => {
  await withManager(async (manager) => {
    const terminals = await Promise.all(
      Array.from({ length: MAX_RUNNING }, (_, index) =>
        manager.start({
          command: nodeCmd("setInterval(() => {}, 1000)"),
          title: `filler-${index}`,
          cwd,
        }),
      ),
    )
    await assert.rejects(
      manager.start({ command: "true", title: "extra", cwd }),
      new RegExp(`Max ${MAX_RUNNING}`),
    )
    await manager.kill([terminals[0].id])
    const replacement = await manager.start({
      command: "true",
      title: "replacement",
      cwd,
    })
    assert.equal((await settlement(manager, replacement.id)).status, "done")
  })
})

test("pruning keeps running entries and preserves tombstone kill reports", async () => {
  await withManager(async (manager) => {
    const keeper = await manager.start({
      command: nodeCmd("setInterval(() => {}, 1000)"),
      title: "keeper",
      cwd,
    })
    const settledIds: string[] = []
    for (let index = 0; index < MAX_TRACKED + 4; index++) {
      const snap = await manager.start({
        command: "true",
        title: `quick-${index}`,
        cwd,
      })
      settledIds.push(snap.id)
      await settlement(manager, snap.id)
    }
    const ids = manager.view.list().map((snap) => snap.id)
    assert.ok(ids.includes(keeper.id))
    assert.equal(ids.includes(settledIds[0]), false)
    const [history] = await manager.kill([settledIds[0]])
    assert.deepEqual(
      { title: history.title, status: history.status, killed: history.killed },
      { title: "quick-0", status: "done", killed: false },
    )
  })
})

test("dispose kills processes and removes private spill directory", async () => {
  const runtime = createTerminalRuntime()
  const snap = await runtime.manager.start({
    command: nodeCmd("setInterval(() => {}, 1000)"),
    title: "disposed",
    cwd,
  })
  assert.ok(snap.pid)
  const spillDir = path.dirname(snap.stdout.spillPath!)
  await runtime.dispose()
  assert.ok(await pollUntil(() => processGone(snap.pid!)))
  assert.equal(fs.existsSync(spillDir), false)
  await assert.rejects(
    runtime.manager.start({ command: "true", title: "late", cwd }),
    /shutting down/,
  )
})
