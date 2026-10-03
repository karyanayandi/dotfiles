import * as v from "valibot"
import type { Static, TSchema } from "typebox"
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
} from "@earendil-works/pi-coding-agent"
import {
  Container,
  Text,
  truncateToWidth,
  type Component,
} from "@earendil-works/pi-tui"

// Left gutter for compact tool rows and user prompts.
const COMPACT_INDENT = "  "

// Gutter reserved on the first row of a tool call: indent + status + space.
const CALL_GUTTER = COMPACT_INDENT.length + 2 // "  " + "✓ " = 4

// Layout-dependent port of https://github.com/zackerydev/pi-minimalist-ui.
// This renders compact single-line style only when `getCompact()` is true
// (minimal/lite). Full/off layouts use pi's built-in renderers.

// SAFETY: Replace terminal C0/C1 controls and bidi overrides in untrusted tool labels; matching these bytes is intentional.
const unsafeTerminalCharacters =
  // oxlint-disable-next-line eslint/no-control-regex
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

interface CompactRenderer<TArgs, TDetails> {
  call: (args: Partial<TArgs>) => CompactCall
  summary?: (
    result: AgentToolResult<TDetails>,
    args: Partial<TArgs>,
  ) => string | undefined
  expanded?: (
    result: AgentToolResult<TDetails>,
    args: Partial<TArgs>,
    isError: boolean,
  ) => string
}

type ToolRender = ToolExecutionComponent["render"]

type ToolInvalidate = ToolExecutionComponent["invalidate"]

type ToolUpdateResult = ToolExecutionComponent["updateResult"]

type ToolSetExpanded = ToolExecutionComponent["setExpanded"]

interface PatchableToolExecutionPrototype {
  render: ToolRender
  invalidate: ToolInvalidate
  updateResult: ToolUpdateResult
  setExpanded: ToolSetExpanded
  __piUiToolSpacingOriginalRender?: ToolRender
  __piUiToolSpacingOriginalInvalidate?: ToolInvalidate
  __piUiToolSpacingOriginalUpdateResult?: ToolUpdateResult
  __piUiToolSpacingOriginalSetExpanded?: ToolSetExpanded
  __piUiToolSpacingPatched?: boolean
  __piUiToolSpacingPatchVersion?: number
  __piUiToolSpacingPatchOwner?: object
}

const TOOL_SPACING_PATCH_VERSION = 1

const TOOL_SPACING_PATCH_OWNER = {}

function getToolExecutionPrototype() {
  const prototype: PatchableToolExecutionPrototype =
    ToolExecutionComponent.prototype

  return prototype
}

class SingleLine implements Component {
  private cachedWidth?: number
  private cachedLines?: string[]

  constructor(private text: string) {}

  setText(text: string): void {
    if (text === this.text) return
    this.text = text
    this.invalidate()
  }

  render(width: number): string[] {
    if (this.cachedWidth === width && this.cachedLines) return this.cachedLines
    this.cachedWidth = width
    this.cachedLines =
      width > 0
        ? [truncateToWidth(this.text, Math.max(1, width - CALL_GUTTER), "…")]
        : []

    return this.cachedLines
  }

  invalidate(): void {
    this.cachedWidth = undefined
    this.cachedLines = undefined
  }
}

function compactText<TValue>(value: TValue, fallback = "…"): string {
  if (!v.is(v.string(), value)) return fallback
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

  if (summary) text += theme.fg("muted", `. ${compactText(summary, "")}`)

  return text
}

function registerCompactTool<
  TParams extends TSchema,
  TDetails,
  TState extends object,
>(
  pi: Pick<ExtensionAPI, "registerTool">,
  factory: (cwd: string) => ToolDefinition<TParams, TDetails, TState>,
  renderer: CompactRenderer<Static<TParams>, TDetails>,
  getCompact: () => boolean,
): void {
  const original = factory(process.cwd())
  const originalCall = original.renderCall
  const originalResult = original.renderResult
  const callLines = new WeakMap<TState, SingleLine>()

  const tool: ToolDefinition<TParams, TDetails, TState> = {
    ...original,
    // Read at render time. Minimal/lite tools use self-shell. Full/off tools
    // keep pi's background box.
    get renderShell(): "self" | "default" {
      return getCompact() ? "self" : "default"
    },
    execute(toolCallId, params, signal, onUpdate, ctx) {
      return factory(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx)
    },
    renderCall(args, theme, context) {
      if (!getCompact()) {
        return originalCall?.(args, theme, context) ?? new Text("", 0, 0)
      }

      const line =
        context.lastComponent instanceof SingleLine
          ? context.lastComponent
          : new SingleLine("")

      callLines.set(context.state, line)
      line.setText(renderLine(original.name, renderer.call(args), theme))

      return line
    },
    renderResult(result, options, theme, context) {
      if (!getCompact()) {
        return (
          originalResult?.(result, options, theme, context) ?? new Container()
        )
      }

      // Tools collapse to a single compact line.
      const summary = context.isError
        ? errorSummary(result)
        : renderer.summary?.(result, context.args)

      callLines
        .get(context.state)
        ?.setText(
          renderLine(
            original.name,
            renderer.call(context.args),
            theme,
            summary,
          ),
        )

      if (!options.expanded) return new Container()

      const output =
        renderer.expanded?.(result, context.args, context.isError) ??
        textOutput(result)

      return output
        ? new Text(styleOutput(output, theme, context.isError), 0, 0)
        : new Container()
    },
  }

  pi.registerTool(tool)
}

export function registerCompactTools(
  pi: Pick<ExtensionAPI, "registerTool">,
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
    previousOriginalRender !== undefined &&
    previousOriginalRender !== prototype.render

  const isCurrentPatch =
    prototype.__piUiToolSpacingPatchOwner === TOOL_SPACING_PATCH_OWNER

  let restoredStalePatch = false

  // A session reload can load this module before old patch state is cleaned up.
  // Restore old wrapper before installing this one.
  if (hasPreviousPatch && !isCurrentPatch) {
    prototype.render = previousOriginalRender

    if (prototype.__piUiToolSpacingOriginalInvalidate) {
      prototype.invalidate = prototype.__piUiToolSpacingOriginalInvalidate
    }

    if (prototype.__piUiToolSpacingOriginalUpdateResult) {
      prototype.updateResult = prototype.__piUiToolSpacingOriginalUpdateResult
    }

    if (prototype.__piUiToolSpacingOriginalSetExpanded) {
      prototype.setExpanded = prototype.__piUiToolSpacingOriginalSetExpanded
    }

    delete prototype.__piUiToolSpacingOriginalRender
    delete prototype.__piUiToolSpacingOriginalInvalidate
    delete prototype.__piUiToolSpacingOriginalUpdateResult
    delete prototype.__piUiToolSpacingOriginalSetExpanded
    delete prototype.__piUiToolSpacingPatched
    delete prototype.__piUiToolSpacingPatchVersion
    delete prototype.__piUiToolSpacingPatchOwner
    restoredStalePatch = true
  }

  // UI extension instances may share one prototype. Keep one wrapper. Stacking
  // wrappers turns one status icon into a row of check marks.
  if (
    !restoredStalePatch &&
    prototype.__piUiToolSpacingPatched &&
    prototype.__piUiToolSpacingPatchVersion === TOOL_SPACING_PATCH_VERSION &&
    prototype.__piUiToolSpacingOriginalRender !== undefined
  ) {
    return () => undefined
  }

  if (!prototype.__piUiToolSpacingOriginalRender) {
    prototype.__piUiToolSpacingOriginalRender = prototype.render
  }

  const originalRender = prototype.__piUiToolSpacingOriginalRender

  if (!originalRender) return () => undefined

  const originalInvalidate = prototype.invalidate
  const originalUpdateResult = prototype.updateResult
  const originalSetExpanded = prototype.setExpanded

  const renderCache = new WeakMap<
    ToolExecutionComponent,
    { width: number; lines: string[] }
  >()

  const renderState = new WeakMap<
    ToolExecutionComponent,
    { settled: boolean; expanded: boolean; hasImages: boolean }
  >()

  const compactRender = function (
    this: ToolExecutionComponent,
    width: number,
  ): string[] {
    if (!getCompact()) return originalRender.call(this, width)
    const state = renderState.get(this)
    const cacheable = state?.settled && !state.expanded && !state.hasImages
    const cached = cacheable ? renderCache.get(this) : undefined

    if (cached?.width === width) return cached.lines

    const rendered = originalRender.call(this, width)

    // Image rows contain blank height placeholders and terminal image escapes.
    // Collapsing or clamping them draws the image over neighboring text.
    if (state?.hasImages) return rendered
    // Tools without custom renderers, such as playwriter, may expose unexpected
    // args or result shapes before they are ready. A throw in render force-closes
    // pi, so use original renderer on error. Clamp lines to `width`, because a
    // wider line makes pi's TUI throw and force-close.
    let lines: string[]

    try {
      lines = clampLines(compactRenderInner.call(this, width, rendered), width)
    } catch {
      lines = clampLines(rendered, width)
    }

    if (cacheable) renderCache.set(this, { width, lines })

    return lines
  }

  const compactInvalidate = function (this: ToolExecutionComponent) {
    renderCache.delete(this)
    originalInvalidate.call(this)
  }

  const compactUpdateResult: ToolUpdateResult = function (
    this: ToolExecutionComponent,
    result,
    isPartial = false,
  ) {
    const previous = renderState.get(this)
    renderState.set(this, {
      settled: !isPartial,
      expanded: previous?.expanded ?? false,
      hasImages: result.content.some((part) => part.type === "image"),
    })
    renderCache.delete(this)
    originalUpdateResult.call(this, result, isPartial)
  }

  const compactSetExpanded: ToolSetExpanded = function (
    this: ToolExecutionComponent,
    expanded,
  ) {
    const previous = renderState.get(this)
    renderState.set(this, {
      settled: previous?.settled ?? false,
      expanded,
      hasImages: previous?.hasImages ?? false,
    })
    renderCache.delete(this)
    originalSetExpanded.call(this, expanded)
  }

  const compactRenderInner = function (
    this: ToolExecutionComponent,
    width: number,
    rendered: string[],
  ): string[] {
    const self = v.parse(toolExecutionStateSchema, this)

    if (self.expanded) return rendered

    if (width <= 0) return []

    // Degenerate width: too narrow to fit indent + status + a character. Emit
    // one bounded line instead of overflowing.
    if (width <= CALL_GUTTER) {
      const raw =
        rendered.flatMap((line) => {
          if (line === "") return []
          const plain = plainTerminalText(line).trim()

          return plain ? [plain] : []
        })[0] ?? ""

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

    // Re-registered compact tools use renderShell "self" and emit one colored
    // line. fd/rg, Task*, and other custom tools use pi's default shell, where a
    // Box adds full-width background padding. Strip padding before collapsing.
    const isBgShell = self.getRenderShell.call(this) !== "self"

    const lines = isBgShell
      ? content.flatMap((line) => {
          const plain = plainTerminalText(line).trim()

          return plain ? [plain] : []
        })
      : content

    if (lines.length === 0) return []

    // Tools without custom renderCall fall back to bare-name line. Append an
    // args digest for Task* tools.
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

    const contentWidth = width - CALL_GUTTER

    if (!isBgShell) {
      return [
        `${COMPACT_INDENT}${status} ${truncateToWidth(content.join(" "), contentWidth, "…")}`,
      ]
    }

    // Code tools keep explicit source lines beneath the truncated header.
    const codeCall = formatCodeToolCall(bareName, self.args, theme)

    const single =
      codeCall?.header ??
      (lines.length <= 2 ? lines.join(" · ") : (lines[0] ?? "")) +
        (args ? ` ${args}` : "")

    return [
      `${COMPACT_INDENT}${status} ${truncateToWidth(single, contentWidth, "…")}`,
      ...(codeCall?.code
        .split("\n")
        .map(
          (line) =>
            `${COMPACT_INDENT}${truncateToWidth(
              theme.fg("toolOutput", sanitizeTerminalText(line)),
              width - COMPACT_INDENT.length,
              "…",
            )}`,
        ) ?? []),
    ]
  }

  prototype.render = compactRender
  prototype.invalidate = compactInvalidate
  prototype.updateResult = compactUpdateResult
  prototype.setExpanded = compactSetExpanded
  prototype.__piUiToolSpacingOriginalInvalidate = originalInvalidate
  prototype.__piUiToolSpacingOriginalUpdateResult = originalUpdateResult
  prototype.__piUiToolSpacingOriginalSetExpanded = originalSetExpanded
  prototype.__piUiToolSpacingPatched = true
  prototype.__piUiToolSpacingPatchVersion = TOOL_SPACING_PATCH_VERSION
  prototype.__piUiToolSpacingPatchOwner = TOOL_SPACING_PATCH_OWNER

  return () => {
    if (prototype.render === compactRender) {
      prototype.render = originalRender

      if (prototype.invalidate === compactInvalidate) {
        prototype.invalidate = originalInvalidate
      }

      if (prototype.updateResult === compactUpdateResult) {
        prototype.updateResult = originalUpdateResult
      }

      if (prototype.setExpanded === compactSetExpanded) {
        prototype.setExpanded = originalSetExpanded
      }

      delete prototype.__piUiToolSpacingOriginalRender
      delete prototype.__piUiToolSpacingOriginalInvalidate
      delete prototype.__piUiToolSpacingOriginalUpdateResult
      delete prototype.__piUiToolSpacingOriginalSetExpanded
      delete prototype.__piUiToolSpacingPatched
      delete prototype.__piUiToolSpacingPatchVersion
      delete prototype.__piUiToolSpacingPatchOwner
    }
  }
}

const compactArgumentSchema = v.union([
  v.string(),
  v.number(),
  v.boolean(),
  v.bigint(),
  v.symbol(),
  v.null(),
  v.undefined(),
  v.array(v.unknown()),
  v.object({}),
  v.function(),
])

const compactArgsSchema = v.record(v.string(), compactArgumentSchema)

const codeArgsSchema = v.object({ code: v.string(), language: v.string() })

const workflowArgsSchema = v.object({ script: v.string() })

function compactArgs<TArgs>(args: TArgs, theme: Theme): string {
  if (Array.isArray(args) || !v.is(compactArgsSchema, args)) return ""
  const parts: string[] = []

  for (const [key, value] of Object.entries(args)) {
    if (key === "code" || key === "language") continue

    if (value === undefined || value === null || value === "") continue

    const val = v.is(v.string(), value)
      ? compactText(value, "")
      : Array.isArray(value)
        ? value.length > 1
          ? `[${value.length}]`
          : compactText(String(value[0] ?? ""), "")
        : v.is(v.object({}), value)
          ? ""
          : String(value)

    if (!val) continue
    parts.push(
      `${theme.fg("muted", compactText(key))}:${theme.fg("accent", val)}`,
    )
  }

  return parts.join(" ")
}

function formatCodeToolCall<TArgs>(name: string, args: TArgs, theme: Theme) {
  if (Array.isArray(args) || !v.is(compactArgsSchema, args)) return undefined

  if (name === "workflow") {
    if (!v.is(workflowArgsSchema, args)) return undefined
    const meta = compactArgs({ ...args, script: undefined }, theme)

    return {
      header: `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", "</>")} ${theme.fg("accent", "javascript")}${meta ? ` ${meta}` : ""}`,
      code: args.script,
    }
  }

  if (!v.is(codeArgsSchema, args)) return undefined
  const meta = compactArgs(args, theme)

  return {
    header: `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", "</>")} ${theme.fg("accent", args.language)}${meta ? ` ${meta}` : ""}`,
    code: args.code,
  }
}

// Clamp every rendered line to `width`. pi's TUI throws and force-closes when
// line exceeds terminal width, regardless of renderShell or Box padding.
function clampLines(lines: string[], width: number): string[] {
  return lines.map((line) => truncateToWidth(line, width, "…"))
}

// --- compact message rendering ---

// SAFETY: Replace terminal controls and bidi overrides in user text while preserving tabs, newlines, and carriage returns.
const unsafeMessageCharacters =
  // oxlint-disable-next-line eslint/no-control-regex
  /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f-\u009f\u202a-\u202e\u2066-\u2069]/g

function sanitizeMessageText(text: string): string {
  return text.replace(unsafeMessageCharacters, "�")
}

function plainTerminalText(text: string): string {
  // SAFETY: Strip only ANSI CSI sequences from terminal-rendered rows; ESC is essential to identifying these sequences.
  // oxlint-disable-next-line eslint/no-control-regex
  return text.replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")
}

const textStateSchema = v.object({ text: v.string() })

const toolExecutionStateSchema = v.object({
  expanded: v.boolean(),
  isPartial: v.boolean(),
  toolName: v.optional(v.string()),
  args: v.optional(v.unknown()),
  result: v.optional(v.object({ isError: v.optional(v.boolean()) })),
  getRenderShell: v.function(),
})

const assistantMessageStateSchema = v.object({
  hiddenThinkingLabel: v.string(),
  hideThinkingBlock: v.boolean(),
  lastMessage: v.optional(
    v.object({
      content: v.array(
        v.object({
          type: v.string(),
          text: v.optional(v.string()),
          thinking: v.optional(v.string()),
        }),
      ),
      errorMessage: v.optional(v.string()),
      stopReason: v.string(),
    }),
  ),
})

export function installCompactMessages(
  theme: Theme,
  getCompact: () => boolean,
): () => void {
  const originalTextRender = Text.prototype.render

  const compactTextRender = function (this: Text, width: number): string[] {
    if (!getCompact()) return originalTextRender.call(this, width)
    const { text } = v.parse(textStateSchema, this)

    if (plainTerminalText(text.slice(0, 128)).startsWith("Thinking level: "))
      return []

    return originalTextRender.call(this, width)
  }

  Text.prototype.render = compactTextRender

  const originalUserRender = UserMessageComponent.prototype.render
  const originalUserInvalidate = UserMessageComponent.prototype.invalidate
  const compactUserMessages = new WeakMap<UserMessageComponent, Text>()

  const compactUserRender = function (
    this: UserMessageComponent,
    width: number,
  ): string[] {
    if (!getCompact()) return originalUserRender.call(this, width)
    const { text } = v.parse(textStateSchema, this)
    let message = compactUserMessages.get(this)

    if (!message) {
      const content = theme.fg(
        "dim",
        `${COMPACT_INDENT}› ${sanitizeMessageText(text)}`,
      )

      message = new Text(content, 0, 0)
      compactUserMessages.set(this, message)
    }

    return message.render(width)
  }

  const compactUserInvalidate = function (this: UserMessageComponent) {
    compactUserMessages.delete(this)
    originalUserInvalidate.call(this)
  }

  UserMessageComponent.prototype.render = compactUserRender
  UserMessageComponent.prototype.invalidate = compactUserInvalidate

  const originalAssistantRender = AssistantMessageComponent.prototype.render

  const originalAssistantInvalidate =
    AssistantMessageComponent.prototype.invalidate

  const originalAssistantUpdateContent =
    AssistantMessageComponent.prototype.updateContent

  const compactAssistantLines = new WeakMap<
    AssistantMessageComponent,
    { width: number; lines: string[] }
  >()

  const compactAssistantState = new WeakMap<
    AssistantMessageComponent,
    { streaming: boolean }
  >()

  const compactAssistantRender = function (
    this: AssistantMessageComponent,
    width: number,
  ): string[] {
    if (!getCompact()) return originalAssistantRender.call(this, width)
    const state = compactAssistantState.get(this)

    const cached =
      state?.streaming === false ? compactAssistantLines.get(this) : undefined

    if (cached?.width === width) return cached.lines

    const { hiddenThinkingLabel, hideThinkingBlock, lastMessage } = v.parse(
      assistantMessageStateSchema,
      this,
    )

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

    let lines: string[]

    if (
      hasToolCalls &&
      hasThinking &&
      !hasText &&
      hideThinkingBlock &&
      !hiddenThinkingLabel
    ) {
      lines = []
    } else if (lastMessage?.stopReason !== "aborted" || hasToolCalls) {
      lines = originalAssistantRender.call(this, width)
    } else {
      const message =
        lastMessage.errorMessage &&
        lastMessage.errorMessage !== "Request was aborted"
          ? lastMessage.errorMessage
          : "Operation aborted"

      lines = new Text(
        theme.fg("error", sanitizeMessageText(message)),
        0,
        0,
      ).render(width)
    }

    const cacheable =
      state?.streaming === false ||
      (state === undefined && lastMessage?.stopReason !== "pending")

    if (cacheable) compactAssistantLines.set(this, { width, lines })

    return lines
  }

  const compactAssistantInvalidate = function (
    this: AssistantMessageComponent,
  ) {
    compactAssistantLines.delete(this)
    originalAssistantInvalidate.call(this)
  }

  const compactAssistantUpdateContent: AssistantMessageComponent["updateContent"] =
    function (this: AssistantMessageComponent, message, isStreaming) {
      const previous = compactAssistantState.get(this)
      compactAssistantState.set(this, {
        streaming: isStreaming ?? previous?.streaming ?? false,
      })
      compactAssistantLines.delete(this)
      originalAssistantUpdateContent.call(this, message, isStreaming)
    }

  AssistantMessageComponent.prototype.render = compactAssistantRender
  AssistantMessageComponent.prototype.invalidate = compactAssistantInvalidate
  AssistantMessageComponent.prototype.updateContent =
    compactAssistantUpdateContent

  return () => {
    if (Text.prototype.render === compactTextRender) {
      Text.prototype.render = originalTextRender
    }

    if (UserMessageComponent.prototype.render === compactUserRender) {
      UserMessageComponent.prototype.render = originalUserRender
    }

    if (UserMessageComponent.prototype.invalidate === compactUserInvalidate) {
      UserMessageComponent.prototype.invalidate = originalUserInvalidate
    }

    if (AssistantMessageComponent.prototype.render === compactAssistantRender) {
      AssistantMessageComponent.prototype.render = originalAssistantRender
    }

    if (
      AssistantMessageComponent.prototype.invalidate ===
      compactAssistantInvalidate
    ) {
      AssistantMessageComponent.prototype.invalidate =
        originalAssistantInvalidate
    }

    if (
      AssistantMessageComponent.prototype.updateContent ===
      compactAssistantUpdateContent
    ) {
      AssistantMessageComponent.prototype.updateContent =
        originalAssistantUpdateContent
    }
  }
}
