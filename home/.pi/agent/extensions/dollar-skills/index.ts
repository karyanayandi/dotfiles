import { spawnSync } from "node:child_process"
import type {
  ExtensionAPI,
  SlashCommandInfo,
} from "@earendil-works/pi-coding-agent"
import type { AutocompleteItem } from "@earendil-works/pi-tui"

const dollarSkillPattern = /^(\s*)\$([a-z0-9-]+)(?:\s+(.*))?$/

function skills(pi: ExtensionAPI) {
  return pi.getCommands().filter((command) => command.source === "skill")
}

export function searchSkills(
  query: string,
  commands: readonly Pick<SlashCommandInfo, "name" | "description">[],
) {
  const names = commands.map((command) => command.name.slice("skill:".length))
  if (!query) return names

  const input = commands
    .map(
      (command) =>
        `${command.name} ${command.description?.replace(/\s+/g, " ") ?? ""}`,
    )
    .join("\n")
  const result = spawnSync("rg", ["-n", "-i", "-F", "--", query], {
    input,
    encoding: "utf8",
  })
  if (result.error) throw result.error
  if (result.status !== 0 && result.status !== 1) {
    throw new Error(result.stderr || "Skill search failed")
  }
  return result.stdout
    .split("\n")
    .filter(Boolean)
    .map((line) => names[Number(line.slice(0, line.indexOf(":"))) - 1])
}

export function expandDollarSkill(text: string, skillNames: string[]) {
  const match = text.match(dollarSkillPattern)
  if (!match || !skillNames.includes(match[2])) return

  const [, indent, skill, args] = match
  return `${indent}/skill:${skill}${args ? ` ${args}` : ""}`
}

export default function dollarSkills(pi: ExtensionAPI) {
  pi.on("input", (event) => {
    if (event.source === "extension") return { action: "continue" as const }

    const text = expandDollarSkill(
      event.text,
      skills(pi).map((command) => command.name.slice("skill:".length)),
    )
    return text
      ? { action: "transform" as const, text }
      : { action: "continue" as const }
  })

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.addAutocompleteProvider((current) => ({
      triggerCharacters: ["$"],
      async getSuggestions(lines, line, col, options) {
        const beforeCursor = (lines[line] ?? "").slice(0, col)
        const match = beforeCursor.match(/(?:^|[ \t])\$([a-z0-9-]*)$/)
        if (!match) return current.getSuggestions(lines, line, col, options)

        const prefix = `$${match[1]}`
        const items: AutocompleteItem[] = searchSkills(
          match[1],
          skills(pi),
        ).map((name) => ({
          value: `$${name}`,
          label: `$${name}`,
          description: "Skill",
        }))
        return items.length > 0 ? { prefix, items } : null
      },
      applyCompletion: current.applyCompletion,
      shouldTriggerFileCompletion: current.shouldTriggerFileCompletion,
    }))
  })
}
