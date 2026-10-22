/**
 * Takeover UI for subagents (ported from v1, rendering from the synchronous
 * SubagentReadModel instead of live pi sessions):
 * - SubagentDashboard: full popup (overlay) listing all subagents.
 * - TakeoverView: full interactive view of one subagent with an input line
 *   to steer/continue it.
 */

import type {
  ExtensionCommandContext,
  KeybindingsManager,
  Theme,
} from "@earendil-works/pi-coding-agent"
import type { Component, Focusable, TUI } from "@earendil-works/pi-tui"
import { Input, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui"
import {
  ACTIVITY_FRAME_MS,
  activityIndicator,
  inputActivityIndicator,
} from "@pi/shared/activity-status"
import { formatElapsed, type SubagentSnapshot } from "#subagents/domain"
import type { SubagentReadModel } from "#subagents/manager"
import { buildTranscriptLines } from "./transcript.ts"
import { sanitizeTerminalText } from "ui/layout.ts"

function configuredKeys(
  keybindings: Pick<KeybindingsManager, "getKeys" | "matches">,
  binding: Parameters<KeybindingsManager["getKeys"]>[0],
) {
  return keybindings.getKeys(binding).join("/") || "unbound"
}

function statusGlyph(snap: SubagentSnapshot, theme: Theme): string {
  return activityIndicator(theme, snap.status)
}

function statusWord(snap: SubagentSnapshot, theme: Theme): string {
  switch (snap.status) {
    case "running":
      return theme.fg("warning", "running")
    case "done":
      return theme.fg("success", "done")
    case "error":
      return theme.fg("error", "failed")
  }
}

// --- Entry points --------------------------------------------------------------

export interface TakeoverOptions {
  readonly badge?: string
}

export async function openSubagentTakeover(
  ctx: ExtensionCommandContext,
  view: SubagentReadModel,
  id: string,
  options?: TakeoverOptions,
) {
  if (!view.get(id)) return
  await ctx.ui.custom<null>(
    (tui, theme, keybindings, done) =>
      new TakeoverView(tui, theme, keybindings, id, view, done, options),
    {
      overlay: true,
      overlayOptions: { anchor: "center", width: "100%", maxHeight: "100%" },
    },
  )
}

export async function openSubagentPicker(
  ctx: ExtensionCommandContext,
  view: SubagentReadModel,
) {
  const selection: DashboardSelection = { index: 0 }

  while (true) {
    if (view.size() === 0) {
      ctx.ui.notify("No subagents", "info")

      return
    }

    const picked = await ctx.ui.custom<string | null>(
      (tui, theme, keybindings, done) =>
        new SubagentDashboard(tui, theme, keybindings, view, selection, done),
      {
        overlay: true,
        overlayOptions: { anchor: "center", width: "100%", maxHeight: "100%" },
      },
    )

    if (!picked) return

    if (!view.get(picked)) continue

    await openSubagentTakeover(ctx, view, picked)
    // After leaving the takeover view, fall back to the dashboard.
  }
}

// --- Dashboard (fullscreen overlay) ----------------------------------------------

export interface DashboardSelection {
  id?: string
  index: number
}

export function reconcileDashboardSelection(
  selection: DashboardSelection,
  subs: readonly Pick<SubagentSnapshot, "id">[],
) {
  const stableIndex = selection.id
    ? subs.findIndex((snap) => snap.id === selection.id)
    : -1

  selection.index =
    stableIndex >= 0
      ? stableIndex
      : Math.min(Math.max(0, selection.index), Math.max(0, subs.length - 1))
  selection.id = subs[selection.index]?.id
}

export class SubagentDashboard implements Component {
  private tui: TUI
  private theme: Theme
  private keybindings: Pick<KeybindingsManager, "getKeys" | "matches">
  private view: SubagentReadModel
  private selection: DashboardSelection
  private done: (value: string | null) => void

  private closed = false
  private ticker: ReturnType<typeof setInterval>
  private unsubChange: () => void

  constructor(
    tui: TUI,
    theme: Theme,
    keybindings: Pick<KeybindingsManager, "getKeys" | "matches">,
    view: SubagentReadModel,
    selection: DashboardSelection,
    done: (value: string | null) => void,
  ) {
    this.tui = tui
    this.theme = theme
    this.keybindings = keybindings
    this.view = view
    this.selection = selection
    this.done = done
    this.ticker = setInterval(() => {
      if (this.view.list().some((snap) => snap.status === "running"))
        this.tui.requestRender()
    }, ACTIVITY_FRAME_MS)
    this.unsubChange = view.subscribe(() => this.tui.requestRender())
  }

  private subs(): readonly SubagentSnapshot[] {
    return this.view.list()
  }

  private cleanup() {
    if (this.closed) return false
    this.closed = true
    clearInterval(this.ticker)
    this.unsubChange()

    return true
  }

  private close(result: string | null) {
    if (this.cleanup()) this.done(result)
  }

  dispose(): void {
    this.cleanup()
  }

  handleInput(data: string): void {
    const subs = this.subs()
    reconcileDashboardSelection(this.selection, subs)

    if (this.keybindings.matches(data, "tui.select.cancel")) {
      this.close(null)

      return
    }

    if (this.keybindings.matches(data, "tui.select.confirm")) {
      const snap = subs[this.selection.index]

      if (snap) this.close(snap.id)

      return
    }

    if (this.keybindings.matches(data, "tui.select.up") || data === "k") {
      if (subs.length > 0) {
        this.selection.index =
          (this.selection.index - 1 + subs.length) % subs.length
        this.selection.id = subs[this.selection.index]?.id
        this.tui.requestRender()
      }

      return
    }

    if (this.keybindings.matches(data, "tui.select.down") || data === "j") {
      if (subs.length > 0) {
        this.selection.index = (this.selection.index + 1) % subs.length
        this.selection.id = subs[this.selection.index]?.id
        this.tui.requestRender()
      }

      return
    }

    if (data === "x") {
      const snap = subs[this.selection.index]

      if (snap?.status === "running") this.view.requestAbort(snap.id)

      return
    }
  }

  render(width: number): string[] {
    const theme = this.theme
    const subs = this.subs()
    reconcileDashboardSelection(this.selection, subs)

    const rows = this.tui.terminal.rows || 30
    // Render exactly terminal rows - 1 so the overlay covers the header,
    // chat, editor, and extra footer lines while leaving pi's final footer
    // row visible.
    const bodyHeight = Math.max(0, rows - 5)

    if (width <= 0) return []
    const running = subs.filter((snap) => snap.status === "running").length

    const lines = [
      truncateToWidth(
        `  ${theme.fg("accent", theme.bold("Subagents"))}${theme.fg("muted", ` · ${running}/${subs.length} running`)}`,
        width,
      ),
      "",
    ]

    const rowLines = this.renderRows(subs, width, bodyHeight)

    for (let i = 0; i < bodyHeight; i++) {
      lines.push(rowLines[i] ?? "")
    }

    lines.push("")

    // Hints
    lines.push(
      truncateToWidth(
        theme.fg(
          "dim",
          `  ${configuredKeys(this.keybindings, "tui.select.up")}/${configuredKeys(this.keybindings, "tui.select.down")}/jk select · ${configuredKeys(this.keybindings, "tui.select.confirm")} take over · x abort · ${configuredKeys(this.keybindings, "tui.select.cancel")} close`,
        ),
        width,
      ),
    )

    return lines.slice(0, Math.max(0, rows - 1))
  }

  private renderRows(
    subs: readonly SubagentSnapshot[],
    width: number,
    height: number,
  ): string[] {
    const theme = this.theme
    const out: string[] = []

    // Scroll window around selection
    let start = 0

    if (subs.length > height) {
      start = Math.min(
        Math.max(0, this.selection.index - Math.floor(height / 2)),
        subs.length - height,
      )
    }

    const visible = subs.slice(start, start + height)

    for (let i = 0; i < visible.length; i++) {
      const snap = visible[i]
      const index = start + i
      const isSelected = index === this.selection.index

      const title = isSelected
        ? theme.fg("accent", sanitizeTerminalText(snap.title))
        : theme.fg("text", sanitizeTerminalText(snap.title))

      const left = `${isSelected ? theme.fg("accent", "› ") : "  "}${statusGlyph(snap, theme)} ${title} ${theme.fg("dim", snap.id)}`

      const dot = theme.fg("dim", " · ")

      const rightParts = [
        theme.fg("muted", snap.backend),
        theme.fg("muted", sanitizeTerminalText(snap.meta.modelLabel ?? "?")),
        theme.fg("muted", snap.meta.thinkingLevel ?? "?"),
        theme.fg("muted", formatElapsed(snap)),
        statusWord(snap, theme),
      ]

      const right =
        width >= 60 ? `${rightParts.join(dot)} ` : `${statusWord(snap, theme)} `

      const rightWidth = visibleWidth(right)
      const leftMax = Math.max(0, width - rightWidth - 2)
      const leftTruncated = truncateToWidth(left, leftMax)
      const gap = Math.max(2, width - visibleWidth(leftTruncated) - rightWidth)

      const row = truncateToWidth(
        leftTruncated + " ".repeat(gap) + right,
        width,
      )

      out.push(row)
    }

    if (start > 0) {
      out[0] = truncateToWidth(theme.fg("dim", `   ... ${start} more`), width)
    }

    if (start + height < subs.length) {
      out[out.length - 1] = truncateToWidth(
        theme.fg("dim", `   ... ${subs.length - start - height} more`),
        width,
      )
    }

    return out
  }

  invalidate(): void {
    this.tui.requestRender()
  }
}

// --- Takeover view ------------------------------------------------------------

const TRANSCRIPT_SCROLL_STEP = 6

export class TakeoverView implements Component, Focusable {
  private tui: TUI
  private theme: Theme
  private keybindings: Pick<KeybindingsManager, "getKeys" | "matches">
  private id: string
  private view: SubagentReadModel
  private done: (value: null) => void
  private options?: TakeoverOptions

  private input = new Input({ prompt: "" })
  /** Scroll offset in lines from the bottom of the transcript. 0 = pinned to bottom. */
  private scrollOffset = 0
  private unsubscribe: () => void
  private renderTimer?: ReturnType<typeof setTimeout>
  private ticker: ReturnType<typeof setInterval>
  private closed = false

  private _focused = false
  get focused(): boolean {
    return this._focused
  }
  set focused(value: boolean) {
    this._focused = value
    this.input.focused = value
  }

  constructor(
    tui: TUI,
    theme: Theme,
    keybindings: Pick<KeybindingsManager, "getKeys" | "matches">,
    id: string,
    view: SubagentReadModel,
    done: (value: null) => void,
    options?: TakeoverOptions,
  ) {
    this.tui = tui
    this.theme = theme
    this.keybindings = keybindings
    this.id = id
    this.view = view
    this.done = done
    this.options = options
    this.unsubscribe = view.subscribeTo(id, () => this.scheduleRender())
    this.ticker = setInterval(() => {
      if (this.snap()?.status === "running") this.tui.requestRender()
    }, ACTIVITY_FRAME_MS)
    this.input.onSubmit = (value: string) => {
      const text = value.trim()

      if (!text) return
      this.input.setValue("")
      this.view.requestSend(this.id, text)
      this.scrollOffset = 0
      this.tui.requestRender()
    }
  }

  private snap(): SubagentSnapshot | undefined {
    return this.view.get(this.id)
  }

  private scheduleRender() {
    if (this.renderTimer) return
    // Streaming can emit an event per token. Limit terminal repaints so this
    // view cannot starve input handling or make the child look frozen.
    this.renderTimer = setTimeout(() => {
      this.renderTimer = undefined

      if (!this.closed) this.tui.requestRender()
    }, 50)
  }

  private cleanup() {
    if (this.closed) return false
    this.closed = true
    this.unsubscribe()
    clearInterval(this.ticker)

    if (this.renderTimer) clearTimeout(this.renderTimer)
    this.renderTimer = undefined

    return true
  }

  private close() {
    if (this.cleanup()) this.done(null)
  }

  dispose(): void {
    this.cleanup()
  }

  handleInput(data: string): void {
    if (this.keybindings.matches(data, "app.clear")) {
      const snap = this.snap()

      if (snap?.status === "running") this.view.requestAbort(this.id)

      return
    }

    if (
      this.keybindings.matches(data, "app.interrupt") ||
      this.keybindings.matches(data, "tui.select.cancel")
    ) {
      this.close()

      return
    }

    if (this.keybindings.matches(data, "tui.editor.cursorUp")) {
      this.scrollOffset += TRANSCRIPT_SCROLL_STEP
      this.tui.requestRender()

      return
    }

    if (this.keybindings.matches(data, "tui.editor.cursorDown")) {
      this.scrollOffset = Math.max(
        0,
        this.scrollOffset - TRANSCRIPT_SCROLL_STEP,
      )
      this.tui.requestRender()

      return
    }

    if (this.keybindings.matches(data, "tui.editor.pageUp")) {
      this.scrollOffset += this.viewportHeight()
      this.tui.requestRender()

      return
    }

    if (this.keybindings.matches(data, "tui.editor.pageDown")) {
      this.scrollOffset = Math.max(0, this.scrollOffset - this.viewportHeight())
      this.tui.requestRender()

      return
    }

    this.input.handleInput(data)
    this.tui.requestRender()
  }

  private viewportHeight(): number {
    const rows = this.tui.terminal.rows || 30

    // Six rows hold the header, metadata, spacing, input, and hints.
    return Math.max(0, rows - 7)
  }

  render(width: number): string[] {
    const theme = this.theme

    if (width <= 0) return []
    const contentWidth = Math.max(0, width - 2)
    const lines: string[] = []
    const snap = this.snap()

    if (!snap) {
      lines.push(
        truncateToWidth(
          `  ${theme.fg("muted", `${sanitizeTerminalText(this.id)} is no longer tracked`)}`,
          width,
        ),
      )

      return lines
    }

    const indicator = statusGlyph(snap, theme)

    const header =
      `${indicator} ` +
      theme.fg(
        "accent",
        theme.bold(
          `Subagent · ${snap.id} · ${sanitizeTerminalText(snap.title)}`,
        ),
      ) +
      ` · ${statusWord(snap, theme)}` +
      theme.fg("muted", ` · ${formatElapsed(snap)}`)

    const metadata =
      `${snap.backend} · ${sanitizeTerminalText(snap.meta.modelLabel ?? "?")}` +
      ` · ${snap.meta.thinkingLevel ?? "?"}` +
      (this.options?.badge
        ? ` · ${sanitizeTerminalText(this.options.badge)}`
        : "")

    lines.push(
      truncateToWidth(`  ${header}`, width),
      truncateToWidth(`  ${theme.fg("dim", metadata)}`, width),
      "",
    )

    // Fixed-height transcript viewport. Error and scroll status consume rows
    // inside the viewport so streaming/scrolling never changes overlay height.
    const transcript = buildTranscriptLines(snap, contentWidth, theme)
    const viewport = this.viewportHeight()
    const errorRows = snap.errorText ? 1 : 0
    const scrollRows = this.scrollOffset > 0 ? 1 : 0
    const transcriptCapacity = Math.max(1, viewport - errorRows - scrollRows)
    const maxOffset = Math.max(0, transcript.length - transcriptCapacity)

    if (this.scrollOffset > maxOffset) this.scrollOffset = maxOffset

    const body: string[] = []

    if (snap.errorText) {
      body.push(
        truncateToWidth(
          theme.fg("error", `error: ${sanitizeTerminalText(snap.errorText)}`),
          contentWidth,
        ),
      )
    }

    const capacity = Math.max(
      1,
      viewport - body.length - (this.scrollOffset > 0 ? 1 : 0),
    )

    const end = transcript.length - this.scrollOffset
    const visible = transcript.slice(Math.max(0, end - capacity), end)

    if (visible.length === 0) body.push(theme.fg("dim", "(no output yet)"))
    else body.push(...visible)

    if (this.scrollOffset > 0) {
      body.push(
        truncateToWidth(
          theme.fg("dim", `... ${this.scrollOffset} lines below · ↓/pgdn`),
          width,
        ),
      )
    }

    while (body.length < viewport) body.push("")
    lines.push(...body.slice(0, viewport))
    lines.push("")

    const inputIndicator = inputActivityIndicator(
      theme,
      snap.status === "running",
    )

    const input = this.input
      .render(Math.max(1, width - 4))
      .map((line) => `  ${inputIndicator} ${line}`)

    const height = Math.max(0, (this.tui.terminal.rows || 30) - 1)

    return [
      ...lines.slice(0, Math.max(0, height - input.length - 1)),
      ...input,
      theme.fg(
        "dim",
        `  ${configuredKeys(this.keybindings, "tui.input.submit")} send · ${configuredKeys(this.keybindings, "app.interrupt")} back · ${configuredKeys(this.keybindings, "app.clear")} abort run · ${configuredKeys(this.keybindings, "tui.editor.cursorUp")}/${configuredKeys(this.keybindings, "tui.editor.cursorDown")} scroll · ${configuredKeys(this.keybindings, "tui.editor.pageUp")}/${configuredKeys(this.keybindings, "tui.editor.pageDown")} page`,
      ),
    ]
      .slice(0, height)
      .map((line) => truncateToWidth(line, width))
  }

  invalidate(): void {
    this.input.invalidate()
  }
}
