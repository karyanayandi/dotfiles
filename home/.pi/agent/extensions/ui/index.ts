import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
  getAgentDir,
} from "@earendil-works/pi-coding-agent"
import {
  truncateToWidth,
  type Component,
  type EditorTheme,
  type TUI,
  visibleWidth,
} from "@earendil-works/pi-tui"
import { Effect } from "effect"

import {
  addBorderLabels,
  addBottomLabel,
  addSideBorders,
  sanitizeTerminalText,
} from "./layout.js"
import {
  installCompactMessages,
  installToolSpacing,
  registerCompactTools,
} from "./compact.js"
import type { ExtensionContext } from "@earendil-works/pi-coding-agent"

class EmptyFooter implements Component {
  render(): string[] {
    return []
  }

  invalidate(): void {}
}

function isHorizontalBorder(line: string): boolean {
  const plain = line.replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")
  return /^─+$/.test(plain) || /^─── [↑↓] \d+ more ─*$/.test(plain)
}

// pi-tui's editor draws a software caret as reverse-video (\x1b[7m…\x1b[0m).
// Unlike the hardware cursor, that block is static text that ignores window
// focus, so you can't tell which terminal has focus. Strip it so the only
// visible caret is the hardware cursor, which every terminal ghosts on blur.
function neutralizeFakeCursor(line: string): string {
  return line.replace(/\u001b\[7m([\s\S]*?)\u001b\[0m/g, "$1")
}

type Layout = "full" | "lite" | "minimal" | "off"

function parseLayout(value: unknown): Layout | undefined {
  if (
    value === "full" ||
    value === "lite" ||
    value === "minimal" ||
    value === "off"
  )
    return value
  return undefined
}

function readSettingsField(path: string): unknown {
  if (!existsSync(path)) return undefined
  try {
    const settings = JSON.parse(readFileSync(path, "utf8"))
    return settings.ui?.layout
  } catch {
    return undefined
  }
}

function readLayout(
  cwd: string,
  projectTrusted: boolean,
): { layout: Layout; scope: "global" | "project" } {
  const globalPath = join(getAgentDir(), "settings.json")
  const globalLayout = parseLayout(readSettingsField(globalPath))
  const projectLayout = projectTrusted
    ? parseLayout(readSettingsField(join(cwd, ".pi/settings.json")))
    : undefined
  if (projectLayout) return { layout: projectLayout, scope: "project" }
  if (globalLayout) return { layout: globalLayout, scope: "global" }
  return { layout: "full", scope: "global" }
}

function writeUiSetting(
  cwd: string,
  scope: "global" | "project",
  value: Layout,
): void {
  const path =
    scope === "global"
      ? join(getAgentDir(), "settings.json")
      : join(cwd, ".pi/settings.json")
  const dir = dirname(path)
  const current = existsSync(path) ? JSON.parse(readFileSync(path, "utf8")) : {}
  const next = { ...current, ui: { ...current.ui, layout: value } }
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  writeFileSync(path, JSON.stringify(next, null, 2))
}

export default function ui(pi: ExtensionAPI) {
  let tui: TUI | undefined
  let succeeded = 0
  let failed = 0
  let branch: string | undefined
  let dirty: boolean | undefined
  let refreshingGit = false
  let refreshPending = false
  let pendingCwd: string | undefined
  let gitAbortController: AbortController | undefined
  let stopped = false
  let clearTerminalOnEditorMount = false
  let working = false
  let spinnerFrame = 0
  let spinnerTimer: ReturnType<typeof setInterval> | undefined
  const spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  let layout: Layout = "full"
  let inputTokens = 0
  let outputTokens = 0
  let tokensDirty = true
  let restoreCompactMessages: (() => void) | undefined
  let restoreToolSpacing: (() => void) | undefined

  // pi-minimalist message/tool style applies only to minimal and lite layouts.
  // The getter is read at render time, so /ui layout switches take effect live.
  const getCompact = () => layout === "minimal" || layout === "lite"
  registerCompactTools(pi, getCompact)

  const fmt = (n: number) => (n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`)

  const applySessionUI = (ctx: ExtensionContext) => {
    if (layout === "lite") {
      // lite: rely on the vanilla "Working..." indicator in the response
      // area instead of drawing a spinner in the footer.
      ctx.ui.setFooter((tui, theme) => ({
        dispose() {},
        invalidate() {},
        render(width: number): string[] {
          if (tokensDirty) {
            tokensDirty = false
            inputTokens = 0
            outputTokens = 0
            for (const e of ctx.sessionManager.getBranch()) {
              if (e.type === "message" && e.message.role === "assistant") {
                inputTokens += e.message.usage?.input ?? 0
                outputTokens += e.message.usage?.output ?? 0
              }
            }
          }
          const left = theme.fg(
            "dim",
            sanitizeTerminalText(
              `${ctx.model?.id ?? "no model"} · ${pi.getThinkingLevel()}`,
            ),
          )
          const parts = [ctx.model ? fmt(ctx.model.contextWindow) : "—"]
          if (inputTokens > 0 || outputTokens > 0) {
            parts.push(
              `\u{f062}${fmt(inputTokens)}`, // nf-fa-arrow_up: input
              `\u{f063}${fmt(outputTokens)}`, // nf-fa-arrow_down: output
            )
          }
          const right = theme.fg("dim", parts.join(" | "))
          const pad = " ".repeat(
            Math.max(1, width - visibleWidth(left) - visibleWidth(right)),
          )
          return [truncateToWidth(left + pad + right, width)]
        },
      }))
    } else {
      ctx.ui.setFooter(layout === "off" ? undefined : () => new EmptyFooter())
    }
    if (layout !== "lite") ctx.ui.setWorkingVisible(false)
  }

  const startSpinner = () => {
    working = true
    spinnerFrame = 0
    if (spinnerTimer) clearInterval(spinnerTimer)
    spinnerTimer = setInterval(() => {
      spinnerFrame = (spinnerFrame + 1) % spinnerFrames.length
      tui?.requestRender()
    }, 80)
    tui?.requestRender()
  }

  const stopSpinner = () => {
    working = false
    if (spinnerTimer) clearInterval(spinnerTimer)
    spinnerTimer = undefined
    tui?.requestRender()
  }

  pi.registerCommand("ui", {
    description: "Configure UI layout",
    handler: async (args, ctx) => {
      const arg = args.trim().toLowerCase()
      const [settingArg, valueArg] = arg.split(/\s+/, 2)
      const isLayoutArg = (v: string | undefined) =>
        v === "full" || v === "lite" || v === "minimal" || v === "off"

      let next: Layout | undefined
      const value =
        valueArg ?? (isLayoutArg(settingArg) ? settingArg : undefined)
      if (isLayoutArg(value)) {
        next = value as Layout
      } else {
        const current = readLayout(ctx.cwd, ctx.isProjectTrusted()).layout
        const choice = await ctx.ui.select(`UI layout (current: ${current})`, [
          "full",
          "lite",
          "minimal",
          "off",
        ])
        if (!choice) return
        next = choice as Layout
      }

      const { layout: current, scope } = readLayout(
        ctx.cwd,
        ctx.isProjectTrusted(),
      )
      if (next === current) {
        ctx.ui.notify(`UI layout already ${current}`, "info")
        return
      }
      writeUiSetting(ctx.cwd, scope, next)
      layout = next
      applySessionUI(ctx)
      ctx.ui.notify(`UI layout: ${current} → ${next}`, "info")
      tui?.requestRender()
    },
  })

  const readGitState = (cwd: string, signal: AbortSignal) =>
    Effect.gen(function* () {
      const branchResult = yield* Effect.promise(() =>
        pi
          .exec("git", ["branch", "--show-current"], {
            cwd,
            signal,
            timeout: 2_000,
          })
          .catch(() => undefined),
      )
      if (signal.aborted) return
      branch =
        branchResult?.code === 0 && !branchResult.killed
          ? branchResult.stdout.trim() || undefined
          : undefined
      if (!branch) {
        dirty = undefined
        return
      }
      const statusResult = yield* Effect.promise(() =>
        pi
          .exec("git", ["--no-optional-locks", "status", "--porcelain"], {
            cwd,
            signal,
            timeout: 2_000,
          })
          .catch(() => undefined),
      )
      if (signal.aborted) return
      dirty =
        statusResult?.code === 0 && !statusResult.killed
          ? Boolean(statusResult.stdout.trim())
          : undefined
    })

  const refreshGit = async (cwd: string) => {
    if (stopped) return
    pendingCwd = cwd
    if (refreshingGit) {
      refreshPending = true
      return
    }
    refreshingGit = true
    const controller = new AbortController()
    gitAbortController = controller
    try {
      do {
        refreshPending = false
        await Effect.runPromise(readGitState(pendingCwd, controller.signal))
      } while (refreshPending && !controller.signal.aborted)
    } finally {
      refreshingGit = false
      if (gitAbortController === controller) gitAbortController = undefined
      tui?.requestRender()
    }
  }

  pi.on("message_end", () => {
    tokensDirty = true
    tui?.requestRender()
  })

  pi.on("agent_start", (_event, ctx) => {
    if (layout !== "lite") ctx.ui.setWorkingVisible(false)
    succeeded = 0
    failed = 0
    startSpinner()
    void refreshGit(ctx.cwd)
  })

  pi.on("tool_execution_end", (event, ctx) => {
    if (event.isError) failed++
    else succeeded++
    tui?.requestRender()
    void refreshGit(ctx.cwd)
  })

  pi.on("agent_end", () => {
    stopSpinner()
  })

  pi.on("message_start", (_event, ctx) => {
    if (layout !== "lite") ctx.ui.setWorkingVisible(false)
  })

  pi.on("session_start", (event, ctx) => {
    stopped = false
    clearTerminalOnEditorMount = event.reason === "startup"
    layout = readLayout(ctx.cwd, ctx.isProjectTrusted()).layout
    inputTokens = 0
    outputTokens = 0
    tokensDirty = true
    applySessionUI(ctx)
    restoreCompactMessages?.()
    restoreToolSpacing?.()
    restoreCompactMessages = installCompactMessages(ctx.ui.theme, getCompact)
    restoreToolSpacing = installToolSpacing(getCompact, ctx.ui.theme)
    if (getCompact()) ctx.ui.setHiddenThinkingLabel("")
    void refreshGit(ctx.cwd)

    class SimpleEditor extends CustomEditor {
      private readonly defaultBorderColor: (text: string) => string
      constructor(
        instance: TUI,
        theme: EditorTheme,
        keybindings: KeybindingsManager,
      ) {
        super(instance, theme, keybindings, { paddingX: 2 })
        tui = instance
        this.defaultBorderColor = this.borderColor.bind(this)
        // Rely on the real terminal cursor for position so it ghosts when the
        // window loses focus (like other TUIs) instead of pi's always-solid
        // software block cursor. The fake cursor is stripped below.
        instance.setShowHardwareCursor(true)
        if (clearTerminalOnEditorMount) {
          clearTerminalOnEditorMount = false
          instance.terminal.clearScreen()
          instance.requestRender(true)
        }
      }

      override render(width: number): string[] {
        if (layout === "off" || layout === "lite") {
          // Reset borderColor: a prior minimal render leaves it as () => "",
          // which would make super.render draw invisible borders here.
          this.borderColor = this.defaultBorderColor
          this.setPaddingX(1)
          return super.render(width).map(neutralizeFakeCursor)
        }
        const isMinimal = layout === "minimal"
        this.borderColor = isMinimal ? () => "" : this.defaultBorderColor
        this.setPaddingX(2)
        const lines = super.render(width).map(neutralizeFakeCursor)
        if (isMinimal) {
          const indicator = working
            ? ctx.ui.theme.fg("text", spinnerFrames[spinnerFrame] ?? "")
            : ctx.ui.theme.fg("text", "┃")
          const firstEmpty = lines.findIndex((line) => line === "")
          const firstContent = firstEmpty >= 0 ? firstEmpty + 1 : 0
          if (firstContent < lines.length) {
            let line = lines[firstContent]
            const paddingX = this.getPaddingX()
            let i = 0
            let removed = 0
            while (removed < paddingX && i < line.length && line[i] === " ") {
              removed++
              i++
            }
            line = indicator + " " + line.slice(i)
            lines[firstContent] = truncateToWidth(line, width, "", true)
          }
          // Add a blank top margin and drop the bottom border.
          const body = lines.filter((line) => line !== "")
          const info = truncateToWidth(
            `${sanitizeTerminalText(ctx.model?.id ?? "no model")} · ${pi.getThinkingLevel()}`,
            width,
            "…",
          )
          return ["", ...body, ctx.ui.theme.fg("muted", info)]
        }

        const borderIndices: number[] = []
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i]
          if (line !== undefined && isHorizontalBorder(line))
            borderIndices.push(i)
        }
        const top = borderIndices.at(0)
        const bottom = borderIndices.at(-1)
        if (top === undefined || bottom === undefined) return lines
        const counts = [
          succeeded > 0 ? ctx.ui.theme.fg("success", `✓${succeeded}`) : "",
          failed > 0 ? ctx.ui.theme.fg("error", `✕${failed}`) : "",
        ]
          .filter(Boolean)
          .join(" ")
        const safeBranch = branch ? sanitizeTerminalText(branch) : undefined
        const gitStateIcon =
          dirty === undefined
            ? ""
            : ctx.ui.theme.fg(dirty ? "error" : "success", dirty ? "✗" : "✓")
        const gitStatus =
          safeBranch && gitStateIcon
            ? `${ctx.ui.theme.fg("accent", safeBranch)} ${gitStateIcon}`
            : safeBranch
              ? ctx.ui.theme.fg("accent", safeBranch)
              : undefined
        const spinner = working
          ? ctx.ui.theme.fg("accent", spinnerFrames[spinnerFrame] ?? "")
          : ""

        lines[top] = addBorderLabels(width, spinner, counts, (text) =>
          this.borderColor(text),
        )
        for (let i = top + 1; i < bottom; i++) {
          const line = lines[i]
          if (line !== undefined)
            lines[i] = addSideBorders(line, width, (text) =>
              this.borderColor(text),
            )
        }
        const status = truncateToWidth(
          [
            gitStatus,
            `${sanitizeTerminalText(ctx.model?.id ?? "no model")} · ${pi.getThinkingLevel()}`,
          ]
            .filter(Boolean)
            .join(" · "),
          Math.max(0, width - 4),
          "…",
        )
        lines[bottom] = addBottomLabel(
          width,
          ctx.ui.theme.fg("muted", status),
          (text) => this.borderColor(text),
        )
        return lines
      }
    }

    ctx.ui.setEditorComponent(
      (instance, theme, keybindings) =>
        new SimpleEditor(instance, theme, keybindings),
    )
  })

  pi.on("session_shutdown", () => {
    stopped = true
    restoreCompactMessages?.()
    restoreCompactMessages = undefined
    restoreToolSpacing?.()
    restoreToolSpacing = undefined
    gitAbortController?.abort()
    gitAbortController = undefined
    stopSpinner()
    tui = undefined
  })
}
