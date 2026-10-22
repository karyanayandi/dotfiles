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
  type AgentToolResult,
  type ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent"
import terminals from "./index.ts"
import { theme } from "@pi/shared/test-theme"

type TerminalTestContext = Pick<
  ExtensionCommandContext,
  "cwd" | "hasUI" | "isIdle"
> & {
  ui: Pick<ExtensionCommandContext["ui"], "theme" | "setStatus" | "setWidget">
}

interface StartToolParameters {
  command: string
  title: string
  working_dir?: string
}

interface KillToolParameters {
  ids: string[]
}

interface TerminalTestTool<TParams> {
  execute(
    this: void,
    toolCallId: string,
    params: TParams,
    signal: AbortSignal | undefined,
    onUpdate: undefined,
    ctx: TerminalTestContext,
  ): Promise<AgentToolResult<unknown>>
}

await test(
  "terminal footer follows subagent design and clears on shutdown",
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
    } satisfies TerminalTestContext

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

    const spawnDefinition = extension.tools.get("bg_start")?.definition
    const killDefinition = extension.tools.get("bg_kill")?.definition
    assert.ok(spawnDefinition)
    assert.ok(killDefinition)
    const spawn: TerminalTestTool<StartToolParameters> = spawnDefinition
    const kill: TerminalTestTool<KillToolParameters> = killDefinition

    const params = {
      command: `"${process.execPath}" -e "setTimeout(() => {}, 60000)"`,
      title: "footer demo",
    }

    try {
      await emit("session_start")
      await spawn.execute("start", params, undefined, undefined, ctx)

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
        /^background terminal: [◜◝◞◟] 1 running · \/ps to view$/,
      )
      assert.deepEqual(widgets, [])
      await kill.execute("kill", { ids: ["bt-1"] }, undefined, undefined, ctx)

      for (
        let attempt = 0;
        attempt < 100 && !statuses.at(-1)?.includes("✕ 1 failed");
        attempt++
      )
        await delay(20)
      assert.equal(
        statuses.at(-1),
        "background terminal: ✕ 1 failed · /ps to view",
      )
      const settled = statuses.length
      await delay(300)
      assert.equal(statuses.length, settled)
      await spawn.execute("restart", params, undefined, undefined, ctx)

      for (
        let attempt = 0;
        attempt < 100 && !/[◜◝◞◟]/.test(statuses.at(-1) ?? "");
        attempt++
      )
        await delay(20)
      assert.match(
        statuses.at(-1) ?? "",
        /^background terminal: [◜◝◞◟] 1 running · ✕ 1 failed · \/ps to view$/,
      )

      for (const exitCode of [0, 1]) {
        await spawn.execute(
          `exit-${exitCode}`,
          {
            command: `"${process.execPath}" -e "process.exit(${exitCode})"`,
            title: `exit ${exitCode}`,
          },
          undefined,
          undefined,
          ctx,
        )
        const outcome = exitCode === 0 ? "✓ 1 done" : "✕ 2 failed"

        for (
          let attempt = 0;
          attempt < 100 && !statuses.at(-1)?.includes(outcome);
          attempt++
        )
          await delay(20)
        assert.ok(statuses.at(-1)?.includes(outcome))
      }

      assert.match(
        statuses.at(-1) ?? "",
        /^background terminal: [◜◝◞◟] 1 running · ✓ 1 done · ✕ 2 failed · \/ps to view$/,
      )
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
