import { readFileSync } from "node:fs"
import { isAbsolute, join } from "node:path"
import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
  formatSize,
  type AgentToolResult,
  type ExtensionAPI,
  type Theme,
  type ToolDefinition,
  type ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent"
import { Container, Text, type Component } from "@earendil-works/pi-tui"
import type { Static, TSchema } from "typebox"

import { renderDiffText, renderWriteDiffText, parseDiff } from "./diff.js"
import { sanitizeTerminalText } from "./layout.js"
import {
  compactText,
  errorSummary,
  lineCount,
  SingleLine,
  styleOutput,
  textOutput,
} from "./tools.js"

const BASH_COLLAPSED_LINES = 10
const BASH_SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
const BASH_SPINNER_INTERVAL_MS = 200

const QUIET_COMMAND_PREFIXES = [
  "cd",
  "mkdir",
  "rmdir",
  "rm",
  "mv",
  "cp",
  "touch",
  "chmod",
  "chown",
  "git add",
  "git checkout",
  "git switch",
  "git restore",
  "git reset",
  "git clean",
  "git fetch",
  "git pull",
  "git push",
  "git stash",
  "git status",
  "git log",
  "npm install",
  "pnpm install",
  "yarn install",
  "bun install",
  "pip install",
  "poetry install",
  "cargo fetch",
  "go mod tidy",
  "Set-Location",
  "New-Item",
  "Remove-Item",
  "Move-Item",
  "Copy-Item",
]

interface OpenCodeCall {
  subject: string
  meta?: string
}

interface BashSpinnerState {
  frame: number
  startedAt?: number
  timer?: ReturnType<typeof setInterval>
}

interface OpenCodeToolState {
  line?: SingleLine
  spinner?: BashSpinnerState
}

interface RenderContext<TArgs = unknown> {
  args: TArgs
  toolCallId: string
  invalidate: () => void
  lastComponent: Component | undefined
  state: OpenCodeToolState
  cwd: string
  executionStarted: boolean
  argsComplete: boolean
  isPartial: boolean
  expanded: boolean
  showImages: boolean
  isError: boolean
}

interface OpenCodeRenderer<TParams extends TSchema, TDetails> {
  call: (args: Static<TParams>) => OpenCodeCall
  callComponent?: (
    args: Static<TParams>,
    theme: Theme,
    context: RenderContext<Static<TParams>>,
  ) => Component
  result: (
    result: AgentToolResult<TDetails>,
    options: ToolRenderResultOptions,
    theme: Theme,
    context: RenderContext<Static<TParams>>,
  ) => Component
  beforeExecute?: (
    toolCallId: string,
    params: Static<TParams>,
    cwd: string,
  ) => void
}

type ToolFactory<TParams extends TSchema, TDetails, TState> = (
  cwd: string,
) => ToolDefinition<TParams, TDetails, TState>

const activeTimers = new Set<ReturnType<typeof setInterval>>()

function stopSpinner(state: BashSpinnerState | undefined): void {
  if (!state) return
  if (state.timer) {
    clearInterval(state.timer)
    activeTimers.delete(state.timer)
    state.timer = undefined
  }
  state.frame = 0
  state.startedAt = undefined
}

function formatElapsed(elapsedMs: number): string {
  const totalSeconds = Math.max(0, Math.floor(elapsedMs / 1000))
  if (totalSeconds < 60) return `${totalSeconds}s`
  const totalMinutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  if (totalMinutes < 60) return `${totalMinutes}m ${seconds}s`
  const hours = Math.floor(totalMinutes / 60)
  return `${hours}h ${totalMinutes % 60}m`
}

function openCodeCallLine(
  name: string,
  call: OpenCodeCall,
  theme: Theme,
): string {
  let text = `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", compactText(call.subject))}`
  if (call.meta) text += theme.fg("muted", ` ${compactText(call.meta, "")}`)
  return text
}

function buildBashCallText(
  command: string,
  timeout: number | undefined,
  theme: Theme,
  spinnerFrame?: string,
  elapsedMs?: number,
): string {
  let text = ""
  if (spinnerFrame) text += theme.fg("warning", `${spinnerFrame} `)
  text += `${theme.fg("toolTitle", theme.bold("$"))} ${theme.fg("accent", compactText(command))}`
  if (timeout !== undefined) text += theme.fg("muted", ` (timeout ${timeout}s)`)
  if (spinnerFrame && elapsedMs !== undefined)
    text += theme.fg("muted", ` · ${formatElapsed(elapsedMs)}`)
  return text
}

function renderBashCallComponent(
  args: { command: string; timeout?: number },
  theme: Theme,
  context: RenderContext<{ command: string; timeout?: number }>,
): SingleLine {
  const line =
    context.lastComponent instanceof SingleLine
      ? context.lastComponent
      : new SingleLine("")
  context.state.line = line
  const shouldSpin = context.executionStarted && context.isPartial

  if (!shouldSpin) {
    stopSpinner(context.state.spinner)
    context.state.spinner = undefined
    line.setText(buildBashCallText(args.command, args.timeout, theme))
    return line
  }

  let spinner = context.state.spinner
  if (!spinner) {
    spinner = { frame: 0 }
    context.state.spinner = spinner
  }
  spinner.startedAt ??= Date.now()
  if (!spinner.timer) {
    spinner.timer = setInterval(() => {
      spinner.frame = (spinner.frame + 1) % BASH_SPINNER_FRAMES.length
      const frame = BASH_SPINNER_FRAMES[spinner.frame]
      const startedAt = spinner.startedAt
      if (frame && startedAt !== undefined) {
        line.setText(
          buildBashCallText(
            args.command,
            args.timeout,
            theme,
            frame,
            Date.now() - startedAt,
          ),
        )
        context.invalidate()
      }
    }, BASH_SPINNER_INTERVAL_MS)
    activeTimers.add(spinner.timer)
  }
  const frame = BASH_SPINNER_FRAMES[spinner.frame]
  const startedAt = spinner.startedAt
  line.setText(
    buildBashCallText(
      args.command,
      args.timeout,
      theme,
      frame,
      startedAt !== undefined ? Date.now() - startedAt : undefined,
    ),
  )
  return line
}

function isLikelyQuietCommand(command: string | undefined): boolean {
  if (!command) return false
  const normalized = command.trim().toLowerCase()
  if (!normalized) return false
  const primary = normalized
    .split(/&&|\|\||;/)
    .map((segment) => segment.trim())
    .find((segment) => segment.length > 0)
  if (!primary) return false
  return QUIET_COMMAND_PREFIXES.some(
    (prefix) => primary === prefix || primary.startsWith(`${prefix} `),
  )
}

function collapsedOutput(
  lines: string[],
  theme: Theme,
  expanded: boolean,
  maxLines: number,
): string {
  const shown = expanded ? lines : lines.slice(0, maxLines)
  let text = shown
    .map((line) => theme.fg("toolOutput", sanitizeTerminalText(line)))
    .join("\n")
  if (!expanded && lines.length > maxLines)
    text += `\n${theme.fg("muted", `... (${lines.length - maxLines} more lines • Ctrl+O to expand)`)}`
  return text
}

function renderBashResult(
  result: AgentToolResult<unknown>,
  options: ToolRenderResultOptions,
  theme: Theme,
  context: RenderContext<{ command: string; timeout?: number }>,
): Component {
  stopSpinner(context.state.spinner)
  context.state.spinner = undefined
  context.state.line?.setText(
    buildBashCallText(context.args.command, context.args.timeout, theme),
  )

  const rawOutput = textOutput(result)
  const lines = rawOutput
    ? rawOutput.split("\n").map((line) => line.trimEnd())
    : []

  if (context.isError) {
    let text = theme.fg("error", "↳ command failed")
    if (lines.length > 0) {
      const shown = options.expanded
        ? lines
        : lines.slice(0, BASH_COLLAPSED_LINES)
      text += `\n${shown.map((line) => theme.fg("error", sanitizeTerminalText(line))).join("\n")}`
      if (!options.expanded && lines.length > BASH_COLLAPSED_LINES)
        text += `\n${theme.fg("muted", `... (${lines.length - BASH_COLLAPSED_LINES} more lines • Ctrl+O to expand)`)}`
    }
    return new Text(text, 0, 0)
  }

  if (lines.length === 0) {
    const quiet = isLikelyQuietCommand(context.args.command)
    return new Text(
      theme.fg(
        "muted",
        quiet ? "↳ command completed (no output)" : "↳ (no output)",
      ),
      0,
      0,
    )
  }
  return new Text(
    collapsedOutput(lines, theme, options.expanded, BASH_COLLAPSED_LINES),
    0,
    0,
  )
}

function renderHiddenResult(
  result: AgentToolResult<unknown>,
  options: ToolRenderResultOptions,
  theme: Theme,
  context: RenderContext<unknown>,
  partialLabel: string,
): Component {
  if (options.isPartial)
    return new Text(theme.fg("warning", partialLabel), 0, 0)
  if (!options.expanded) return new Container()
  const output = textOutput(result)
  return output
    ? new Text(styleOutput(output, theme, context.isError), 0, 0)
    : new Container()
}

function editLineCount(edits: Array<{ newText: string }> | undefined): number {
  if (!Array.isArray(edits)) return 0
  return edits.reduce(
    (total, edit) =>
      total + (typeof edit.newText === "string" ? lineCount(edit.newText) : 0),
    0,
  )
}

function registerOpenCodeTool<TParams extends TSchema, TDetails, TState>(
  pi: ExtensionAPI,
  factory: ToolFactory<TParams, TDetails, TState>,
  renderer: OpenCodeRenderer<TParams, TDetails>,
  restores: Array<() => void>,
): void {
  const original = factory(process.cwd())
  restores.push(() => pi.registerTool(original))
  pi.registerTool<TParams, TDetails, OpenCodeToolState>({
    ...original,
    renderShell: "self",
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      renderer.beforeExecute?.(toolCallId, params, ctx.cwd)
      return factory(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx)
    },
    renderCall(args, theme, context) {
      if (renderer.callComponent)
        return renderer.callComponent(
          args as never,
          theme,
          context as never,
        ) as Component
      return new SingleLine(
        openCodeCallLine(original.name, renderer.call(args), theme),
      )
    },
    renderResult(result, options, theme, context) {
      return renderer.result(result as never, options, theme, context as never)
    },
  })
}

function captureWriteMeta(
  cwd: string,
  path: string,
): { existed: boolean; content?: string } {
  const absolute = isAbsolute(path) ? path : join(cwd, path)
  try {
    return { existed: true, content: readFileSync(absolute, "utf8") }
  } catch {
    return { existed: false }
  }
}

export function registerOpenCodeTools(pi: ExtensionAPI): Array<() => void> {
  const restores: Array<() => void> = []
  const clearTimers = () => {
    for (const timer of activeTimers) clearInterval(timer)
    activeTimers.clear()
  }
  restores.push(clearTimers)

  registerOpenCodeTool(
    pi,
    createReadToolDefinition,
    {
      call: (args) => {
        const suffix =
          args.offset !== undefined || args.limit !== undefined
            ? `:${args.offset ?? 1}${args.limit !== undefined ? `–${(args.offset ?? 1) + args.limit - 1}` : ""}`
            : undefined
        return {
          subject: compactText(args.path),
          ...(suffix ? { meta: suffix } : {}),
        }
      },
      result: (result, options, theme, context) =>
        renderHiddenResult(result, options, theme, context, "reading..."),
    },
    restores,
  )

  registerOpenCodeTool(
    pi,
    createBashToolDefinition,
    {
      call: (args) => ({ subject: compactText(args.command) }),
      callComponent: renderBashCallComponent,
      result: renderBashResult,
    },
    restores,
  )

  registerOpenCodeTool(
    pi,
    createEditToolDefinition,
    {
      call: (args) => {
        const count = editLineCount(args.edits)
        return {
          subject: compactText(args.path),
          ...(count > 0
            ? { meta: `(${count} line${count === 1 ? "" : "s"})` }
            : {}),
        }
      },
      result: (result, options, theme, context) => {
        if (context.isError) {
          const summary = errorSummary(result)
          return new Text(
            theme.fg(
              "error",
              summary ? `↳ edit failed — ${summary}` : "↳ edit failed",
            ),
            0,
            0,
          )
        }
        const diff = result.details?.diff
        if (diff)
          return new Text(
            renderDiffText(parseDiff(diff), theme, options.expanded),
            0,
            0,
          )
        return renderHiddenResult(result, options, theme, context, "editing...")
      },
    },
    restores,
  )

  const writeMeta = new Map<string, { existed: boolean; content?: string }>()
  registerOpenCodeTool(
    pi,
    createWriteToolDefinition,
    {
      call: (args) => {
        const count =
          typeof args.content === "string" ? lineCount(args.content) : 0
        const size = typeof args.content === "string" ? args.content.length : 0
        return {
          subject: compactText(args.path),
          ...(count > 0
            ? {
                meta: `(${count} line${count === 1 ? "" : "s"} • ${formatSize(size)})`,
              }
            : {}),
        }
      },
      beforeExecute: (toolCallId, params, cwd) => {
        writeMeta.delete(toolCallId)
        if (typeof params.path === "string" && params.path)
          writeMeta.set(toolCallId, captureWriteMeta(cwd, params.path))
      },
      result: (result, options, theme, context) => {
        if (context.isError) {
          const summary = errorSummary(result)
          return new Text(
            theme.fg(
              "error",
              summary ? `↳ write failed — ${summary}` : "↳ write failed",
            ),
            0,
            0,
          )
        }
        const meta = writeMeta.get(context.toolCallId)
        const content =
          typeof context.args?.content === "string" ? context.args.content : ""
        return new Text(
          renderWriteDiffText(
            content,
            meta?.content,
            meta?.existed ?? false,
            theme,
            options.expanded,
          ),
          0,
          0,
        )
      },
    },
    restores,
  )

  registerOpenCodeTool(
    pi,
    createGrepToolDefinition,
    {
      call: (args) => ({
        subject: `/${compactText(args.pattern, "")}/`,
        meta: `in ${compactText(args.path, ".")}`,
      }),
      result: (result, options, theme, context) =>
        renderHiddenResult(result, options, theme, context, "running..."),
    },
    restores,
  )

  registerOpenCodeTool(
    pi,
    createFindToolDefinition,
    {
      call: (args) => ({
        subject: compactText(args.pattern),
        meta: `in ${compactText(args.path, ".")}`,
      }),
      result: (result, options, theme, context) =>
        renderHiddenResult(result, options, theme, context, "running..."),
    },
    restores,
  )

  registerOpenCodeTool(
    pi,
    createLsToolDefinition,
    {
      call: (args) => ({ subject: compactText(args.path, ".") }),
      result: (result, options, theme, context) =>
        renderHiddenResult(result, options, theme, context, "running..."),
    },
    restores,
  )

  return restores
}
