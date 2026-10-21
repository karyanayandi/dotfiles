import assert from "node:assert/strict"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { setTimeout as delay } from "node:timers/promises"
import test from "node:test"
import { stripVTControlCharacters } from "node:util"
import {
  DefaultResourceLoader,
  SettingsManager,
} from "@earendil-works/pi-coding-agent"
import terminals from "./index.ts"
import { theme } from "../subagents/test-theme.ts"

test(
  "running terminals animate in footer and clear on kill and shutdown",
  { timeout: 10_000 },
  async () => {
    const directory = await mkdtemp(join(tmpdir(), "pi-terminal-status-"))
    const statuses: (string | undefined)[] = []
    const widgets: unknown[] = []
    const ctx = {
      cwd: directory,
      hasUI: true,
      isIdle: () => false,
      ui: {
        theme,
        setStatus: (key: string, text: string | undefined) => {
          assert.equal(key, "background-terminals")
          statuses.push(
            text === undefined ? undefined : stripVTControlCharacters(text),
          )
        },
        setWidget: (...args: unknown[]) => widgets.push(args),
      },
    }
    const loader = new DefaultResourceLoader({
      cwd: directory,
      agentDir: join(directory, "agent"),
      settingsManager: SettingsManager.inMemory(undefined, {
        projectTrusted: false,
      }),
      extensionFactories: [terminals],
    })
    await loader.reload()
    const loaded = loader.getExtensions()
    assert.deepEqual(loaded.errors, [])
    const extension = loaded.extensions[0]
    assert.ok(extension)
    async function emit(event: string) {
      for (const handler of extension.handlers.get(event) ?? [])
        await handler({ type: event }, ctx)
    }
    const spawn = extension.tools.get("bg_start")?.definition
    const kill = extension.tools.get("bg_kill")?.definition
    assert.ok(spawn)
    assert.ok(kill)
    const params = {
      command: `"${process.execPath}" -e "setTimeout(() => {}, 60000)"`,
      title: "footer demo",
    }
    try {
      await emit("session_start")
      await Reflect.apply(spawn.execute, spawn, [
        "start",
        params,
        undefined,
        undefined,
        ctx,
      ])
      for (
        let attempt = 0;
        attempt < 100 && new Set(statuses.filter(Boolean)).size < 2;
        attempt++
      )
        await delay(20)
      assert.ok(
        new Set(statuses.filter(Boolean)).size >= 2,
        "footer spinner must advance without output",
      )
      assert.match(
        statuses.at(-1) ?? "",
        /[◜◝◞◟] 1 background terminal running.*\/ps to view/,
      )
      assert.deepEqual(widgets, [])
      await Reflect.apply(kill.execute, kill, [
        "kill",
        { ids: ["bt-1"] },
        undefined,
        undefined,
        ctx,
      ])
      for (
        let attempt = 0;
        attempt < 100 && statuses.at(-1) !== undefined;
        attempt++
      )
        await delay(20)
      assert.equal(statuses.at(-1), undefined)
      const settled = statuses.length
      await delay(300)
      assert.equal(statuses.length, settled)
      await Reflect.apply(spawn.execute, spawn, [
        "restart",
        params,
        undefined,
        undefined,
        ctx,
      ])
      for (let attempt = 0; attempt < 100 && !statuses.at(-1); attempt++)
        await delay(20)
      assert.match(statuses.at(-1) ?? "", /1 background terminal running/)
      await emit("session_shutdown")
      assert.equal(statuses.at(-1), undefined)
      const closed = statuses.length
      await delay(300)
      assert.equal(statuses.length, closed)
      assert.deepEqual(widgets, [])
    } finally {
      await emit("session_shutdown")
      await rm(directory, { recursive: true, force: true })
    }
  },
)
