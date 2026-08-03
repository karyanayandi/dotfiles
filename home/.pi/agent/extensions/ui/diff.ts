import type { Theme } from "@earendil-works/pi-coding-agent"

import { sanitizeTerminalText } from "./layout.js"

export interface DiffLine {
  kind: "add" | "remove" | "context" | "meta"
  oldNum: number | null
  newNum: number | null
  content: string
}

const CANONICAL_LINE_PATTERN = /^([+\- ])(\s*\d+)\|(.*)$/
const LEGACY_LINE_PATTERN = /^([+\- ])(\s*\d+)\s(.*)$/

export function parseDiff(diff: string): DiffLine[] {
  const entries: DiffLine[] = []
  for (const raw of diff.replace(/\r/g, "").split("\n")) {
    const match =
      raw.match(CANONICAL_LINE_PATTERN) ?? raw.match(LEGACY_LINE_PATTERN)
    if (match) {
      const prefix = match[1]
      const num = Number.parseInt(match[2] ?? "", 10)
      const kind =
        prefix === "+" ? "add" : prefix === "-" ? "remove" : "context"
      entries.push({
        kind,
        oldNum: kind === "add" ? null : num,
        newNum: kind === "remove" ? null : num,
        content: match[3] ?? "",
      })
      continue
    }
    entries.push({ kind: "meta", oldNum: null, newNum: null, content: raw })
  }
  return entries
}

interface DiffOperation {
  kind: "add" | "remove" | "context"
  content: string
}

// LCS line diff, ported from pi-tool-display's buildWriteDiffOperations.
export function diffLines(oldLines: string[], newLines: string[]): DiffLine[] {
  const oldLength = oldLines.length
  const newLength = newLines.length
  const table: number[][] = Array.from({ length: oldLength + 1 }, () =>
    Array<number>(newLength + 1).fill(0),
  )
  for (let oldIndex = 1; oldIndex <= oldLength; oldIndex++) {
    for (let newIndex = 1; newIndex <= newLength; newIndex++) {
      if ((oldLines[oldIndex - 1] ?? "") === (newLines[newIndex - 1] ?? "")) {
        table[oldIndex]![newIndex] = table[oldIndex - 1]![newIndex - 1]! + 1
        continue
      }
      table[oldIndex]![newIndex] = Math.max(
        table[oldIndex - 1]![newIndex]!,
        table[oldIndex]![newIndex - 1]!,
      )
    }
  }

  const operations: DiffOperation[] = []
  let oldCursor = oldLength
  let newCursor = newLength
  while (oldCursor > 0 || newCursor > 0) {
    const oldLine = oldCursor > 0 ? oldLines[oldCursor - 1] : undefined
    const newLine = newCursor > 0 ? newLines[newCursor - 1] : undefined
    if (oldCursor > 0 && newCursor > 0 && oldLine === newLine) {
      operations.push({ kind: "context", content: oldLine ?? "" })
      oldCursor--
      newCursor--
      continue
    }
    const top = oldCursor > 0 ? table[oldCursor - 1]![newCursor]! : -1
    const left = newCursor > 0 ? table[oldCursor]![newCursor - 1]! : -1
    if (newCursor > 0 && left >= top) {
      operations.push({ kind: "add", content: newLine ?? "" })
      newCursor--
      continue
    }
    if (oldCursor > 0) {
      operations.push({ kind: "remove", content: oldLine ?? "" })
      oldCursor--
    }
  }
  operations.reverse()

  let oldNum = 1
  let newNum = 1
  return operations.map((op) => {
    if (op.kind === "add") {
      const line: DiffLine = {
        kind: "add",
        oldNum: null,
        newNum: newNum++,
        content: op.content,
      }
      return line
    }
    if (op.kind === "remove") {
      const line: DiffLine = {
        kind: "remove",
        oldNum: oldNum++,
        newNum: null,
        content: op.content,
      }
      return line
    }
    const line: DiffLine = {
      kind: "context",
      oldNum: oldNum++,
      newNum: newNum++,
      content: op.content,
    }
    return line
  })
}

const DIFF_COLLAPSED_LINES = 24
const EXPAND_HINT = " • Ctrl+O to expand"

function colorFor(
  kind: DiffLine["kind"],
): "toolDiffAdded" | "toolDiffRemoved" | "dim" {
  if (kind === "add") return "toolDiffAdded"
  if (kind === "remove") return "toolDiffRemoved"
  return "dim"
}

export function renderDiffText(
  entries: DiffLine[],
  theme: Theme,
  expanded: boolean,
): string {
  if (entries.length === 0) return ""
  const maxNum = Math.max(
    0,
    ...entries.map((entry) => Math.max(entry.oldNum ?? 0, entry.newNum ?? 0)),
  )
  const numWidth = String(maxNum).length

  const render = (entry: DiffLine): string => {
    if (entry.kind === "meta") {
      if (entry.content.startsWith("@@"))
        return theme.fg("muted", sanitizeTerminalText(entry.content))
      return ""
    }
    const marker =
      entry.kind === "add" ? "+" : entry.kind === "remove" ? "-" : " "
    const num =
      entry.kind === "add"
        ? entry.newNum
        : entry.kind === "remove"
          ? entry.oldNum
          : (entry.newNum ?? entry.oldNum)
    const numText =
      num !== null ? String(num).padStart(numWidth, " ") : " ".repeat(numWidth)
    const color = colorFor(entry.kind)
    const content =
      entry.kind === "context"
        ? sanitizeTerminalText(entry.content)
        : theme.fg(color, sanitizeTerminalText(entry.content))
    return (
      theme.fg(color, marker) +
      theme.fg(color, numText) +
      theme.fg("dim", " │ ") +
      content
    )
  }

  const lines = entries.map(render).filter((line) => line !== "")
  if (!expanded && lines.length > DIFF_COLLAPSED_LINES) {
    lines.length = DIFF_COLLAPSED_LINES
    lines.push(
      theme.fg(
        "muted",
        `... (${entries.length - DIFF_COLLAPSED_LINES} more lines${EXPAND_HINT})`,
      ),
    )
  }
  return lines.join("\n")
}

function splitContent(content: string): string[] {
  const lines = content.replace(/\r/g, "").split("\n")
  if (lines.length > 1 && lines.at(-1) === "") lines.pop()
  return lines
}

export function renderWriteDiffText(
  content: string,
  previousContent: string | undefined,
  fileExisted: boolean,
  theme: Theme,
  expanded: boolean,
): string {
  const newLines = splitContent(content)
  const entries =
    fileExisted && previousContent !== undefined
      ? diffLines(splitContent(previousContent), newLines)
      : newLines.map<DiffLine>((line, index) => ({
          kind: "add",
          oldNum: null,
          newNum: index + 1,
          content: line,
        }))
  return renderDiffText(entries, theme, expanded)
}
