// Demo diff marker — harmless comment to show edit styling
import {
  type AgentToolResult,
  type ExtensionAPI,
  type Theme,
  type ToolDefinition,
} from "@earendil-works/pi-coding-agent"
import { Container, Text } from "@earendil-works/pi-tui"

import {
  compactText,
  errorSummary,
  expandedText,
  lineCount,
  renderDefaultCall,
  SingleLine,
  styleOutput,
  textOutput,
} from "./helpers.js"
import { taskToolDefinitions } from "../tasks/index.js"

const TASK_TOOL_NAMES = new Set([
  "TaskCreate",
  "TaskList",
  "TaskGet",
  "TaskUpdate",
  "TaskOutput",
  "TaskStop",
  "TaskExecute",
])

type TaskDisplayMode = "off" | "minimal" | "opencode"

let taskDisplayMode: TaskDisplayMode = "off"

interface TaskToolState {
  line?: SingleLine
}

type TaskArgs = Record<string, unknown>

function getTaskId(args: TaskArgs): string {
  return compactText(
    (args.taskId as string | undefined) ??
      (args.task_id as string | undefined) ??
      (args.shell_id as string | undefined) ??
      "",
    "…",
  )
}

function taskCall(
  name: string,
  args: TaskArgs,
): { subject: string; meta?: string } {
  switch (name) {
    case "TaskCreate": {
      const subject = compactText(args.subject as string | undefined)
      const agentType = compactText(args.agentType as string | undefined, "")
      return {
        subject: subject || "create task",
        ...(agentType ? { meta: `agent ${agentType}` } : {}),
      }
    }
    case "TaskList":
      return { subject: "list tasks" }
    case "TaskGet":
      return { subject: `#${getTaskId(args)}` }
    case "TaskUpdate": {
      const status = compactText(args.status as string | undefined, "")
      return {
        subject: `#${getTaskId(args)}`,
        ...(status ? { meta: `→ ${status}` } : {}),
      }
    }
    case "TaskOutput": {
      const block = args.block as boolean | undefined
      return {
        subject: `#${getTaskId(args)}`,
        ...(block === false ? { meta: "async" } : {}),
      }
    }
    case "TaskStop":
      return { subject: `#${getTaskId(args)}` }
    case "TaskExecute": {
      const ids = args.task_ids
      const count = Array.isArray(ids) ? ids.length : 0
      return {
        subject: `${count} task${count === 1 ? "" : "s"}`,
        ...(args.model ? { meta: `model ${args.model}` } : {}),
      }
    }
    default:
      return { subject: "" }
  }
}

function taskResultSummary(
  name: string,
  result: AgentToolResult<unknown>,
): string | undefined {
  if (name === "TaskCreate") {
    const match = textOutput(result).match(/Task #(\d+) created successfully/)
    if (match?.[1]) return `#${match[1]} created`
  }
  if (name === "TaskList") {
    const lines = lineCount(textOutput(result))
    return lines === 0 ? "no tasks" : `${lines} task${lines === 1 ? "" : "s"}`
  }
  if (name === "TaskGet") {
    const match = textOutput(result).match(/Status: (\S+)/)
    if (match?.[1]) return `[${match[1]}]`
  }
  if (name === "TaskUpdate") {
    const match = textOutput(result).match(/Updated task #(\d+) status/)
    if (match?.[1]) return `#${match[1]} updated`
  }
  if (name === "TaskExecute") {
    const out = textOutput(result)
    const match = out.match(/Launched (\d+) agent/)
    if (match?.[1])
      return `launched ${match[1]} agent${match[1] === "1" ? "" : "s"}`
    if (out.includes("No tasks to execute.")) return "no tasks to execute"
  }
  return undefined
}

function renderCompactTaskLine(
  name: string,
  call: ReturnType<typeof taskCall>,
  theme: Theme,
  isPartial: boolean,
  isError: boolean,
  summary?: string,
): string {
  const status = isPartial
    ? theme.fg("muted", "·")
    : isError
      ? theme.fg("error", "✕")
      : theme.fg("success", "✓")
  let text = `${status} ${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", compactText(call.subject))}`
  if (call.meta) text += theme.fg("muted", ` ${compactText(call.meta, "")}`)
  if (summary)
    text += theme.fg(
      isError ? "error" : "muted",
      ` — ${compactText(summary, "")}`,
    )
  return text
}

function renderOpenCodeTaskLine(
  name: string,
  call: ReturnType<typeof taskCall>,
  theme: Theme,
): string {
  let text = `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", compactText(call.subject))}`
  if (call.meta) text += theme.fg("muted", ` ${compactText(call.meta, "")}`)
  return text
}

function renderCompactResult(
  original: ToolDefinition,
  result: AgentToolResult<unknown>,
  theme: Theme,
  context: {
    isPartial: boolean
    isError: boolean
    args: TaskArgs
    state: TaskToolState
  },
): string {
  const summary = context.isError
    ? errorSummary(result)
    : taskResultSummary(original.name, result)
  const call = taskCall(original.name, context.args)
  return renderCompactTaskLine(
    original.name,
    call,
    theme,
    context.isPartial,
    context.isError,
    summary,
  )
}

const TASK_COLLAPSED_LINES = 6

function renderCollapsedOutput(
  output: string,
  theme: Theme,
  expanded: boolean,
  isError: boolean,
): string {
  const lines = output.split("\n").filter((line) => line.trimEnd())
  const shown = expanded ? lines : lines.slice(0, TASK_COLLAPSED_LINES)
  const color = isError ? "error" : "toolOutput"
  let text = shown
    .map((line) => theme.fg(color, compactText(line, "")))
    .join("\n")
  if (!expanded && lines.length > TASK_COLLAPSED_LINES)
    text += `\n${theme.fg("muted", `... (${lines.length - TASK_COLLAPSED_LINES} more lines • Ctrl+O to expand)`)}`
  return text
}

function renderOpenCodeResult(
  original: ToolDefinition,
  result: AgentToolResult<unknown>,
  options: { expanded: boolean },
  theme: Theme,
  context: { isError: boolean; args: TaskArgs },
): string {
  if (context.isError) {
    const summary = errorSummary(result)
    const output = expandedText(result)
    let text = theme.fg("error", summary ? `↳ failed — ${summary}` : "↳ failed")
    if (output && options.expanded)
      text += `\n${styleOutput(output, theme, true)}`
    return text
  }

  const summary = taskResultSummary(original.name, result)
  const output = expandedText(result)
  if (!options.expanded) {
    return summary ? theme.fg("muted", `↳ ${summary}`) : ""
  }
  if (!output) return summary ? theme.fg("muted", `↳ ${summary}`) : ""
  return renderCollapsedOutput(output, theme, options.expanded, false)
}

export function setTaskDisplayMode(mode: TaskDisplayMode): void {
  taskDisplayMode = mode
}

export function installTaskToolPatch(pi: ExtensionAPI): () => void {
  const originalRegisterTool = pi.registerTool.bind(pi)
  const wrappedRegisterTool = (def: ToolDefinition) => {
    if (!TASK_TOOL_NAMES.has(def.name)) {
      return originalRegisterTool(def)
    }

    const wrapped: ToolDefinition = {
      ...def,
      renderShell: "self",
      renderCall(args, theme, context) {
        if (taskDisplayMode === "off") {
          return (
            def.renderCall?.(args, theme, context) ??
            new Text(renderDefaultCall(def.name, args, theme), 0, 0)
          )
        }
        const call = taskCall(def.name, args as TaskArgs)
        const text =
          taskDisplayMode === "opencode"
            ? renderOpenCodeTaskLine(def.name, call, theme)
            : renderCompactTaskLine(
                def.name,
                call,
                theme,
                context.isPartial,
                context.isError,
              )
        const line =
          context.lastComponent instanceof SingleLine
            ? context.lastComponent
            : new SingleLine("")
        ;(context.state as TaskToolState).line = line
        line.setText(text)
        return line
      },
      renderResult(result, options, theme, context) {
        if (taskDisplayMode === "off") {
          if (def.renderResult) {
            return def.renderResult(result, options, theme, context)
          }
          const output = expandedText(result)
          return output
            ? new Text(styleOutput(output, theme, context.isError), 0, 0)
            : new Container()
        }
        if (taskDisplayMode === "minimal") {
          const state = context.state as TaskToolState
          state.line?.setText(
            renderCompactResult(def, result, theme, {
              isPartial: context.isPartial,
              isError: context.isError,
              args: context.args as TaskArgs,
              state,
            }),
          )
          if (!options.expanded) return new Container()
          const output = expandedText(result)
          return output
            ? new Text(styleOutput(output, theme, context.isError), 0, 0)
            : new Container()
        }
        // opencode
        const text = renderOpenCodeResult(def, result, options, theme, {
          isError: context.isError,
          args: context.args as TaskArgs,
        })
        return text ? new Text(text, 0, 0) : new Container()
      },
    }

    return originalRegisterTool(wrapped)
  }
  pi.registerTool = wrappedRegisterTool as typeof pi.registerTool

  // Re-register already-loaded task tools so the patch wraps them too.
  for (const def of taskToolDefinitions) {
    wrappedRegisterTool(def)
  }

  return () => {
    if (pi.registerTool === wrappedRegisterTool) {
      pi.registerTool = originalRegisterTool
    }
  }
}
