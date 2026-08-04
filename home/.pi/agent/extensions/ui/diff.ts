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

// Tinted diff row backgrounds, ported from pi-tool-display.
interface Rgb {
  r: number
  g: number
  b: number
}

const ADDITION_TINT_TARGET: Rgb = { r: 84, g: 190, b: 118 }
const DELETION_TINT_TARGET: Rgb = { r: 232, g: 95, b: 122 }
const ROW_BACKGROUND_MIX_RATIO = 0.12
const ANSI_BG_RESET = "\x1b[49m"

const BASE16: Rgb[] = [
  { r: 0, g: 0, b: 0 },
  { r: 128, g: 0, b: 0 },
  { r: 0, g: 128, b: 0 },
  { r: 128, g: 128, b: 0 },
  { r: 0, g: 0, b: 128 },
  { r: 128, g: 0, b: 128 },
  { r: 0, g: 128, b: 128 },
  { r: 192, g: 192, b: 192 },
  { r: 128, g: 128, b: 128 },
  { r: 255, g: 0, b: 0 },
  { r: 0, g: 255, b: 0 },
  { r: 255, g: 255, b: 0 },
  { r: 0, g: 0, b: 255 },
  { r: 255, g: 0, b: 255 },
  { r: 0, g: 255, b: 255 },
  { r: 255, g: 255, b: 255 },
]

function ansi256ToRgb(code: number): Rgb {
  if (code <= 15) return BASE16[code] ?? { r: 0, g: 0, b: 0 }
  if (code <= 231) {
    const value = code - 16
    const steps = [0, 95, 135, 175, 215, 255]
    return {
      r: steps[Math.floor(value / 36)] ?? 0,
      g: steps[Math.floor((value % 36) / 6)] ?? 0,
      b: steps[value % 6] ?? 0,
    }
  }
  const gray = 8 + (code - 232) * 10
  return { r: gray, g: gray, b: gray }
}

function parseAnsiColorCode(ansi: string | undefined): Rgb | null {
  if (!ansi) return null
  const trueColor = /^\x1b\[(?:38|48);2;(\d{1,3});(\d{1,3});(\d{1,3})m$/.exec(
    ansi,
  )
  if (trueColor)
    return { r: +trueColor[1]!, g: +trueColor[2]!, b: +trueColor[3]! }
  const bit = /^\x1b\[(?:38|48);5;(\d{1,3})m$/.exec(ansi)
  if (bit) return ansi256ToRgb(+bit[1]!)
  return null
}

function mixRgb(base: Rgb, tint: Rgb, ratio: number): Rgb {
  const clamped = Math.max(0, Math.min(1, ratio))
  return {
    r: base.r * (1 - clamped) + tint.r * clamped,
    g: base.g * (1 - clamped) + tint.g * clamped,
    b: base.b * (1 - clamped) + tint.b * clamped,
  }
}

function rgbToBgAnsi(color: Rgb): string {
  const round = (value: number) =>
    Math.max(0, Math.min(255, Math.round(value)))
  return `\x1b[48;2;${round(color.r)};${round(color.g)};${round(color.b)}m`
}

interface DiffPalette {
  addRowBg?: string
  removeRowBg?: string
}

function resolvePalette(theme: Theme): DiffPalette {
  if (typeof theme.getBgAnsi !== "function") return {}
  let baseBg: Rgb | null = null
  for (const slot of ["toolSuccessBg", "toolPendingBg", "userMessageBg"] as const) {
    try {
      baseBg = parseAnsiColorCode(theme.getBgAnsi(slot))
    } catch {
      baseBg = null
    }
    if (baseBg) break
  }
  if (!baseBg) return {}
  // Fixed green/red targets, mixed toward the container background so text
  // stays readable on light and dark themes alike.
  return {
    addRowBg: rgbToBgAnsi(
      mixRgb(baseBg, ADDITION_TINT_TARGET, ROW_BACKGROUND_MIX_RATIO),
    ),
    removeRowBg: rgbToBgAnsi(
      mixRgb(baseBg, DELETION_TINT_TARGET, ROW_BACKGROUND_MIX_RATIO),
    ),
  }
}

export function renderDiffText(
  entries: DiffLine[],
  theme: Theme,
  expanded: boolean,
): string {
  if (entries.length === 0) return ""
  const palette = resolvePalette(theme)
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
    const { kind } = entry
    const num =
      kind === "add"
        ? entry.newNum
        : kind === "remove"
          ? entry.oldNum
          : (entry.newNum ?? entry.oldNum)
    const numText =
      num !== null ? String(num).padStart(numWidth, " ") : " ".repeat(numWidth)
    const numColor =
      kind === "add"
        ? "toolDiffAdded"
        : kind === "remove"
          ? "toolDiffRemoved"
          : "dim"
    // OpenCode-style: ▌ bar indicator, colored line number, │ divider.
    const marker =
      kind === "context" ? " " : theme.fg(numColor, "▌")
    const prefix = `${marker} ${theme.fg(numColor, numText)} ${theme.fg("dim", "│ ")}`
    let line = prefix + sanitizeTerminalText(entry.content)
    const rowBg =
      kind === "add"
        ? palette.addRowBg
        : kind === "remove"
          ? palette.removeRowBg
          : undefined
    // theme.fg only resets the foreground (\x1b[39m), so the row background
    // survives every colored segment; close it at the end of the line.
    if (rowBg) line = `${rowBg}${line}${ANSI_BG_RESET}`
    return line
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
