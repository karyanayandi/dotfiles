import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import type { AutocompleteItem } from "@earendil-works/pi-tui"

const dollarSkillPattern = /^(\s*)\$([a-z0-9-]+)(?:\s+(.*))?$/

function skills(pi: ExtensionAPI) {
  return pi
    .getCommands()
    .filter((command) => command.source === "skill")
    .map((command) => command.name.slice("skill:".length))
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

    const text = expandDollarSkill(event.text, skills(pi))
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
        const items: AutocompleteItem[] = skills(pi)
          .filter((name) => name.startsWith(match[1]))
          .map((name) => ({
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
