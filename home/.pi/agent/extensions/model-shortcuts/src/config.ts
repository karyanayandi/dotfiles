import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { getAgentDir } from "@earendil-works/pi-coding-agent"

const configPath = join(getAgentDir(), "model-shortcuts.json")

export function loadShortcuts() {
  if (!existsSync(configPath)) return {}

  try {
    const value: unknown = JSON.parse(readFileSync(configPath, "utf8"))
    if (
      typeof value !== "object" ||
      value === null ||
      Array.isArray(value) ||
      !Object.values(value).every((model) => typeof model === "string")
    ) {
      throw new Error("expected an object of shortcut: provider/model pairs")
    }
    return value as Record<string, string>
  } catch (error) {
    console.error(`Model shortcuts: could not load ${configPath}: ${error}`)
    return {}
  }
}

export function saveShortcuts(shortcuts: Record<string, string>) {
  writeFileSync(configPath, `${JSON.stringify(shortcuts, null, 2)}\n`)
}
