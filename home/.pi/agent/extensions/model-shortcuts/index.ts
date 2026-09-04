import { getSupportedThinkingLevels } from "@earendil-works/pi-ai"
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import {
  loadShortcuts,
  nextThinkingLevel,
  saveShortcuts,
  thinkingLevels,
  type ShortcutConfig,
  type ThinkingLevel,
} from "./src/config.ts"
import { pick } from "./src/picker.ts"

type ModelShortcut = `ctrl+${0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9}`

function isModelShortcut(shortcut: string): shortcut is ModelShortcut {
  return /^ctrl\+[0-9]$/.test(shortcut)
}

const availableShortcuts = [
  "ctrl+1",
  "ctrl+2",
  "ctrl+3",
  "ctrl+4",
  "ctrl+5",
  "ctrl+6",
  "ctrl+7",
  "ctrl+8",
  "ctrl+9",
  "ctrl+0",
] as const

function describeTarget({ model, thinkingLevel }: ShortcutConfig) {
  return `${model} · thinking:${thinkingLevel ?? "default"}`
}

function changeThinkingLevel(
  pi: ExtensionAPI,
  levels: readonly ThinkingLevel[],
  direction: -1 | 1,
) {
  const thinkingLevels = levels.filter((level) => level !== "off")
  const next = nextThinkingLevel(
    thinkingLevels.length > 0 ? thinkingLevels : levels,
    pi.getThinkingLevel(),
    direction,
  )
  pi.setThinkingLevel(next)
  return pi.getThinkingLevel()
}

export default function modelShortcuts(pi: ExtensionAPI) {
  for (const [shortcut, direction] of [
    ["ctrl+,", -1],
    ["ctrl+.", 1],
  ] as const) {
    pi.registerShortcut(shortcut, {
      description: `${direction === -1 ? "Lower" : "Raise"} thinking level`,
      handler: async (ctx) => {
        if (!ctx.model) return
        const level = changeThinkingLevel(
          pi,
          getSupportedThinkingLevels(ctx.model),
          direction,
        )
        ctx.ui.notify(`Thinking level: ${level}`, "info")
      },
    })
  }

  pi.registerCommand("model-shortcuts", {
    description: "Configure model keyboard shortcuts",
    handler: async (_args, ctx) => {
      const shortcuts = loadShortcuts()
      const action = await pick(ctx, "Model shortcuts", [
        { value: "set", label: "Add or replace" },
        { value: "remove", label: "Remove" },
      ])
      if (!action) return

      if (action === "remove") {
        const items = Object.entries(shortcuts)
          .sort(([left], [right]) => left.localeCompare(right))
          .map(([shortcut, target]) => ({
            value: shortcut,
            label: shortcut,
            description: describeTarget(target),
          }))
        if (items.length === 0) {
          ctx.ui.notify("No model shortcuts configured", "info")
          return
        }

        const shortcut = await pick(ctx, "Remove shortcut", items)
        if (!shortcut) return
        delete shortcuts[shortcut]
        saveShortcuts(shortcuts)
        ctx.ui.notify(`Removed ${shortcut}; reloading shortcuts`, "info")
        await ctx.reload()
        return
      }

      const items = [
        ...Object.entries(shortcuts)
          .sort(([left], [right]) => left.localeCompare(right))
          .map(([shortcut, target]) => ({
            value: shortcut,
            label: shortcut,
            description: describeTarget(target),
          })),
        ...availableShortcuts
          .filter((shortcut) => !(shortcut in shortcuts))
          .map((shortcut) => ({
            value: shortcut,
            label: shortcut,
            description: "unassigned",
          })),
      ]
      const shortcut = await pick(ctx, "Select shortcut", items)
      if (!shortcut || !isModelShortcut(shortcut)) return

      const models = ctx.modelRegistry
        .getAvailable()
        .map((model) => ({
          value: `${model.provider}/${model.id}`,
          label: model.id,
          description: model.provider,
        }))
        .sort((left, right) => left.value.localeCompare(right.value))
      const model = await pick(ctx, "Select model", models)
      if (!model) return

      const selectedThinkingLevel = await pick(ctx, "Select thinking level", [
        { value: "default", label: "default", description: "Use setting" },
        ...thinkingLevels.map((level) => ({ value: level, label: level })),
      ])
      if (!selectedThinkingLevel) return

      const thinkingLevel = thinkingLevels.find(
        (level) => level === selectedThinkingLevel,
      )
      const target: ShortcutConfig = {
        model,
        ...(thinkingLevel ? { thinkingLevel } : {}),
      }
      shortcuts[shortcut] = target
      saveShortcuts(shortcuts)
      ctx.ui.notify(
        `Saved ${shortcut} → ${describeTarget(target)}; reloading shortcuts`,
        "info",
      )
      await ctx.reload()
    },
  })

  for (const [shortcut, config] of Object.entries(loadShortcuts())) {
    if (!isModelShortcut(shortcut)) {
      console.error(
        `Model shortcuts: only ctrl+0 through ctrl+9 are supported; got ${shortcut}`,
      )
      continue
    }

    const [provider, ...modelParts] = config.model.split("/")
    const modelId = modelParts.join("/")

    if (!provider || !modelId) {
      console.error(
        `Model shortcuts: ${shortcut} must target provider/model, got ${config.model}`,
      )
      continue
    }

    pi.registerShortcut(shortcut, {
      description: `Switch to ${describeTarget(config)}`,
      handler: async (ctx) => {
        const model = ctx.modelRegistry.find(provider, modelId)
        if (!model) {
          ctx.ui.notify(`Model not found: ${config.model}`, "error")
          return
        }

        if (await pi.setModel(model)) {
          if (config.thinkingLevel) pi.setThinkingLevel(config.thinkingLevel)
          ctx.ui.notify(`Model: ${describeTarget(config)}`, "info")
        } else {
          ctx.ui.notify(`No credentials for ${config.model}`, "error")
        }
      },
    })
  }
}
