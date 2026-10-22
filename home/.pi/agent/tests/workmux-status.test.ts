import assert from "node:assert/strict"
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"
import {
  createEventBus,
  DefaultResourceLoader,
  SettingsManager,
} from "@earendil-works/pi-coding-agent"
import workmuxStatus from "#workmux-status"

await test("workmux validates activity events and preserves status order", async () => {
  const directory = await mkdtemp(join(tmpdir(), "pi-workmux-status-"))
  const log = join(directory, "status.log")
  const originalPath = process.env.PATH
  const events = createEventBus()

  const ctx = {
    cwd: directory,
    isIdle: () => true,
    sessionManager: { getBranch: () => [] },
  }

  try {
    await writeFile(
      join(directory, "workmux"),
      `#!${process.execPath}\nrequire('node:fs').appendFileSync(${JSON.stringify(log)}, process.argv.slice(2).join(' ') + '\\n')\n`,
      { mode: 0o755 },
    )
    process.env.PATH = `${directory}:${originalPath ?? ""}`

    const loader = new DefaultResourceLoader({
      cwd: directory,
      agentDir: join(directory, "agent"),
      eventBus: events,
      settingsManager: SettingsManager.inMemory(undefined, {
        projectTrusted: false,
      }),
      extensionFactories: [workmuxStatus],
    })

    await loader.reload()
    const loaded = loader.getExtensions()
    assert.deepEqual(loaded.errors, [])
    const extension = loaded.extensions[0]
    assert.ok(extension)

    async function emit(event: string) {
      for (const handler of extension.handlers.get(event) ?? []) {
        await handler({ type: event }, ctx)
      }
    }

    await emit("session_start")
    events.emit("suba:activity", { activeCount: 2 })
    await emit("agent_settled")

    for (const value of [
      null,
      [],
      {},
      { activeCount: "0" },
      { activeCount: -1 },
      { activeCount: 0.5 },
      { activeCount: Number.NaN },
      { activeCount: Number.POSITIVE_INFINITY },
      { activeCount: Number.MAX_SAFE_INTEGER + 1 },
    ]) {
      events.emit("suba:activity", value)
      await emit("agent_settled")
    }

    events.emit("suba:activity", { activeCount: 0 })
    await emit("agent_settled")
    await emit("session_shutdown")
    assert.equal(
      await readFile(log, "utf8"),
      "register-agent\nset-window-status working\nset-window-status done\n",
    )
  } finally {
    if (originalPath === undefined) delete process.env.PATH
    else process.env.PATH = originalPath
    await rm(directory, { recursive: true, force: true })
  }
})
