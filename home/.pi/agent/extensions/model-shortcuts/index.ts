import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { loadShortcuts, saveShortcuts } from "./src/config.ts"
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

export default function modelShortcuts(pi: ExtensionAPI) {
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
            description: target,
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
            description: target,
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
      const target = await pick(ctx, "Select model", models)
      if (!target) return

      shortcuts[shortcut] = target
      saveShortcuts(shortcuts)
      ctx.ui.notify(
        `Saved ${shortcut} → ${target}; reloading shortcuts`,
        "info",
      )
      await ctx.reload()
    },
  })

  for (const [shortcut, target] of Object.entries(loadShortcuts())) {
    if (!isModelShortcut(shortcut)) {
      console.error(
        `Model shortcuts: only ctrl+0 through ctrl+9 are supported; got ${shortcut}`,
      )
      continue
    }

    const [provider, ...modelParts] = target.split("/")
    const modelId = modelParts.join("/")

    if (!provider || !modelId) {
      console.error(
        `Model shortcuts: ${shortcut} must target provider/model, got ${target}`,
      )
      continue
    }

    pi.registerShortcut(shortcut, {
      description: `Switch to ${target}`,
      handler: async (ctx) => {
        const model = ctx.modelRegistry.find(provider, modelId)
        if (!model) {
          ctx.ui.notify(`Model not found: ${target}`, "error")
          return
        }

        if (await pi.setModel(model)) {
          ctx.ui.notify(`Model: ${target}`, "info")
        } else {
          ctx.ui.notify(`No credentials for ${target}`, "error")
        }
      },
    })
  }
}
