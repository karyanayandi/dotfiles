import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
  type AgentToolResult,
  type EditToolDetails,
  type ExtensionAPI,
  type Theme,
  ToolExecutionComponent,
  type ToolDefinition,
} from "@earendil-works/pi-coding-agent"
import { Container, Text, type Component } from "@earendil-works/pi-tui"
import type { Static, TSchema } from "typebox"

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

export interface CompactCall {
  subject: string
  meta?: string
}

interface CompactToolState {
  line?: SingleLine
}

interface CompactRenderer<TParams extends TSchema, TDetails> {
  call: (args: Static<TParams>) => CompactCall
  summary?: (
    result: AgentToolResult<TDetails>,
    args: Static<TParams>,
  ) => string | undefined
  expanded?: (
    result: AgentToolResult<TDetails>,
    args: Static<TParams>,
    isError: boolean,
  ) => string
}

type ToolFactory<TParams extends TSchema, TDetails, TState> = (
  cwd: string,
) => ToolDefinition<TParams, TDetails, TState>

function renderLine(
  name: string,
  call: CompactCall,
  theme: Theme,
  state: { isPartial: boolean; isError: boolean },
  summary?: string,
): string {
  const status = state.isPartial
    ? theme.fg("muted", "·")
    : state.isError
      ? theme.fg("error", "✕")
      : theme.fg("success", "✓")
  let text = `${status} ${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", compactText(call.subject))}`
  if (call.meta) text += theme.fg("muted", ` ${compactText(call.meta, "")}`)
  if (summary)
    text += theme.fg(
      state.isError ? "error" : "muted",
      ` — ${compactText(summary, "")}`,
    )
  return text
}

function registerCompactTool<TParams extends TSchema, TDetails, TState>(
  pi: ExtensionAPI,
  factory: ToolFactory<TParams, TDetails, TState>,
  renderer: CompactRenderer<TParams, TDetails>,
  restores: Array<() => void>,
): void {
  const original = factory(process.cwd())
  restores.push(() => pi.registerTool(original))
  pi.registerTool<TParams, TDetails, CompactToolState>({
    ...original,
    renderShell: "self",
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return factory(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx)
    },
    renderCall(args, theme, context) {
      const state = { isError: context.isError, isPartial: context.isPartial }
      const line =
        context.lastComponent instanceof SingleLine
          ? context.lastComponent
          : new SingleLine("")
      context.state.line = line
      line.setText(renderLine(original.name, renderer.call(args), theme, state))
      return line
    },
    renderResult(result, { expanded }, theme, context) {
      const state = { isError: context.isError, isPartial: context.isPartial }
      const summary = context.isError
        ? errorSummary(result)
        : renderer.summary?.(result, context.args)
      context.state.line?.setText(
        renderLine(
          original.name,
          renderer.call(context.args),
          theme,
          state,
          summary,
        ),
      )

      if (!expanded) return new Container()
      const output =
        renderer.expanded?.(result, context.args, context.isError) ??
        expandedText(result)
      return output
        ? new Text(styleOutput(output, theme, context.isError), 0, 0)
        : new Container()
    },
  })
}

type CallRenderer = (args: unknown, theme: Theme, context: unknown) => Component

function patchDefaultCallRenderer(): () => void {
  const proto = ToolExecutionComponent.prototype as unknown as {
    getCallRenderer: () => CallRenderer | undefined
  }
  const original = proto.getCallRenderer
  const patched = function (this: ToolExecutionComponent) {
    const renderer = original.call(this)
    if (renderer) return renderer
    // Tools without a renderCall (MCP tools like ctx_*, web_search) only
    // show their bare name by default; add a compact args summary.
    const { toolName } = this as unknown as { toolName: string }
    return (args: unknown, theme: Theme): Component =>
      new Text(renderDefaultCall(toolName, args, theme), 0, 0)
  }
  proto.getCallRenderer = patched
  return () => {
    const current = ToolExecutionComponent.prototype as unknown as {
      getCallRenderer: () => CallRenderer | undefined
    }
    if (current.getCallRenderer === patched) current.getCallRenderer = original
  }
}

export function removeToolSpacing(): () => void {
  const originalRender = ToolExecutionComponent.prototype.render
  const compactRender = function (
    this: ToolExecutionComponent,
    width: number,
  ): string[] {
    const rendered = originalRender.call(this, width)

    const visibleAt = (line: string) => {
      const plain = line.replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")
      return plain.trim().length > 0
    }

    const firstVisible = rendered.findIndex(visibleAt)
    if (firstVisible === -1) return []

    // Show everything from the first visible line on, stripping the box
    // padding. Each renderer already handles its own collapse: compact
    // renderers return an empty Container when collapsed (so the single
    // status line remains), opencode renderers cap output/diff inline and
    // hide read-style results until Ctrl+O.
    let end = rendered.length
    while (end > firstVisible && !visibleAt(rendered[end - 1]!)) end--
    return rendered.slice(firstVisible, end)
  }
  ToolExecutionComponent.prototype.render = compactRender
  const restoreCallRenderer = patchDefaultCallRenderer()

  return () => {
    if (ToolExecutionComponent.prototype.render === compactRender) {
      ToolExecutionComponent.prototype.render = originalRender
    }
    restoreCallRenderer()
  }
}

function countDiff(details: EditToolDetails | undefined): string | undefined {
  if (!details?.diff) return undefined
  let additions = 0
  let removals = 0
  for (const line of details.diff.split("\n")) {
    if (line.startsWith("+") && !line.startsWith("+++")) additions++
    if (line.startsWith("-") && !line.startsWith("---")) removals++
  }
  return `+${additions} −${removals}`
}

export function registerCompactTools(pi: ExtensionAPI): Array<() => void> {
  const restores: Array<() => void> = []
  registerCompactTool(
    pi,
    createReadToolDefinition,
    {
      call: (args) => {
        const start = args.offset
        const end =
          start !== undefined && args.limit !== undefined
            ? start + args.limit - 1
            : undefined
        const range =
          start !== undefined
            ? `lines ${start}${end !== undefined ? `–${end}` : "+"}`
            : undefined
        return {
          subject: compactText(args.path),
          ...(range ? { meta: range } : {}),
        }
      },
      summary: (result) => {
        const count = lineCount(textOutput(result))
        return count > 0
          ? `${count} lines${result.details?.truncation?.truncated ? ", truncated" : ""}`
          : undefined
      },
    },
    restores,
  )

  registerCompactTool(
    pi,
    createBashToolDefinition,
    {
      call: (args) => ({
        subject: compactText(args.command),
        ...(args.timeout !== undefined
          ? { meta: `timeout ${args.timeout}s` }
          : {}),
      }),
    },
    restores,
  )

  registerCompactTool(
    pi,
    createEditToolDefinition,
    {
      call: (args) => ({
        subject: compactText(args.path),
        ...(Array.isArray(args.edits)
          ? {
              meta: `${args.edits.length} block${args.edits.length === 1 ? "" : "s"}`,
            }
          : {}),
      }),
      summary: (result) => countDiff(result.details),
      expanded: (result, _args, isError) =>
        isError
          ? expandedText(result)
          : (result.details?.diff ?? expandedText(result)),
    },
    restores,
  )

  registerCompactTool(
    pi,
    createWriteToolDefinition,
    {
      call: (args) => {
        const count =
          typeof args.content === "string" ? lineCount(args.content) : 0
        return {
          subject: compactText(args.path),
          ...(count > 0
            ? { meta: `${count} line${count === 1 ? "" : "s"}` }
            : {}),
        }
      },
      expanded: (result, args, isError) =>
        isError
          ? expandedText(result)
          : typeof args.content === "string"
            ? args.content
            : expandedText(result),
    },
    restores,
  )

  registerCompactTool(
    pi,
    createGrepToolDefinition,
    {
      call: (args) => {
        const path = compactText(args.path, ".")
        const glob = args.glob ? ` ${compactText(args.glob, "")}` : ""
        return {
          subject: `/${compactText(args.pattern, "")}/`,
          meta: `in ${path}${glob}`,
        }
      },
      summary: (result) => {
        const count = lineCount(textOutput(result))
        return count > 0 ? `${count} lines` : undefined
      },
    },
    restores,
  )

  registerCompactTool(
    pi,
    createFindToolDefinition,
    {
      call: (args) => ({
        subject: compactText(args.pattern),
        meta: `in ${compactText(args.path, ".")}`,
      }),
      summary: (result) => {
        const count = lineCount(textOutput(result))
        return count > 0 ? `${count} files` : undefined
      },
    },
    restores,
  )

  registerCompactTool(
    pi,
    createLsToolDefinition,
    {
      call: (args) => ({ subject: compactText(args.path, ".") }),
      summary: (result) => {
        const count = lineCount(textOutput(result))
        return count > 0 ? `${count} entries` : undefined
      },
    },
    restores,
  )
  return restores
}
