import type { AgentToolResult, Theme } from "@earendil-works/pi-coding-agent"
import { Container, Text, truncateToWidth } from "@earendil-works/pi-tui"
import { sanitizeTerminalText } from "ui/layout.ts"

class SubagentToolText extends Text {
  override render(width: number) {
    if (width <= 0) return []

    return super.render(width).map((line) => truncateToWidth(line, width))
  }
}

export function subagentToolRenderers(name: string) {
  return {
    renderShell: "self" as const,
    renderCall(
      args: { name?: string; id?: string; ids?: string[]; harness?: string },
      theme: Theme,
    ) {
      const subject = args.name ?? args.id ?? args.ids?.join(", ") ?? ""

      const text =
        theme.fg("toolTitle", theme.bold(name)) +
        (subject
          ? ` ${theme.fg("accent", sanitizeTerminalText(subject))}`
          : "") +
        (args.harness
          ? theme.fg("muted", ` ${sanitizeTerminalText(args.harness)}`)
          : "")

      return new SubagentToolText(text, 0, 0)
    },
    renderResult(
      result: AgentToolResult<unknown>,
      { expanded }: { expanded: boolean },
      theme: Theme,
      { isError }: { isError: boolean },
    ) {
      const output = result.content
        .flatMap((part) => (part.type === "text" ? [part.text] : []))
        .join("\n")

      if (!output) return new Container()
      const lines = output.split("\n")
      const visible = expanded ? lines : lines.slice(0, 1)

      return new SubagentToolText(
        visible
          .map((line) =>
            theme.fg(
              isError ? "error" : expanded ? "toolOutput" : "muted",
              sanitizeTerminalText(line),
            ),
          )
          .join("\n"),
        0,
        0,
      )
    },
  }
}
