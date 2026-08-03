import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import {
  CustomEditor,
  type ExtensionAPI,
  type ExtensionUIContext,
  type KeybindingsManager,
  getAgentDir,
} from "@earendil-works/pi-coding-agent"
import {
  truncateToWidth,
  type Component,
  type EditorTheme,
  type TUI,
} from "@earendil-works/pi-tui"
import { Effect } from "effect"

import {
  addBorderLabels,
  addBottomLabel,
  addSideBorders,
  sanitizeTerminalText,
} from "./layout.js"
import { compactMessages } from "./messages.js"
import { registerOpenCodeTools } from "./opencode.js"
import { registerCompactTools, removeToolSpacing } from "./tools.js"

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

type Layout = "full" | "minimal" | "off"

type ToolDisplay = "minimal" | "off" | "opencode"

function parseLayout(value: unknown): Layout | undefined {
  if (value === "full" || value === "minimal" || value === "off") return value
  return undefined
}

function parseToolDisplay(value: unknown): ToolDisplay | undefined {
  if (value === "minimal" || value === "off" || value === "opencode")
    return value
  return undefined
}

function readSettingsField(
  path: string,
  field: "layout" | "toolDisplay",
): unknown {
  if (!existsSync(path)) return undefined
  try {
    const settings = JSON.parse(readFileSync(path, "utf8"))
    return settings.ui?.[field]
  } catch {
    return undefined
  }
}

function readLayout(
  cwd: string,
  projectTrusted: boolean,
): { layout: Layout; scope: "global" | "project" } {
  const globalPath = join(getAgentDir(), "settings.json")
  const globalLayout = parseLayout(readSettingsField(globalPath, "layout"))
  const projectLayout = projectTrusted
    ? parseLayout(readSettingsField(join(cwd, ".pi/settings.json"), "layout"))
    : undefined
  if (projectLayout) return { layout: projectLayout, scope: "project" }
  if (globalLayout) return { layout: globalLayout, scope: "global" }
  return { layout: "full", scope: "global" }
}

function readToolDisplay(
  cwd: string,
  projectTrusted: boolean,
): { toolDisplay: ToolDisplay; scope: "global" | "project" } {
  const globalPath = join(getAgentDir(), "settings.json")
  const globalToolDisplay = parseToolDisplay(
    readSettingsField(globalPath, "toolDisplay"),
  )
  const projectToolDisplay = projectTrusted
    ? parseToolDisplay(
        readSettingsField(join(cwd, ".pi/settings.json"), "toolDisplay"),
      )
    : undefined
  if (projectToolDisplay)
    return { toolDisplay: projectToolDisplay, scope: "project" }
  if (globalToolDisplay)
    return { toolDisplay: globalToolDisplay, scope: "global" }
  return { toolDisplay: "minimal", scope: "global" }
}

function writeUiSetting(
  cwd: string,
  scope: "global" | "project",
  field: "layout" | "toolDisplay",
  value: Layout | ToolDisplay,
): void {
  const path =
    scope === "global"
      ? join(getAgentDir(), "settings.json")
      : join(cwd, ".pi/settings.json")
  const dir = dirname(path)
  const current = existsSync(path) ? JSON.parse(readFileSync(path, "utf8")) : {}
  const next = { ...current, ui: { ...current.ui, [field]: value } }
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  writeFileSync(path, JSON.stringify(next, null, 2))
}

export default function ui(pi: ExtensionAPI) {
  let restoreToolSpacing: (() => void) | undefined
  let restoreTools: Array<() => void> | undefined
  let restoreOpenCodeSpacing: (() => void) | undefined
  let restoreOpenCodeTools: Array<() => void> | undefined

  const applyCompactTools = () => {
    if (restoreTools) return
    restoreTools = registerCompactTools(pi)
    restoreToolSpacing = removeToolSpacing()
  }

  const applyOpenCodeTools = () => {
    if (restoreOpenCodeTools) return
    restoreOpenCodeTools = registerOpenCodeTools(pi)
    restoreOpenCodeSpacing = removeToolSpacing()
  }

  const removeToolDisplay = () => {
    if (restoreTools) {
      restoreToolSpacing?.()
      restoreToolSpacing = undefined
      for (const restore of restoreTools) restore()
      restoreTools = undefined
    }
    if (restoreOpenCodeTools) {
      restoreOpenCodeSpacing?.()
      restoreOpenCodeSpacing = undefined
      for (const restore of restoreOpenCodeTools) restore()
      restoreOpenCodeTools = undefined
    }
  }

  const startupLayout = parseLayout(
    readSettingsField(join(getAgentDir(), "settings.json"), "layout"),
  )
  const startupToolDisplay = parseToolDisplay(
    readSettingsField(join(getAgentDir(), "settings.json"), "toolDisplay"),
  )
  if (startupLayout !== "off" && startupToolDisplay !== "off") {
    if (startupToolDisplay === "opencode") applyOpenCodeTools()
    else applyCompactTools()
  }

  pi.registerCommand("ui", {
    description: "Configure UI layout and tool display",
    handler: async (args, ctx) => {
      const arg = args.trim().toLowerCase()
      const [settingArg, valueArg] = arg.split(/\s+/, 2)
      const isLayoutArg = (v: string | undefined) =>
        v === "full" || v === "minimal" || v === "off"
      const isToolDisplayArg = (v: string | undefined) =>
        v === "opencode" || v === "off" || v === "minimal"

      let setting: "layout" | "toolDisplay"
      if (settingArg === "layout" || settingArg === "tools") {
        setting = settingArg === "layout" ? "layout" : "toolDisplay"
      } else if (settingArg === "full") {
        setting = "layout"
      } else if (settingArg === "opencode") {
        setting = "toolDisplay"
      } else {
        const choice = await ctx.ui.select("UI settings", [
          "UI layout",
          "Tool display",
        ])
        if (!choice) return
        setting = choice === "UI layout" ? "layout" : "toolDisplay"
      }

      const current =
        setting === "layout"
          ? readLayout(ctx.cwd, ctx.isProjectTrusted()).layout
          : readToolDisplay(ctx.cwd, ctx.isProjectTrusted()).toolDisplay
      const scope =
        setting === "layout"
          ? readLayout(ctx.cwd, ctx.isProjectTrusted()).scope
          : readToolDisplay(ctx.cwd, ctx.isProjectTrusted()).scope

      let next: Layout | ToolDisplay | undefined
      const value =
        valueArg ??
        (settingArg && settingArg !== "layout" && settingArg !== "tools"
          ? settingArg
          : undefined)
      if (setting === "layout") {
        if (isLayoutArg(value)) next = value as Layout
        else {
          const choice = await ctx.ui.select(
            `UI layout (current: ${current})`,
            ["full", "minimal", "off"],
          )
          if (!choice) return
          next = choice as Layout
        }
      } else {
        if (isToolDisplayArg(value)) next = value as ToolDisplay
        else {
          const choice = await ctx.ui.select(
            `Tool display (current: ${current})`,
            ["minimal", "opencode", "off"],
          )
          if (!choice) return
          next = choice as ToolDisplay
        }
      }
      if (next === current) {
        ctx.ui.notify(
          `${setting === "layout" ? "UI layout" : "Tool display"} already ${current}`,
          "info",
        )
        return
      }
      writeUiSetting(ctx.cwd, scope, setting, next)
      if (setting === "layout") layout = next as Layout
      else toolDisplay = next as ToolDisplay
      applySessionUI(ctx)
      ctx.ui.notify(
        `${setting === "layout" ? "UI layout" : "Tool display"}: ${current} → ${next}`,
        "info",
      )
      tui?.requestRender()
    },
  })

  let tui: TUI | undefined
  let restoreMessages: (() => void) | undefined
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
  let toolDisplay: ToolDisplay = "minimal"

  const applyToolDisplay = () => {
    removeToolDisplay()
    if (layout === "off") return
    if (toolDisplay === "opencode") applyOpenCodeTools()
    else if (toolDisplay === "minimal") applyCompactTools()
  }

  const applySessionUI = (ctx: { ui: ExtensionUIContext }) => {
    const isOff = layout === "off"
    restoreMessages?.()
    restoreMessages = isOff ? undefined : compactMessages(ctx.ui.theme)
    ctx.ui.setFooter(isOff ? undefined : () => new EmptyFooter())
    ctx.ui.setHiddenThinkingLabel(isOff ? undefined : "")
    ctx.ui.setWorkingVisible(!isOff)
    applyToolDisplay()
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

  pi.on("agent_start", (_event, ctx) => {
    if (layout !== "off") ctx.ui.setWorkingVisible(false)
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
    if (layout !== "off") ctx.ui.setWorkingVisible(false)
  })

  pi.on("session_start", (event, ctx) => {
    stopped = false
    clearTerminalOnEditorMount = event.reason === "startup"
    layout = readLayout(ctx.cwd, ctx.isProjectTrusted()).layout
    toolDisplay = readToolDisplay(ctx.cwd, ctx.isProjectTrusted()).toolDisplay
    applySessionUI(ctx)
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
        if (clearTerminalOnEditorMount) {
          clearTerminalOnEditorMount = false
          instance.terminal.clearScreen()
          instance.requestRender(true)
        }
      }

      override render(width: number): string[] {
        if (layout === "off") {
          this.setPaddingX(1)
          return super.render(width)
        }
        const isMinimal = layout === "minimal"
        this.borderColor = isMinimal ? () => "" : this.defaultBorderColor
        this.setPaddingX(2)
        const lines = super.render(width)
        if (isMinimal) {
          const indicator = working
            ? ctx.ui.theme.fg("accent", spinnerFrames[spinnerFrame] ?? "")
            : ctx.ui.theme.fg("accent", "❯")
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
          return ["", ...lines.filter((line) => line !== "")]
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
    restoreMessages?.()
    restoreMessages = undefined
    removeToolDisplay()
    gitAbortController?.abort()
    gitAbortController = undefined
    stopSpinner()
    tui = undefined
  })
}
