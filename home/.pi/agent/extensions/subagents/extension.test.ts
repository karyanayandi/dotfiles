import assert from "node:assert/strict"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"
import {
  DefaultResourceLoader,
  ExtensionRunner,
  ModelRegistry,
  ModelRuntime,
  SessionManager,
  SettingsManager,
} from "@earendil-works/pi-coding-agent"
import subagents from "./index.ts"
import { AsyncEventQueue } from "./src/backend.ts"
import { piBackend } from "./src/backends/pi.ts"
import type { SubagentEvent } from "./src/domain.ts"
import { theme } from "./test-theme.ts"
import { ACTIVITY_FRAME_MS } from "@pi/shared/activity-status"

void test("SDK loads Pi-only subagent tools without a harness parameter", async () => {
  const directory = await mkdtemp(join(tmpdir(), "pi-subagents-extension-"))

  try {
    const loader = new DefaultResourceLoader({
      cwd: directory,
      agentDir: join(directory, "agent"),
      settingsManager: SettingsManager.inMemory(undefined, {
        projectTrusted: false,
      }),
      extensionFactories: [subagents],
    })

    await loader.reload()
    const loaded = loader.getExtensions()
    assert.deepEqual(loaded.errors, [])

    const tools = loaded.extensions.flatMap((extension) =>
      [...extension.tools.values()].map((tool) => tool.definition),
    )

    assert.deepEqual(tools.map((tool) => tool.name).sort(), [
      "subagent_cancel",
      "subagent_check",
      "subagent_list",
      "subagent_spawn",
      "subagent_wait",
    ])
    const spawn = tools.find((tool) => tool.name === "subagent_spawn")
    assert.ok(spawn)
    const schema = JSON.stringify(spawn.parameters)
    assert.doesNotMatch(schema, /harness|codex/i)

    for (const field of [
      "prompt",
      "name",
      "working_dir",
      "model",
      "reasoning_effort",
    ]) {
      assert.ok(schema.includes(`"${field}"`), `${field} must remain available`)
    }

    assert.match(spawn.description, /in.process/i)

    const commands = loaded.extensions.flatMap((extension) => [
      ...extension.commands.keys(),
    ])

    assert.ok(commands.includes("subagent-defaults"))
    assert.ok(commands.includes("subagents"))
    assert.ok(commands.includes("btw"))
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})

void test("footer animates idle running agents and stops after completion and shutdown", async (context) => {
  const directory = await mkdtemp(join(tmpdir(), "pi-subagent-status-"))
  const events = new AsyncEventQueue<SubagentEvent>()
  context.mock.method(piBackend, "spawn", () =>
    Promise.resolve({
      meta: () => ({ backend: "pi" as const, contextWindow: 100_000 }),
      events,
      send: () => Promise.resolve(),
      interrupt: () => Promise.resolve(),
      dispose: () => Promise.resolve(events.close()),
    }),
  )
  const statuses: (string | undefined)[] = []

  const ctx = {
    cwd: directory,
    hasUI: true,
    isIdle: () => false,
    isProjectTrusted: () => false,
    ui: {
      theme,
      setStatus: (_key: string, text: string | undefined) =>
        statuses.push(text),
    },
  }

  const loader = new DefaultResourceLoader({
    cwd: directory,
    agentDir: join(directory, "agent"),
    settingsManager: SettingsManager.inMemory(undefined, {
      projectTrusted: false,
    }),
    extensionFactories: [subagents],
  })

  await loader.reload()
  const loaded = loader.getExtensions()
  context.mock.method(loaded.runtime, "getThinkingLevel", () => "off")
  const extension = loaded.extensions[0]
  assert.ok(extension)

  const modelRuntime = await ModelRuntime.create({
    modelsPath: null,
    refreshOnCreate: false,
  })

  const runner = new ExtensionRunner(
    loaded.extensions,
    loaded.runtime,
    directory,
    SessionManager.inMemory(directory),
    new ModelRegistry(modelRuntime),
  )

  const toolContext = {
    ...runner.createToolContext("test-tool", undefined),
    hasUI: true,
    isIdle: () => false,
    isProjectTrusted: () => false,
    ui: {
      ...runner.getUIContext(),
      theme,
      setStatus: (_key: string, text: string | undefined) => {
        statuses.push(text)
      },
    },
  }

  async function emit(event: string) {
    for (const handler of extension.handlers.get(event) ?? [])
      await handler({ type: event }, ctx)
  }

  try {
    await emit("session_start")
    const spawn = extension.tools.get("subagent_spawn")?.definition
    assert.ok(spawn)
    context.mock.timers.enable({
      apis: ["Date", "setInterval", "setTimeout"],
      now: 0,
    })
    await spawn.execute(
      "demo",
      { name: "status demo", prompt: "hold" },
      undefined,
      undefined,
      toolContext,
    )
    context.mock.timers.tick(100)
    assert.match(statuses.at(-1) ?? "", /◜.*1 running/)

    for (const [name, args] of [
      ["subagent_list", {}],
      ["subagent_check", { id: "sa-1" }],
    ] as const) {
      const tool = extension.tools.get(name)?.definition
      assert.ok(tool)

      const result = await tool.execute(
        name,
        args,
        undefined,
        undefined,
        toolContext,
      )

      assert.doesNotMatch(JSON.stringify(result), /%\/100k/)
    }

    const updates = statuses.length
    context.mock.timers.tick(ACTIVITY_FRAME_MS)
    assert.equal(statuses.length, updates + 1)
    assert.match(statuses.at(-1) ?? "", /◝.*1 running/)
    events.push({
      _tag: "RunSettled",
      outcome: { _tag: "Completed", finalText: "done" },
    })
    await new Promise<void>((resolve) => setImmediate(resolve))
    context.mock.timers.tick(100)
    assert.match(statuses.at(-1) ?? "", /1 done/)
    const settledUpdates = statuses.length
    context.mock.timers.tick(ACTIVITY_FRAME_MS * 3)
    assert.equal(statuses.length, settledUpdates)
    await spawn.execute(
      "demo-2",
      { name: "shutdown demo", prompt: "hold" },
      undefined,
      undefined,
      toolContext,
    )
    context.mock.timers.tick(100)
    const beforeShutdown = statuses.length
    context.mock.timers.tick(ACTIVITY_FRAME_MS)
    assert.equal(statuses.length, beforeShutdown + 1)
    await emit("session_shutdown")
    assert.equal(statuses.at(-1), undefined)
    const shutdownUpdates = statuses.length
    context.mock.timers.tick(ACTIVITY_FRAME_MS * 3)
    assert.equal(statuses.length, shutdownUpdates)
  } finally {
    await emit("session_shutdown")
    await rm(directory, { recursive: true, force: true })
  }
})
