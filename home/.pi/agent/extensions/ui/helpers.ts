import {
  type AgentToolResult,
  type Theme,
} from "@earendil-works/pi-coding-agent"
import { truncateToWidth, type Component } from "@earendil-works/pi-tui"

import { sanitizeTerminalText } from "./layout.js"

export class SingleLine implements Component {
  constructor(private text: string) {}

  setText(text: string): void {
    this.text = text
  }

  render(width: number): string[] {
    if (width <= 0) return []
    return [truncateToWidth(this.text, width, "…", true)]
  }

  invalidate(): void {}
}

export function compactText(value: unknown, fallback = "…"): string {
  if (typeof value !== "string") return fallback
  const compact = value.replace(/\s+/g, " ").trim()
  return sanitizeTerminalText(compact) || fallback
}

export function textOutput(result: AgentToolResult<unknown>): string {
  return result.content
    .flatMap((part) => (part.type === "text" ? [part.text] : []))
    .join("\n")
    .trimEnd()
}

export function lineCount(text: string): number {
  return text ? text.split("\n").length : 0
}

export function errorSummary(
  result: AgentToolResult<unknown>,
): string | undefined {
  const lines = textOutput(result)
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
  return lines.length > 0 ? compactText(lines.at(-1)) : undefined
}

export function expandedText(result: AgentToolResult<unknown>): string {
  return textOutput(result)
}

export function styleOutput(
  text: string,
  theme: Theme,
  isError: boolean,
): string {
  const color = isError ? "error" : "toolOutput"
  return text
    .split("\n")
    .map((line) => theme.fg(color, line))
    .join("\n")
}

export function renderDefaultCall(
  name: string,
  args: unknown,
  theme: Theme,
): string {
  const summary =
    args && typeof args === "object" && !Array.isArray(args)
      ? Object.entries(args as Record<string, unknown>)
          .map(([key, value]) => {
            const text =
              typeof value === "string"
                ? compactText(value, "")
                : typeof value === "object" && value !== null
                  ? compactText(JSON.stringify(value).replace(/\s+/g, " "), "")
                  : compactText(String(value), "")
            return text ? `${key}=${truncateToWidth(text, 40, "…", true)}` : ""
          })
          .filter(Boolean)
          .join(" ")
      : ""
  let text = theme.fg("toolTitle", theme.bold(name))
  if (summary)
    text += theme.fg("accent", ` ${truncateToWidth(summary, 80, "…", true)}`)
  return text
}
