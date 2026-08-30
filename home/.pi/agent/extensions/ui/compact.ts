import {
  AssistantMessageComponent,
  UserMessageComponent,
  createBashToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  type AgentToolResult,
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
  wrapTextWithAnsi,
  type Component,
} from "@earendil-works/pi-tui"

// Left gutter for compact tool rows and user prompts.
const COMPACT_INDENT = "  "
// Gutter reserved on the first row of a tool call: indent + status + space.
// Long call text wraps to the next line instead of being truncated.
const CALL_GUTTER = COMPACT_INDENT.length + 2 // "  " + "✓ " = 4

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

function withMeta(subject: string, meta?: string): CompactCall {
  return meta ? { subject, meta } : { subject }
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

type ToolRender = ToolExecutionComponent["render"]

interface PatchableToolExecutionPrototype {
  render: ToolRender
  __piUiToolSpacingOriginalRender?: ToolRender
  __piUiToolSpacingPatched?: boolean
  __piUiToolSpacingPatchVersion?: number
  __piUiToolSpacingPatchOwner?: object
}

const TOOL_SPACING_PATCH_VERSION = 1
const TOOL_SPACING_PATCH_OWNER = {}

function getToolExecutionPrototype() {
  return ToolExecutionComponent.prototype as unknown as PatchableToolExecutionPrototype
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
    return width > 0
      ? wrapTextWithAnsi(this.text, Math.max(1, width - CALL_GUTTER))
      : []
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

function countSummary(
  result: AgentToolResult<unknown>,
  label: string,
): string | undefined {
  const count = lineCount(textOutput(result))
  return count > 0 ? `${count} ${label}` : undefined
}

function errorSummary(result: AgentToolResult<unknown>): string | undefined {
  const lines = textOutput(result)
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
  return lines.length > 0 ? compactText(lines.at(-1)) : undefined
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
      // Tools collapse to a single compact line.
      const summary = context.isError
        ? errorSummary(result)
        : renderer.summary?.(result, context.args)
      context.state.line?.setText(
        renderLine(original.name, renderer.call(context.args), theme, summary),
      )

      if (!options.expanded) return new Container()
      const output =
        renderer.expanded?.(result, context.args, context.isError) ??
        textOutput(result)
      return output
        ? new Text(styleOutput(output, theme, context.isError), 0, 0)
        : new Container()
    },
  })
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
        let range: string | undefined
        if (start !== undefined) {
          range =
            end !== undefined ? `lines ${start}–${end}` : `lines ${start}+`
        }
        return withMeta(compactText(args.path), range)
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
      call: (args) =>
        withMeta(
          compactText(args.command),
          args.timeout !== undefined ? `timeout ${args.timeout}s` : undefined,
        ),
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
        return withMeta(
          `/${compactText(args.pattern, "")}/`,
          `in ${path}${glob}`,
        )
      },
      summary: (result) => countSummary(result, "lines"),
    },
    getCompact,
  )

  registerCompactTool(
    pi,
    createFindToolDefinition,
    {
      call: (args) =>
        withMeta(
          compactText(args.pattern),
          `in ${compactText(args.path, ".")}`,
        ),
      summary: (result) => countSummary(result, "files"),
    },
    getCompact,
  )

  registerCompactTool(
    pi,
    createLsToolDefinition,
    {
      call: (args) => withMeta(compactText(args.path, ".")),
      summary: (result) => countSummary(result, "entries"),
    },
    getCompact,
  )
}

/**
 * Collapse each tool's transcript row to a single line in compact layouts.
 * This is what gives un-wrapped custom tools the pi-minimalist single-line look
 * without re-registering them. When a
 * tool renders a short call+summary pair (exactly two content lines, e.g. fd/rg)
 * they are joined; otherwise only the call line is kept, augmented with the
 * call's args when the tool has no custom renderer (bare-name fallback). Never
 * touches the file-search extension.
 */
export function installToolSpacing(
  getCompact: () => boolean,
  theme: Theme,
): () => void {
  const prototype = getToolExecutionPrototype()
  const previousOriginalRender = prototype.__piUiToolSpacingOriginalRender
  const hasPreviousPatch =
    typeof previousOriginalRender === "function" &&
    previousOriginalRender !== prototype.render
  const isCurrentPatch =
    prototype.__piUiToolSpacingPatchOwner === TOOL_SPACING_PATCH_OWNER
  let restoredStalePatch = false

  // Session reloads can load a fresh copy of this module before old patch
  // state has been cleaned up. Restore that wrapper before installing one.
  if (hasPreviousPatch && !isCurrentPatch) {
    prototype.render = previousOriginalRender
    delete prototype.__piUiToolSpacingOriginalRender
    delete prototype.__piUiToolSpacingPatched
    delete prototype.__piUiToolSpacingPatchVersion
    delete prototype.__piUiToolSpacingPatchOwner
    restoredStalePatch = true
  }

  // Multiple UI extension instances may share one prototype. Keep one wrapper;
  // stacking it is what turns one status icon into a row of check marks.
  if (
    !restoredStalePatch &&
    prototype.__piUiToolSpacingPatched &&
    prototype.__piUiToolSpacingPatchVersion === TOOL_SPACING_PATCH_VERSION &&
    typeof prototype.__piUiToolSpacingOriginalRender === "function"
  ) {
    return () => {}
  }

  if (!prototype.__piUiToolSpacingOriginalRender) {
    prototype.__piUiToolSpacingOriginalRender = prototype.render
  }
  const originalRender = prototype.__piUiToolSpacingOriginalRender
  if (!originalRender) return () => {}

  const compactRender = function (
    this: ToolExecutionComponent,
    width: number,
  ): string[] {
    const rendered = originalRender.call(this, width)
    if (!getCompact()) return rendered
    // Any tool (e.g. MCP tools like playwriter with no custom renderer) can
    // surface an unexpected args/result shape when it isn't ready. A throw here
    // runs in the render path and force-closes pi, so fall back to the original
    // renderer instead of crashing. Either way, clamp every line to `width` — a
    // line wider than the terminal makes pi's TUI throw and force-close.
    try {
      return clampLines(compactRenderInner.call(this, width, rendered), width)
    } catch {
      return clampLines(rendered, width)
    }
  }
  const compactRenderInner = function (
    this: ToolExecutionComponent,
    width: number,
    rendered: string[],
  ): string[] {
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

    // Degenerate width: too narrow to fit indent + status + a character. Emit
    // one bounded line instead of overflowing.
    if (width <= CALL_GUTTER) {
      const raw =
        rendered
          .filter((line) => line !== "")
          .map((l) => plainTerminalText(l).trim())
          .filter((l) => l !== "")[0] ?? ""
      return raw ? [truncateToWidth(raw, width, "…")] : []
    }

    // edit/write are owned by pi-tool-display and render their diffs inline in
    // both states (collapsed shows up to diffCollapsedLines). Keep their rows
    // uncollapsed.
    if (self.toolName === "edit" || self.toolName === "write") {
      return rendered.filter((line) => line !== "")
    }

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

    const status = self.result?.isError
      ? theme.fg("error", "✕")
      : self.isPartial
        ? theme.fg("muted", "·")
        : theme.fg("success", "✓")

    // Compact (re-registered) tools already wrap their call line through a
    // SingleLine at `width - CALL_GUTTER`; prepend the gutter and keep every
    // wrapped row so long text flows onto following lines instead of being cut.
    if (!isBgShell) {
      const [first, ...rest] = content
      return [
        `${COMPACT_INDENT}${status} ${first}`,
        ...rest.map((l) => `${COMPACT_INDENT}${l}`),
      ]
    }

    // fd/rg, Task* and other custom tools: join a short call + result summary
    // pair (or keep the call line), then wrap to width so long rows continue
    // onto the next line.
    const single =
      formatCodeToolCall(bareName, self.args, theme) ??
      (lines.length <= 2 ? lines.join(" · ") : (lines[0] ?? "")) +
        (args ? ` ${args}` : "")
    const contentWidth = Math.max(1, width - COMPACT_INDENT.length - 2)
    const wrapped = wrapTextWithAnsi(single, contentWidth)
    return [
      `${COMPACT_INDENT}${status} ${wrapped[0] ?? ""}`,
      ...wrapped.slice(1).map((l) => `${COMPACT_INDENT}${l}`),
    ]
  }
  prototype.render = compactRender
  prototype.__piUiToolSpacingPatched = true
  prototype.__piUiToolSpacingPatchVersion = TOOL_SPACING_PATCH_VERSION
  prototype.__piUiToolSpacingPatchOwner = TOOL_SPACING_PATCH_OWNER
  return () => {
    if (prototype.render === compactRender) {
      prototype.render = originalRender
      delete prototype.__piUiToolSpacingOriginalRender
      delete prototype.__piUiToolSpacingPatched
      delete prototype.__piUiToolSpacingPatchVersion
      delete prototype.__piUiToolSpacingPatchOwner
    }
  }
}

function compactArgs(args: unknown, theme: Theme): string {
  if (!args || typeof args !== "object" || Array.isArray(args)) return ""
  const parts: string[] = []
  for (const [key, value] of Object.entries(args as Record<string, unknown>)) {
    if (key === "code" || key === "language") continue
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

function formatCodeToolCall(name: string, args: unknown, theme: Theme) {
  if (!args || typeof args !== "object" || Array.isArray(args)) return undefined
  const { code, language } = args as Record<string, unknown>
  if (typeof code !== "string" || typeof language !== "string") return undefined
  const meta = compactArgs(args, theme)
  return `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", "</>")} ${theme.fg("accent", language)}${meta ? ` ${meta}` : ""}`
}

// Clamp every rendered line to `width`. pi's TUI throws (and force-closes) if
// any line exceeds the terminal width, so the compact renderer must never emit
// a wider line — regardless of a tool's renderShell or Box padding.
function clampLines(lines: string[], width: number): string[] {
  return lines.map((line) => truncateToWidth(line, width, "…"))
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
    const content = theme.fg(
      "dim",
      `${COMPACT_INDENT}› ${sanitizeMessageText(text)}`,
    )
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
