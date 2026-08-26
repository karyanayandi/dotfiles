import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { loadShortcuts, saveShortcuts } from "./src/config.ts"
import { pick } from "./src/picker.ts"
import { isShortcut } from "./src/shortcut.ts"

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

      const defaults = Array.from(
        { length: 9 },
        (_, index) => `ctrl+${index + 1}`,
      )
      const items = [
        ...Object.entries(shortcuts)
          .sort(([left], [right]) => left.localeCompare(right))
          .map(([shortcut, target]) => ({
            value: shortcut,
            label: shortcut,
            description: target,
          })),
        ...defaults
          .filter((shortcut) => !(shortcut in shortcuts))
          .map((shortcut) => ({
            value: shortcut,
            label: shortcut,
            description: "unassigned",
          })),
        {
          value: "custom",
          label: "Custom shortcut…",
          description: "Type any Pi shortcut",
        },
      ]
      const selected = await pick(ctx, "Select shortcut", items)
      if (!selected) return
      const shortcut =
        selected === "custom"
          ? await ctx.ui.input("Shortcut", "ctrl+4")
          : selected
      if (!shortcut?.trim()) return
      if (!isShortcut(shortcut.trim())) {
        ctx.ui.notify(`Invalid Pi shortcut: ${shortcut.trim()}`, "error")
        return
      }

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

      shortcuts[shortcut.trim()] = target
      saveShortcuts(shortcuts)
      ctx.ui.notify(
        `Saved ${shortcut.trim()} → ${target}; reloading shortcuts`,
        "info",
      )
      await ctx.reload()
    },
  })

  for (const [shortcut, target] of Object.entries(loadShortcuts())) {
    if (!isShortcut(shortcut)) {
      console.error(`Model shortcuts: invalid shortcut ${shortcut}`)
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
