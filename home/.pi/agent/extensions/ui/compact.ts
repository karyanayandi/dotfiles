import {
  AssistantMessageComponent,
  UserMessageComponent,
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
  type ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent"
import {
  Container,
  Text,
  truncateToWidth,
  type Component,
} from "@earendil-works/pi-tui"

// Layout-conditional port of https://github.com/zackerydev/pi-minimalist-ui.
// Everything here renders the compact single-line style only when `getCompact()`
// is true (minimal/lite). In full/off layouts it transparently delegates back to
// pi's built-in renderers, so the current style is preserved.

const unsafeTerminalCharacters =
  /[\u0000-\u001f\u007f-\u009f\u202a-\u202e\u2066-\u2069]/g

function sanitizeTerminalText(text: string): string {
  return text.replace(unsafeTerminalCharacters, "�")
}

interface CompactCall {
  subject: string
  meta?: string
}

interface CompactRenderer<TDetails> {
  call: (args: any) => CompactCall
  summary?: (result: AgentToolResult<TDetails>, args: any) => string | undefined
  expanded?: (
    result: AgentToolResult<TDetails>,
    args: any,
    isError: boolean,
  ) => string
}

// The workspace ships two typebox builds (pi bundles 1.3.7, the root catalog
// resolves 1.3.11), so their `Static<T>` types are mutually unassignable. The
// original tool renderers are therefore captured with loose `any` signatures —
// the parameter types are compatible both directions, so no cast is needed.
type FallbackCall = (
  args: any,
  theme: Theme,
  context: any,
) => Component | undefined
type FallbackResult = (
  result: AgentToolResult<any>,
  options: ToolRenderResultOptions,
  theme: Theme,
  context: any,
) => Component | undefined

class SingleLine implements Component {
  constructor(private text: string) {}

  setText(text: string): void {
    this.text = text
  }

  render(width: number): string[] {
    return width > 0 ? [truncateToWidth(this.text, width, "…")] : []
  }

  invalidate(): void {}
}

function compactText(value: unknown, fallback = "…"): string {
  if (typeof value !== "string") return fallback
  const compact = value.replace(/\s+/g, " ").trim()
  return sanitizeTerminalText(compact) || fallback
}

function textOutput(result: AgentToolResult<unknown>): string {
  return result.content
    .flatMap((part) => (part.type === "text" ? [part.text] : []))
    .join("\n")
    .trimEnd()
}

function lineCount(text: string): number {
  return text ? text.split("\n").length : 0
}

function errorSummary(result: AgentToolResult<unknown>): string | undefined {
  const lines = textOutput(result)
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
  return lines.length > 0 ? compactText(lines.at(-1)) : undefined
}

function expandedText(result: AgentToolResult<unknown>): string {
  return textOutput(result)
}

function styleOutput(text: string, theme: Theme, isError: boolean): string {
  const color = isError ? "error" : "toolOutput"
  return text
    .split("\n")
    .map((line) => theme.fg(color, line))
    .join("\n")
}

// Status icon lives in the ToolExecutionComponent render patch so it applies
// uniformly to compact tools AND un-wrapped tools (fd/rg) alike.
function renderLine(
  name: string,
  call: CompactCall,
  theme: Theme,
  summary?: string,
): string {
  let text = `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", compactText(call.subject))}`
  if (call.meta) text += theme.fg("muted", ` ${compactText(call.meta, "")}`)
  if (summary) text += theme.fg("muted", ` — ${compactText(summary, "")}`)
  return text
}

function registerCompactTool(
  pi: ExtensionAPI,
  factory: (cwd: string) => ToolDefinition<any, any, any>,
  renderer: CompactRenderer<any>,
  getCompact: () => boolean,
): void {
  const original = factory(process.cwd())
  const originalCall: FallbackCall | undefined = original.renderCall
  const originalResult: FallbackResult | undefined = original.renderResult
  pi.registerTool({
    ...original,
    // read at render time so compact tools render through the clean self-shell in
    // minimal/lite but keep pi's background box in full/off (current style intact).
    get renderShell(): "self" | "default" {
      return getCompact() ? "self" : "default"
    },
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return factory(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx)
    },
    renderCall(args: any, theme: Theme, context: any) {
      if (!getCompact()) {
        return originalCall?.(args, theme, context) ?? new Text("", 0, 0)
      }
      const line =
        context.lastComponent instanceof SingleLine
          ? context.lastComponent
          : new SingleLine("")
      context.state.line = line
      line.setText(renderLine(original.name, renderer.call(args), theme))
      return line
    },
    renderResult(
      result: any,
      options: ToolRenderResultOptions,
      theme: Theme,
      context: any,
    ) {
      if (!getCompact()) {
        return (
          originalResult?.(result, options, theme, context) ?? new Container()
        )
      }
      const summary = context.isError
        ? errorSummary(result)
        : renderer.summary?.(result, context.args)
      context.state.line?.setText(
        renderLine(original.name, renderer.call(context.args), theme, summary),
      )

      if (!options.expanded) return new Container()
      const output =
        renderer.expanded?.(result, context.args, context.isError) ??
        expandedText(result)
      return output
        ? new Text(styleOutput(output, theme, context.isError), 0, 0)
        : new Container()
    },
  })
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

export function registerCompactTools(
  pi: ExtensionAPI,
  getCompact: () => boolean,
): void {
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
    getCompact,
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
    getCompact,
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
    getCompact,
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
    getCompact,
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
    getCompact,
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
    getCompact,
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
    getCompact,
  )
}

/**
 * Collapse each tool's transcript row to a single line in compact layouts.
 * This is what gives un-wrapped tools (fd, rg, every Task* tool, and other custom
 * tools) the pi-minimalist single-line look without re-registering them. When a
 * tool renders a short call+summary pair (exactly two content lines, e.g. fd/rg)
 * they are joined; otherwise only the call line is kept, augmented with the
 * call's args when the tool has no custom renderer (bare-name fallback). Never
 * touches the file-search or tasks extensions.
 */
export function installToolSpacing(
  getCompact: () => boolean,
  theme: Theme,
): () => void {
  const originalRender = ToolExecutionComponent.prototype.render
  const compactRender = function (
    this: ToolExecutionComponent,
    width: number,
  ): string[] {
    const rendered = originalRender.call(this, width)
    if (!getCompact()) return rendered
    const self = this as unknown as {
      expanded: boolean
      isPartial: boolean
      toolName?: string
      args?: unknown
      result?: { isError?: boolean }
      getRenderShell: () => string | undefined
    }
    if (self.expanded) return rendered
    if (width <= 0) return []

    const content = rendered.filter((line) => line !== "")
    if (content.length === 0) return []

    // Compact (re-registered) tools use renderShell "self" and emit a clean
    // single colored line. fd/rg, Task* and other custom tools keep pi's default
    // shell, where a Box wraps each line in full-width background padding — strip
    // that before collapsing so the row reads like a compact tool row.
    const isBgShell = self.getRenderShell() !== "self"
    const lines = isBgShell
      ? content
          .map((line) => plainTerminalText(line).trim())
          .filter((l) => l !== "")
      : content
    if (lines.length === 0) return []

    // Tools with no custom renderCall fall back to a bare-name line. For those
    // (all Task* tools) append a compact args digest so the row stays useful.
    const bareName = self.toolName ? sanitizeTerminalText(self.toolName) : ""
    const firstPlain = plainTerminalText(lines[0] ?? "").trim()
    const args =
      bareName !== "" && firstPlain === bareName
        ? compactArgs(self.args, theme)
        : ""

    // A short call + result summary pair (e.g. fd/rg) is joined; a lone call
    // line stays as-is. Longer output keeps only the call line.
    const single =
      (lines.length <= 2 ? lines.join(" · ") : (lines[0] ?? "")) +
      (args ? ` ${args}` : "")
    const status = self.result?.isError
      ? theme.fg("error", "✕")
      : self.isPartial
        ? theme.fg("muted", "·")
        : theme.fg("success", "✓")
    const line = truncateToWidth(`${status} ${single}`, width, "…")
    return [line]
  }
  ToolExecutionComponent.prototype.render = compactRender
  return () => {
    if (ToolExecutionComponent.prototype.render === compactRender) {
      ToolExecutionComponent.prototype.render = originalRender
    }
  }
}

function compactArgs(args: unknown, theme: Theme): string {
  if (!args || typeof args !== "object" || Array.isArray(args)) return ""
  const parts: string[] = []
  for (const [key, value] of Object.entries(args as Record<string, unknown>)) {
    if (value === undefined || value === null || value === "") continue
    const val =
      typeof value === "string"
        ? compactText(value, "")
        : Array.isArray(value)
          ? value.length > 1
            ? `[${value.length}]`
            : compactText(String(value[0] ?? ""), "")
          : typeof value === "object"
            ? ""
            : String(value)
    if (!val) continue
    parts.push(
      `${theme.fg("muted", compactText(key))}:${theme.fg("accent", val)}`,
    )
  }
  return parts.join(" ")
}

// --- compact message rendering ---

const unsafeMessageCharacters =
  /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f-\u009f\u202a-\u202e\u2066-\u2069]/g

function sanitizeMessageText(text: string): string {
  return text.replace(unsafeMessageCharacters, "�")
}

function plainTerminalText(text: string): string {
  return text.replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")
}

interface TextState {
  text: string
}

interface UserMessageState {
  text: string
}

interface AssistantMessageState {
  hiddenThinkingLabel: string
  hideThinkingBlock: boolean
  lastMessage?: {
    content: Array<{ thinking?: string; text?: string; type: string }>
    errorMessage?: string
    stopReason: string
  }
}

export function installCompactMessages(
  theme: Theme,
  getCompact: () => boolean,
): () => void {
  const originalTextRender = Text.prototype.render
  const compactTextRender = function (this: Text, width: number): string[] {
    if (!getCompact()) return originalTextRender.call(this, width)
    const { text } = this as unknown as TextState
    if (plainTerminalText(text).startsWith("Thinking level: ")) return []
    return originalTextRender.call(this, width)
  }
  Text.prototype.render = compactTextRender

  const originalUserRender = UserMessageComponent.prototype.render
  const compactUserRender = function (
    this: UserMessageComponent,
    width: number,
  ): string[] {
    if (!getCompact()) return originalUserRender.call(this, width)
    const { text } = this as unknown as UserMessageState
    const content = theme.fg("dim", `› ${sanitizeMessageText(text)}`)
    return new Text(content, 0, 0).render(width)
  }
  UserMessageComponent.prototype.render = compactUserRender

  const originalAssistantRender = AssistantMessageComponent.prototype.render
  const compactAssistantRender = function (
    this: AssistantMessageComponent,
    width: number,
  ): string[] {
    if (!getCompact()) return originalAssistantRender.call(this, width)
    const { hiddenThinkingLabel, hideThinkingBlock, lastMessage } =
      this as unknown as AssistantMessageState
    const hasToolCalls =
      lastMessage?.content.some((part) => part.type === "toolCall") ?? false
    const hasThinking =
      lastMessage?.content.some(
        (part) => part.type === "thinking" && part.thinking?.trim(),
      ) ?? false
    const hasText =
      lastMessage?.content.some(
        (part) => part.type === "text" && part.text?.trim(),
      ) ?? false
    if (
      hasToolCalls &&
      hasThinking &&
      !hasText &&
      hideThinkingBlock &&
      !hiddenThinkingLabel
    )
      return []
    if (lastMessage?.stopReason !== "aborted" || hasToolCalls) {
      return originalAssistantRender.call(this, width)
    }

    const message =
      lastMessage.errorMessage &&
      lastMessage.errorMessage !== "Request was aborted"
        ? lastMessage.errorMessage
        : "Operation aborted"
    return new Text(
      theme.fg("error", sanitizeMessageText(message)),
      0,
      0,
    ).render(width)
  }
  AssistantMessageComponent.prototype.render = compactAssistantRender

  return () => {
    if (Text.prototype.render === compactTextRender) {
      Text.prototype.render = originalTextRender
    }
    if (UserMessageComponent.prototype.render === compactUserRender) {
      UserMessageComponent.prototype.render = originalUserRender
    }
    if (AssistantMessageComponent.prototype.render === compactAssistantRender) {
      AssistantMessageComponent.prototype.render = originalAssistantRender
    }
  }
}
