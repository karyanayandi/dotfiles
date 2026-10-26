import {
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui"

// SAFETY: Remove C0/C1 controls and bidi overrides from untrusted model IDs and git branches before terminal rendering.
const unsafeTerminalCharacters =
  // oxlint-disable-next-line eslint/no-control-regex
  /[\u0000-\u001f\u007f-\u009f\u202a-\u202e\u2066-\u2069]/g

export function sanitizeTerminalText(text: string): string {
  return text.replace(unsafeTerminalCharacters, "")
}

export function addSideBorders(
  line: string,
  width: number,
  border: (text: string) => string,
): string {
  if (width <= 0) return ""

  if (width === 1) return border("│")

  const start = line.charCodeAt(0) === 32 ? 1 : 0
  let end = line.length

  if (end > start && line.charCodeAt(end - 1) === 32) end--

  const innerWidth = width - 2
  let inner = line.slice(start, end)

  if (visibleWidth(inner) > innerWidth)
    inner = truncateToWidth(inner, innerWidth, "…")
  inner += " ".repeat(Math.max(0, innerWidth - visibleWidth(inner)))

  return border("│") + inner + border("│")
}

export function addBorderLabels(
  width: number,
  leftLabel: string,
  rightLabel: string,
  border: (text: string) => string,
): string {
  if (width <= 0) return ""

  if (width === 1) return border("┌")

  const innerWidth = width - 2
  let right = rightLabel && width >= 8 ? ` ${rightLabel} ` : ""

  if (visibleWidth(right) > innerWidth)
    right = truncateToWidth(right, innerWidth, "…")

  const leftWidth = innerWidth - visibleWidth(right)
  let left = leftLabel && width >= 8 ? ` ${leftLabel} ` : ""

  if (visibleWidth(left) > leftWidth)
    left = truncateToWidth(left, leftWidth, "…")

  const fillWidth = innerWidth - visibleWidth(left) - visibleWidth(right)

  return (
    border("┌") + left + border("─".repeat(fillWidth)) + right + border("┐")
  )
}

export function renderExtensionStatuses(
  statuses: ReadonlyMap<string, string>,
  width: number,
  dim?: (text: string) => string,
) {
  if (width <= 0) return []

  const entries = [...statuses.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(
      ([key, text]) =>
        [
          key,
          text
            .replace(/[\r\n\t]/g, " ")
            .replace(/ +/g, " ")
            .replace(/ to view/g, " ↗")
            .replace(/[·•↗]/g, (symbol) => dim?.(symbol) ?? symbol)
            .trim(),
        ] as const,
    )
    .filter(([, text]) => Boolean(text))

  const full = entries.map(([, text]) => text).join("  ")

  if (!full) return []

  if (visibleWidth(full) <= width) return [full]

  const sections = entries.map(([key, text]) => {
    if (key === "background-terminals") {
      text = text.includes("background terminal:")
        ? text.replace("background terminal:", ">_ ")
        : `>_  ${text.replace(/ background terminals? running/g, "")}`
    } else if (key === "subagents") {
      text = text.replace("subagents:", "⌘ ")
    } else if (key === "workflows") {
      text = text.replace("workflows:", "⑂ ")
    } else {
      return text
    }

    return text.replace(/ (?:running|done|failed)\b/g, "")
  })

  const lines: string[] = []
  let row = ""

  for (const entry of sections) {
    const next = row ? `${row}  ${entry}` : entry

    if (visibleWidth(next) <= width) {
      row = next
      continue
    }

    if (row) lines.push(row)
    const wrapped = wrapTextWithAnsi(entry, width)
    row = wrapped.pop() ?? ""
    lines.push(...wrapped)
  }

  if (row) lines.push(row)

  return lines
}

export function addBottomLabel(
  width: number,
  label: string,
  border: (text: string) => string,
): string {
  if (width <= 0) return ""

  if (width === 1) return border("└")

  const innerWidth = width - 2
  let right = label && width >= 8 ? ` ${label} ` : ""

  if (visibleWidth(right) > innerWidth)
    right = truncateToWidth(right, innerWidth, "…")
  const fillWidth = innerWidth - visibleWidth(right)

  return border("└") + border("─".repeat(fillWidth)) + right + border("┘")
}
