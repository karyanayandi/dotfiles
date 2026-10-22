/**
 * Transcript rendering for the takeover view: turns a SubagentSnapshot's
 * normalized transcript + live state into plain wrapped lines. Ported from
 * v1, with the session-poking replaced by snapshot reads.
 */

import { getMarkdownTheme, type Theme } from "@earendil-works/pi-coding-agent"
import {
  Markdown,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui"
import { activityIndicator } from "@pi/shared/activity-status"
import type {
  SubagentSnapshot,
  TranscriptItem,
  TranscriptPart,
} from "#subagents/domain"

const ANSI_PATTERN =
  // eslint-disable-next-line no-control-regex
  /[\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[a-zA-Z\d]*)*)?\u0007)|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-nq-uy=><~]))/g

export interface SubagentTranscriptToolRenderRequest {
  readonly call: Extract<TranscriptPart, { type: "toolCall" }>
  readonly result?: Extract<TranscriptItem, { kind: "toolResult" }>
  readonly snapshot: SubagentSnapshot
  readonly width: number
  readonly theme: Theme
}

export type SubagentTranscriptToolRenderer = (
  request: SubagentTranscriptToolRenderRequest,
) => string[] | undefined

const transcriptToolRendererKey = Symbol.for(
  "pi-subagents.transcriptToolRenderer.v1",
)

type GlobalWithTranscriptToolRenderer = typeof globalThis & {
  [transcriptToolRendererKey]?: SubagentTranscriptToolRenderer
}

function renderTranscriptTool(request: SubagentTranscriptToolRenderRequest) {
  // SAFETY: The optional symbol property belongs to the transcript renderer hook.
  const renderer = (globalThis as GlobalWithTranscriptToolRenderer)[
    transcriptToolRendererKey
  ]

  if (!renderer) return undefined

  try {
    const lines = renderer(request)

    return lines?.map((line) => truncateToWidth(line, request.width))
  } catch {
    return undefined
  }
}

/**
 * Strip raw ANSI codes, expand tabs, and drop control chars. Terminal-expanded
 * tabs (and stray escapes) make lines wider than the width we declare to the
 * TUI, which desyncs the renderer and smears the overlay.
 */
export function sanitizeText(text: string): string {
  return (
    text
      .replace(ANSI_PATTERN, "")
      .replaceAll("\t", "  ")
      // oxlint-disable-next-line no-control-regex
      .replace(/[\u0000-\u0008\u000b-\u001f\u007f]/g, "")
  )
}

function renderUserText(
  theme: Theme,
  text: string,
  width: number,
  out: string[],
) {
  const clean = sanitizeText(text).trim()

  if (!clean) return
  const prefixWidth = 8
  const wrapped = wrapTextWithAnsi(clean, Math.max(1, width - prefixWidth))

  for (let i = 0; i < wrapped.length; i++) {
    const prefix =
      i === 0 ? theme.fg("dim", "  User: ") : " ".repeat(prefixWidth)

    out.push(truncateToWidth(prefix + theme.fg("dim", wrapped[i]), width))
  }
}

function visibleAssistantText(part: TranscriptPart): string | undefined {
  if (part.type === "text") return sanitizeText(part.text).trim() || undefined

  if (part.type === "thinking")
    return (
      sanitizeText(part.redacted ? "[redacted reasoning]" : part.text).trim() ||
      undefined
    )

  return undefined
}

function renderThinking(
  theme: Theme,
  text: string,
  width: number,
  out: string[],
) {
  const reasoning = sanitizeText(text).trim()

  if (!reasoning) return

  for (const line of new Markdown(reasoning, 1, 0, getMarkdownTheme()).render(
    width,
  )) {
    out.push(truncateToWidth(theme.fg("muted", theme.italic(line)), width))
  }
}

function renderAssistantItem(
  theme: Theme,
  item: Extract<TranscriptItem, { kind: "assistant" }>,
  width: number,
  out: string[],
  snapshot: SubagentSnapshot,
  results: ReadonlyMap<string, Extract<TranscriptItem, { kind: "toolResult" }>>,
  renderedResults: Set<string>,
) {
  if (item.parts.some((part) => visibleAssistantText(part) !== undefined))
    out.push("")

  for (let index = 0; index < item.parts.length; index++) {
    const part = item.parts[index]

    if (part.type === "text") {
      const text = visibleAssistantText(part)

      if (text)
        out.push(...new Markdown(text, 1, 0, getMarkdownTheme()).render(width))
    } else if (part.type === "thinking") {
      const thinking: string[] = []

      for (; index < item.parts.length; index++) {
        const thinkingPart = item.parts[index]

        if (thinkingPart.type !== "thinking") break

        const text = visibleAssistantText(thinkingPart)

        if (text) thinking.push(text)
      }

      index--

      if (thinking.length === 0) continue

      renderThinking(theme, thinking.join("\n\n"), width, out)

      if (
        item.parts
          .slice(index + 1)
          .some((next) => visibleAssistantText(next) !== undefined)
      )
        out.push("")
    } else if (part.type === "toolCall") {
      const result = results.get(part.toolId)

      const rendered = renderTranscriptTool({
        call: part,
        result,
        snapshot,
        width,
        theme,
      })

      if (rendered !== undefined) {
        out.push(...rendered)

        if (result) renderedResults.add(part.toolId)
        continue
      }

      const preview = part.argsPreview ? sanitizeText(part.argsPreview) : ""

      const marker = activityIndicator(
        theme,
        result ? (result.isError ? "error" : "done") : "running",
      )

      const line =
        `${marker} ${theme.fg("toolTitle", theme.bold(sanitizeText(part.name)))}` +
        (preview && preview !== "{}" ? theme.fg("accent", ` ${preview}`) : "")

      out.push(
        ...wrapTextWithAnsi(line, Math.max(1, width - 4)).map((row, index) =>
          truncateToWidth(`${index === 0 ? "  " : "    "}${row}`, width),
        ),
      )
    }
  }
}

function renderToolResultItem(
  theme: Theme,
  item: Extract<TranscriptItem, { kind: "toolResult" }>,
  width: number,
  out: string[],
) {
  const firstLine =
    sanitizeText(item.outputPreview ?? "")
      .split("\n")
      .find((line) => line.trim()) ?? ""

  const label = item.isError ? theme.fg("error", "  ✕ ") : "  "
  out.push(
    truncateToWidth(
      label +
        theme.fg(
          item.isError ? "error" : "toolOutput",
          firstLine || "(no output)",
        ),
      width,
    ),
  )
}

/** Render a subagent's conversation as plain lines, wrapped to `width`. */
export function buildTranscriptLines(
  snap: SubagentSnapshot,
  width: number,
  theme: Theme,
): string[] {
  if (width <= 0) return []
  const out: string[] = []

  const results = new Map<
    string,
    Extract<TranscriptItem, { kind: "toolResult" }>
  >()

  for (const item of snap.transcript) {
    if (item.kind === "toolResult") results.set(item.toolId, item)
  }

  const renderedResults = new Set<string>()

  for (const item of snap.transcript) {
    if (item.kind === "user") {
      renderUserText(theme, item.text, width, out)
    } else if (item.kind === "assistant") {
      renderAssistantItem(
        theme,
        item,
        width,
        out,
        snap,
        results,
        renderedResults,
      )
    } else if (!renderedResults.has(item.toolId)) {
      renderToolResultItem(theme, item, width, out)
    }
  }

  // Live streaming assistant buffers (cleared when the finalized message lands).
  if (snap.liveAssistant) {
    const thinking = sanitizeText(snap.liveAssistant.thinking).trim()
    const text = sanitizeText(snap.liveAssistant.text).trim()

    if (thinking || text) out.push("")

    if (thinking) renderThinking(theme, thinking, width, out)

    if (thinking && text) out.push("")

    if (text)
      out.push(...new Markdown(text, 1, 0, getMarkdownTheme()).render(width))
  }

  // Live tool executions (present until the ToolEnd lands in the transcript).
  for (const tool of snap.liveTools) {
    const marker = activityIndicator(
      theme,
      tool.done ? (tool.isError ? "error" : "done") : "running",
    )

    let line = `  ${marker} ${theme.fg("toolTitle", theme.bold(sanitizeText(tool.name)))}`
    const preview = tool.outputPreview && sanitizeText(tool.outputPreview)

    if (preview) line += theme.fg("dim", ` · ${preview}`)
    out.push(truncateToWidth(line, width))
  }

  // Queued steering/follow-up messages: show them immediately so Enter
  // visibly acknowledges the user's input instead of appearing to do nothing.
  for (const message of snap.queued) {
    if (out.length > 0) out.push("")

    const prefix = theme.fg(
      "warning",
      `  ${activityIndicator(theme, "queued")} [queued ${message.kind}] `,
    )

    const wrapped = wrapTextWithAnsi(
      sanitizeText(message.text),
      Math.max(1, width - visibleWidth(prefix)),
    )

    for (let i = 0; i < wrapped.length; i++) {
      out.push(
        truncateToWidth(
          (i === 0 ? prefix : " ".repeat(visibleWidth(prefix))) +
            theme.fg("muted", wrapped[i]),
          width,
        ),
      )
    }
  }

  return out.map((line) => truncateToWidth(line, width))
}
