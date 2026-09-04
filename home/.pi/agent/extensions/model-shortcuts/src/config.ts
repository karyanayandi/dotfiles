import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { getAgentDir } from "@earendil-works/pi-coding-agent"

const configPath = join(getAgentDir(), "model-shortcuts.json")

export const thinkingLevels = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
] as const

export type ThinkingLevel = (typeof thinkingLevels)[number]

export function nextThinkingLevel(
  levels: readonly ThinkingLevel[],
  current: ThinkingLevel,
  direction: -1 | 1,
) {
  if (levels.length === 0) return current

  const index = levels.indexOf(current)
  const start = index === -1 ? (direction === 1 ? -1 : 0) : index
  return levels[(start + direction + levels.length) % levels.length]
}

export interface ShortcutConfig {
  model: string
  thinkingLevel?: ThinkingLevel
}

export function parseShortcuts(value: unknown) {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("expected an object of shortcut configurations")
  }

  return Object.fromEntries(
    Object.entries(value).map(([shortcut, config]) => {
      if (typeof config === "string") return [shortcut, { model: config }]
      if (
        typeof config !== "object" ||
        config === null ||
        Array.isArray(config) ||
        !("model" in config) ||
        typeof config.model !== "string"
      ) {
        throw new Error(`invalid configuration for ${shortcut}`)
      }

      const thinkingLevel =
        "thinkingLevel" in config
          ? thinkingLevels.find((level) => level === config.thinkingLevel)
          : undefined
      if ("thinkingLevel" in config && !thinkingLevel) {
        throw new Error(`invalid configuration for ${shortcut}`)
      }
      return [
        shortcut,
        { model: config.model, ...(thinkingLevel ? { thinkingLevel } : {}) },
      ]
    }),
  )
}

export function loadShortcuts() {
  if (!existsSync(configPath)) return {}

  try {
    return parseShortcuts(JSON.parse(readFileSync(configPath, "utf8")))
  } catch (error) {
    console.error(`Model shortcuts: could not load ${configPath}: ${error}`)
    return {}
  }
}

export function saveShortcuts(shortcuts: Record<string, ShortcutConfig>) {
  writeFileSync(configPath, `${JSON.stringify(shortcuts, null, 2)}\n`)
}
