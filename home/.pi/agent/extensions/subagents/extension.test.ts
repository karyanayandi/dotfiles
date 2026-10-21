import assert from "node:assert/strict"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"
import {
  DefaultResourceLoader,
  SettingsManager,
} from "@earendil-works/pi-coding-agent"
import subagents from "./index.ts"

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
