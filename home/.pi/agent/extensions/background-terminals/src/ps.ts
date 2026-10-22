/**
 * /ps UI. two-stage full-screen overlay over the synchronous
 * TerminalReadModel:
 * - TerminalDashboard: list of all tracked terminals (select, kill, open).
 * - TerminalDetailView: read-only inspector for one terminal. metadata,
 *   stdout/stderr toggle, scrolling, live tail. No input surface: background
 *   terminals have no stdin by design.
 */

import type {
  ExtensionCommandContext,
  KeybindingsManager,
  Theme,
} from "@earendil-works/pi-coding-agent"
import { formatSize } from "@earendil-works/pi-coding-agent"
import type { Component, TUI } from "@earendil-works/pi-tui"
import { truncateToWidth } from "@earendil-works/pi-tui"
import {
  ACTIVITY_FRAME_MS,
  activityIndicator,
} from "@pi/shared/activity-status"
import { formatElapsed, formatExit, type TerminalSnapshot } from "./domain.ts"
import type { TerminalReadModel } from "./manager.ts"
import { createOutputLineCache, sanitizeText } from "./ui/output-view.ts"

const GUTTER = "  "

const OUTPUT_SCROLL_STEP = 6

type PickerKeybindings = Pick<KeybindingsManager, "getKeys" | "matches">

interface PickerContext {
  ui: {
    custom<T>(
      factory: (
        tui: TUI,
        theme: Theme,
        keybindings: PickerKeybindings,
        done: (result: T) => void,
      ) =>
        | (Component & { dispose?(): void })
        | Promise<Component & { dispose?(): void }>,
      options?: Parameters<ExtensionCommandContext["ui"]["custom"]>[1],
    ): Promise<T>
    notify: ExtensionCommandContext["ui"]["notify"]
  }
}

/** One-line-safe rendering of model-provided text (titles, commands): a
 * newline or control char inside a fixed-height row desyncs the renderer. */
function oneLine(text: string) {
  return sanitizeText(text.replace(/\s+/g, " "))
}

function configuredKeys(
  keybindings: PickerKeybindings,
  binding: Parameters<KeybindingsManager["getKeys"]>[0],
) {
  return keybindings.getKeys(binding).join("/") || "unbound"
}

function statusGlyph(snap: TerminalSnapshot, theme: Theme) {
  switch (snap.status) {
    case "running":
      return activityIndicator(theme, "running")
    case "done":
      return activityIndicator(theme, "done")
    case "failed":
      return activityIndicator(theme, "error")
    case "killed":
      return activityIndicator(theme, "stopped")
  }
}

function statusWord(snap: TerminalSnapshot, theme: Theme) {
  switch (snap.status) {
    case "running":
      return theme.fg("warning", "running")
    case "done":
      return theme.fg("success", "done")
    case "failed":
      return theme.fg("error", "failed")
    case "killed":
      return theme.fg("muted", "killed")
  }
}

export async function openTerminalPicker(
  ctx: PickerContext,
  view: TerminalReadModel,
) {
  const selection: DashboardSelection = { index: 0 }

  while (true) {
    if (view.size() === 0) {
      ctx.ui.notify("No background terminals", "info")

      return
    }

    const picked = await ctx.ui.custom<string | null>(
      (tui, theme, keybindings, done) =>
        new TerminalDashboard(tui, theme, keybindings, view, selection, done),
      {
        overlay: true,
        overlayOptions: { anchor: "center", width: "100%", maxHeight: "100%" },
      },
    )

    if (!picked) return

    if (!view.get(picked)) continue

    await ctx.ui.custom<null>(
      (tui, theme, keybindings, done) =>
        new TerminalDetailView(tui, theme, keybindings, picked, view, done),
      {
        overlay: true,
        overlayOptions: { anchor: "center", width: "100%", maxHeight: "100%" },
      },
    )
  }
}

export interface DashboardSelection {
  id?: string
  index: number
}

export function reconcileDashboardSelection(
  selection: DashboardSelection,
  terminals: readonly Pick<TerminalSnapshot, "id">[],
) {
  const stableIndex = selection.id
    ? terminals.findIndex((snap) => snap.id === selection.id)
    : -1

  selection.index =
    stableIndex >= 0
      ? stableIndex
      : Math.min(
          Math.max(0, selection.index),
          Math.max(0, terminals.length - 1),
        )
  selection.id = terminals[selection.index]?.id
}

class TerminalDashboard implements Component {
  private tui: TUI
  private theme: Theme
  private keybindings: PickerKeybindings
  private view: TerminalReadModel
  private selection: DashboardSelection
  private done: (value: string | null) => void
  private closed = false
  private ticker: ReturnType<typeof setInterval>
  private unsubChange: () => void

  constructor(
    tui: TUI,
    theme: Theme,
    keybindings: PickerKeybindings,
    view: TerminalReadModel,
    selection: DashboardSelection,
    done: (value: string | null) => void,
  ) {
    this.tui = tui
    this.theme = theme
    this.keybindings = keybindings
    this.view = view
    this.selection = selection
    this.done = done
    // Refresh running status and elapsed time at spinner cadence.
    this.ticker = setInterval(() => {
      if (this.terminals().some((snap) => snap.status === "running"))
        this.tui.requestRender()
    }, ACTIVITY_FRAME_MS)
    this.unsubChange = view.subscribe(() => this.tui.requestRender())
  }

  private terminals(): readonly TerminalSnapshot[] {
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
    const terminals = this.terminals()
    reconcileDashboardSelection(this.selection, terminals)

    if (this.keybindings.matches(data, "tui.select.cancel")) {
      this.close(null)

      return
    }

    if (this.keybindings.matches(data, "tui.select.confirm")) {
      const snap = terminals[this.selection.index]

      if (snap) this.close(snap.id)

      return
    }

    if (this.keybindings.matches(data, "tui.select.up") || data === "k") {
      if (terminals.length > 0) {
        this.selection.index =
          (this.selection.index - 1 + terminals.length) % terminals.length
        this.selection.id = terminals[this.selection.index]?.id
        this.tui.requestRender()
      }

      return
    }

    if (this.keybindings.matches(data, "tui.select.down") || data === "j") {
      if (terminals.length > 0) {
        this.selection.index = (this.selection.index + 1) % terminals.length
        this.selection.id = terminals[this.selection.index]?.id
        this.tui.requestRender()
      }

      return
    }

    if (data === "x") {
      const snap = terminals[this.selection.index]

      if (snap?.status === "running") this.view.requestKill(snap.id)
    }
  }

  render(width: number): string[] {
    if (width <= 0) return []

    const terminals = this.terminals()
    reconcileDashboardSelection(this.selection, terminals)

    const height = Math.max(0, (this.tui.terminal.rows || 30) - 1)

    if (height === 0) return []

    const running = terminals.filter((snap) => snap.status === "running").length

    const heading =
      this.theme.fg("accent", this.theme.bold("Background terminals")) +
      this.theme.fg("muted", ` · ${running}/${terminals.length} running`)

    const rowHeight = Math.max(0, height - 3)
    const lines = [truncateToWidth(`${GUTTER}${heading}`, width)]

    if (height > 1) lines.push("")
    lines.push(...this.renderRows(terminals, width, rowHeight))

    if (height > 2) {
      lines.push(
        truncateToWidth(
          this.theme.fg(
            "dim",
            `${GUTTER}${configuredKeys(this.keybindings, "tui.select.up")}/${configuredKeys(this.keybindings, "tui.select.down")}/jk select · ${configuredKeys(this.keybindings, "tui.select.confirm")} inspect · x kill · ${configuredKeys(this.keybindings, "tui.select.cancel")} close`,
          ),
          width,
        ),
      )
    }

    return lines.slice(0, height)
  }

  private renderRows(
    terminals: readonly TerminalSnapshot[],
    width: number,
    height: number,
  ): string[] {
    if (height === 0) return []

    let start = 0

    if (terminals.length > height) {
      start = Math.min(
        Math.max(0, this.selection.index - Math.floor(height / 2)),
        terminals.length - height,
      )
    }

    const visible = terminals.slice(start, start + height)

    const lines = visible.map((snap, offset) => {
      const index = start + offset
      const selected = index === this.selection.index

      const title = selected
        ? this.theme.fg("accent", oneLine(snap.title))
        : this.theme.fg("text", oneLine(snap.title))

      const exit = snap.status === "running" ? "" : ` · ${formatExit(snap)}`

      const metadata = [
        `pid ${snap.pid ?? "?"}`,
        formatElapsed(snap),
        `${statusWord(snap, this.theme)}${exit}`,
      ].join(this.theme.fg("dim", " · "))

      const row = truncateToWidth(
        `${selected ? this.theme.fg("accent", "› ") : GUTTER}${statusGlyph(snap, this.theme)} ${title} ${this.theme.fg("dim", snap.id)} ${this.theme.fg("muted", metadata)}`,
        width,
      )

      return row
    })

    if (start > 0) {
      lines[0] = truncateToWidth(
        this.theme.fg("dim", `${GUTTER}... ${start} more`),
        width,
      )
    }

    if (start + height < terminals.length) {
      lines[lines.length - 1] = truncateToWidth(
        this.theme.fg(
          "dim",
          `${GUTTER}... ${terminals.length - start - height} more`,
        ),
        width,
      )
    }

    while (lines.length < height) lines.push("")

    return lines
  }

  invalidate(): void {
    return undefined
  }
}

class TerminalDetailView implements Component {
  private tui: TUI
  private theme: Theme
  private keybindings: PickerKeybindings
  private id: string
  private view: TerminalReadModel
  private done: (value: null) => void
  private stream: "stdout" | "stderr" = "stdout"
  private scrollOffset = 0
  private lineCache = createOutputLineCache()
  private unsubscribe: () => void
  private renderTimer?: ReturnType<typeof setTimeout>
  private ticker: ReturnType<typeof setInterval>
  private closed = false

  constructor(
    tui: TUI,
    theme: Theme,
    keybindings: PickerKeybindings,
    id: string,
    view: TerminalReadModel,
    done: (value: null) => void,
  ) {
    this.tui = tui
    this.theme = theme
    this.keybindings = keybindings
    this.id = id
    this.view = view
    this.done = done
    this.unsubscribe = view.subscribeTo(id, () => this.scheduleRender())
    // Refresh the running indicator and elapsed time at spinner cadence.
    this.ticker = setInterval(() => {
      if (this.snap()?.status === "running") this.tui.requestRender()
    }, ACTIVITY_FRAME_MS)
  }

  private snap(): TerminalSnapshot | undefined {
    return this.view.get(this.id)
  }

  private scheduleRender() {
    if (this.renderTimer) return
    // A chatty process emits a chunk per write. Limit terminal repaints so
    // this view cannot starve input handling.
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
    if (
      this.keybindings.matches(data, "app.interrupt") ||
      this.keybindings.matches(data, "tui.select.cancel")
    ) {
      this.close()

      return
    }

    if (data === "t") {
      this.stream = this.stream === "stdout" ? "stderr" : "stdout"
      this.lineCache = createOutputLineCache()
      this.scrollOffset = 0
      this.tui.requestRender()

      return
    }

    if (data === "x") {
      const snap = this.snap()

      if (snap?.status === "running") this.view.requestKill(this.id)

      return
    }

    if (this.keybindings.matches(data, "tui.editor.cursorUp") || data === "k") {
      this.scrollOffset += OUTPUT_SCROLL_STEP
      this.tui.requestRender()

      return
    }

    if (
      this.keybindings.matches(data, "tui.editor.cursorDown") ||
      data === "j"
    ) {
      this.scrollOffset = Math.max(0, this.scrollOffset - OUTPUT_SCROLL_STEP)
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

    if (data === "g") {
      this.scrollOffset = Number.MAX_SAFE_INTEGER
      this.tui.requestRender()

      return
    }

    if (data === "G") {
      this.scrollOffset = 0
      this.tui.requestRender()
    }
  }

  private screenHeight(): number {
    return Math.max(0, (this.tui.terminal.rows || 30) - 1)
  }

  private viewportHeight(): number {
    return Math.max(0, this.screenHeight() - 6)
  }

  render(width: number): string[] {
    if (width <= 0) return []

    const height = this.screenHeight()

    if (height === 0) return []

    const snap = this.snap()

    if (!snap) {
      const lines = Array.from({ length: height }, () => "")
      lines[0] = truncateToWidth(
        `${GUTTER}${this.id} is no longer tracked`,
        width,
      )

      if (height > 1) {
        lines[height - 1] = truncateToWidth(
          this.theme.fg(
            "dim",
            `${GUTTER}${configuredKeys(this.keybindings, "tui.select.cancel")} back`,
          ),
          width,
        )
      }

      return lines
    }

    const lines = [
      truncateToWidth(
        `${GUTTER}${statusGlyph(snap, this.theme)} ${this.theme.fg("accent", this.theme.bold(`Background process · ${snap.id} · ${oneLine(snap.title)}`))}`,
        width,
      ),
      truncateToWidth(
        this.theme.fg(
          "muted",
          `${GUTTER}${statusWord(snap, this.theme)} · ${formatElapsed(snap)} · pid ${snap.pid ?? "?"}${snap.status === "running" ? "" : ` · ${formatExit(snap)}`} · ${oneLine(snap.cwd)}`,
        ),
        width,
      ),
      truncateToWidth(
        `${GUTTER}${this.theme.fg("dim", "$ ")}${this.theme.fg("text", oneLine(snap.command))}`,
        width,
      ),
      "",
    ]

    const active = this.stream
    const buffer = active === "stdout" ? snap.stdout : snap.stderr

    const tab = (name: "stdout" | "stderr", size: number) =>
      name === active
        ? this.theme.fg(
            "accent",
            this.theme.bold(`${name} (${formatSize(size)})`),
          )
        : this.theme.fg("muted", `${name} (${formatSize(size)})`)

    lines.push(
      truncateToWidth(
        `${GUTTER}${tab("stdout", snap.stdout.totalBytes)}${this.theme.fg("dim", " · ")}${tab("stderr", snap.stderr.totalBytes)}${this.theme.fg("dim", " · t switch")}`,
        width,
      ),
    )

    const output = this.lineCache.get(
      buffer.text,
      buffer.totalBytes,
      width - GUTTER.length,
    )

    const viewport = this.viewportHeight()
    const noteRows: string[] = []

    if (snap.errorText) {
      noteRows.push(
        truncateToWidth(
          this.theme.fg("error", `${GUTTER}error: ${oneLine(snap.errorText)}`),
          width,
        ),
      )
    }

    if (buffer.truncatedBytes > 0) {
      noteRows.push(
        truncateToWidth(
          this.theme.fg(
            "dim",
            `${GUTTER}first ${formatSize(buffer.truncatedBytes)} dropped from view. full log: ${buffer.spillPath ?? "(unavailable)"}`,
          ),
          width,
        ),
      )
    }

    const body = [...noteRows]
    const scrollRows = this.scrollOffset > 0 ? 1 : 0
    const capacity = Math.max(1, viewport - body.length - scrollRows)
    const maxOffset = Math.max(0, output.length - capacity)

    if (this.scrollOffset > maxOffset) this.scrollOffset = maxOffset

    const end = output.length - this.scrollOffset
    const visible = output.slice(Math.max(0, end - capacity), end)

    if (visible.length === 0) {
      body.push(this.theme.fg("dim", `${GUTTER}(no ${active} yet)`))
    } else {
      for (const line of visible) {
        body.push(truncateToWidth(`${GUTTER}${line}`, width))
      }
    }

    if (this.scrollOffset > 0) {
      body.push(
        truncateToWidth(
          this.theme.fg(
            "dim",
            `${GUTTER}... ${this.scrollOffset} lines below · ↓/pgdn`,
          ),
          width,
        ),
      )
    }

    while (body.length < viewport) body.push("")
    lines.push(...body.slice(0, viewport))
    lines.push(
      truncateToWidth(
        this.theme.fg(
          "dim",
          `${GUTTER}${configuredKeys(this.keybindings, "tui.select.cancel")} back · t stdout/stderr · x kill · ${configuredKeys(this.keybindings, "tui.editor.cursorUp")}/${configuredKeys(this.keybindings, "tui.editor.cursorDown")}/jk scroll · ${configuredKeys(this.keybindings, "tui.editor.pageUp")}/${configuredKeys(this.keybindings, "tui.editor.pageDown")} page · g/G top/bottom`,
        ),
        width,
      ),
    )

    return lines.slice(0, height)
  }

  invalidate(): void {
    return undefined
  }
}
