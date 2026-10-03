import * as v from "valibot"
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

const shortcutsSchema = v.record(
  v.string(),
  v.union([
    v.pipe(
      v.string(),
      v.transform((model): ShortcutConfig => ({ model })),
    ),
    v.object({
      model: v.string(),
      thinkingLevel: v.exactOptional(v.picklist(thinkingLevels)),
    }),
  ]),
)

export function parseShortcuts<Value>(value: Value) {
  return v.parse(shortcutsSchema, value)
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
