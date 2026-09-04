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
  type ExtensionUIContext,
  type Theme,
  ToolExecutionComponent,
  type ToolDefinition,
  type ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent"
import {
  Box,
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

// Layout-dependent port of https://github.com/zackerydev/pi-minimalist-ui.
// This renders compact single-line style only when `getCompact()` is true
// (minimal/lite). Full/off layouts use pi's built-in renderers.

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
  return ToolExecutionComponent.prototype as unknown as PatchableToolExecutionPrototype
}

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
        ? wrapTextWithAnsi(this.text, Math.max(1, width - CALL_GUTTER))
        : []
    return this.cachedLines
  }

  invalidate(): void {
    this.cachedWidth = undefined
    this.cachedLines = undefined
  }
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
  if (summary) text += theme.fg("muted", `. ${compactText(summary, "")}`)
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
    // Read at render time. Minimal/lite tools use self-shell. Full/off tools
    // keep pi's background box.
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
  getMinimal: () => boolean = getCompact,
): () => void {
  const prototype = getToolExecutionPrototype()
  const previousOriginalRender = prototype.__piUiToolSpacingOriginalRender
  const hasPreviousPatch =
    typeof previousOriginalRender === "function" &&
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
    typeof prototype.__piUiToolSpacingOriginalRender === "function"
  ) {
    return () => {}
  }

  if (!prototype.__piUiToolSpacingOriginalRender) {
    prototype.__piUiToolSpacingOriginalRender = prototype.render
  }
  const originalRender = prototype.__piUiToolSpacingOriginalRender
  if (!originalRender) return () => {}
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

    // Re-registered compact tools use renderShell "self" and emit one colored
    // line. fd/rg, Task*, and other custom tools use pi's default shell, where a
    // Box adds full-width background padding. Strip padding before collapsing.
    const isBgShell = self.getRenderShell() !== "self"
    const lines = isBgShell
      ? content
          .map((line) => plainTerminalText(line).trim())
          .filter((l) => l !== "")
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
      (getMinimal()
        ? formatSubagentToolCall(bareName, self.args, theme)
        : undefined) ??
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

function formatSubagentToolCall(name: string, args: unknown, theme: Theme) {
  if (!args || typeof args !== "object" || Array.isArray(args)) return undefined
  const input = args as Record<string, unknown>
  const ids = Array.isArray(input.ids)
    ? input.ids.filter((id): id is string => typeof id === "string").join(", ")
    : ""

  switch (name) {
    case "subagent_spawn":
      return renderLine(
        name,
        withMeta(
          compactText(input.name, "subagent"),
          [input.harness, input.model, input.reasoning_effort]
            .filter((value): value is string => typeof value === "string")
            .join(" · ") || undefined,
        ),
        theme,
      )
    case "subagent_wait":
    case "subagent_cancel":
      return renderLine(name, { subject: compactText(ids) }, theme)
    case "subagent_check":
      return renderLine(name, { subject: compactText(input.id) }, theme)
    case "subagent_list":
      return theme.fg("toolTitle", theme.bold(name))
    default:
      return undefined
  }
}

function formatCodeToolCall(name: string, args: unknown, theme: Theme) {
  if (!args || typeof args !== "object" || Array.isArray(args)) return undefined
  const { code, language } = args as Record<string, unknown>
  if (typeof code !== "string" || typeof language !== "string") return undefined
  const meta = compactArgs(args, theme)
  return `${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", "</>")} ${theme.fg("accent", language)}${meta ? ` ${meta}` : ""}`
}

// Clamp every rendered line to `width`. pi's TUI throws and force-closes when
// line exceeds terminal width, regardless of renderShell or Box padding.
function clampLines(lines: string[], width: number): string[] {
  return lines.map((line) => truncateToWidth(line, width, "…"))
}

interface SubagentTranscriptToolRenderRequest {
  readonly call: {
    readonly type: "toolCall"
    readonly toolId: string
    readonly name: string
    readonly displayArgs?: unknown
  }
  readonly result?: {
    readonly kind: "toolResult"
    readonly isError: boolean
    readonly displayResult?: unknown
  }
  readonly snapshot: { readonly cwd: string }
  readonly width: number
  readonly theme: Theme
}

type SubagentTranscriptToolRenderer = (
  request: SubagentTranscriptToolRenderRequest,
) => string[] | undefined

interface ToolDisplayRenderContext {
  readonly args: unknown
  readonly state: Record<string, unknown>
  readonly lastComponent: Component | undefined
  readonly invalidate: () => void
  readonly toolCallId: string
  readonly cwd: string
  readonly executionStarted: boolean
  readonly argsComplete: boolean
  readonly isPartial: boolean
  readonly expanded: boolean
  readonly showImages: boolean
  readonly isError: boolean
}

interface ToolDisplayDefinition {
  readonly renderCall?: (
    args: unknown,
    theme: Theme,
    context: ToolDisplayRenderContext,
  ) => Component
  readonly renderResult?: (
    result: unknown,
    options: ToolRenderResultOptions,
    theme: Theme,
    context: ToolDisplayRenderContext,
  ) => Component
}

interface ToolDisplayApi {
  readonly version: 1
  readonly decorateTool: (
    tool: Record<string, unknown>,
    adapter?: Record<string, unknown>,
  ) => ToolDisplayDefinition
}

const toolDisplayApiKey = Symbol.for("pi-tool-display.api.v1")
const subagentTranscriptToolRendererKey = Symbol.for(
  "pi-subagents.transcriptToolRenderer.v1",
)

type GlobalWithToolRenderers = typeof globalThis & {
  [toolDisplayApiKey]?: ToolDisplayApi
  [subagentTranscriptToolRendererKey]?: SubagentTranscriptToolRenderer
}

function createSubagentTranscriptToolRenderer(getMinimal: () => boolean) {
  let cache = new WeakMap<object, Component>()

  return {
    render(request: SubagentTranscriptToolRenderRequest) {
      const { call, result, snapshot, theme, width } = request
      if (
        !getMinimal() ||
        call.name !== "edit" ||
        call.displayArgs === undefined ||
        result?.displayResult === undefined
      )
        return undefined

      const api = (globalThis as GlobalWithToolRenderers)[toolDisplayApiKey]
      if (api?.version !== 1) return undefined

      const cacheKey =
        result.displayResult !== null &&
        typeof result.displayResult === "object"
          ? result.displayResult
          : undefined
      let component = cacheKey ? cache.get(cacheKey) : undefined
      if (!component) {
        const tool = api.decorateTool(
          { name: "edit" },
          { kind: "edit", overrideExistingRenderers: true },
        )
        if (!tool.renderCall || !tool.renderResult) return undefined

        const state: Record<string, unknown> = {}
        const context: ToolDisplayRenderContext = {
          args: call.displayArgs,
          state,
          lastComponent: undefined,
          invalidate: () => {},
          toolCallId: call.toolId,
          cwd: snapshot.cwd,
          executionStarted: true,
          argsComplete: true,
          isPartial: false,
          expanded: false,
          showImages: false,
          isError: result.isError,
        }
        const background = result.isError ? "toolErrorBg" : "toolSuccessBg"
        const box = new Box(1, 1, (text) => theme.bg(background, text))
        box.addChild(tool.renderCall(call.displayArgs, theme, context))
        box.addChild(
          tool.renderResult(
            result.displayResult,
            { expanded: false, isPartial: false },
            theme,
            context,
          ),
        )
        component = box
        if (cacheKey) cache.set(cacheKey, component)
      }

      return clampLines(component.render(width), width)
    },
    invalidate() {
      cache = new WeakMap()
    },
  }
}

function compactTakeoverTool(
  value: string,
  output: string | undefined,
  status: "done" | "error" | "running",
  width: number,
  theme: Theme,
) {
  const [name = "", ...args] = value.split(/\s+/)
  const marker =
    status === "error"
      ? theme.fg("error", "✕")
      : status === "done"
        ? theme.fg("success", "✓")
        : theme.fg("muted", "·")
  let text = theme.fg("toolTitle", theme.bold(name))
  if (args.length > 0) text += ` ${theme.fg("accent", args.join(" "))}`
  if (output) text += theme.fg("muted", ` · ${output}`)
  return truncateToWidth(`${COMPACT_INDENT}${marker} ${text}`, width, "…")
}

export function compactSubagentTakeover(
  lines: string[],
  width: number,
  theme: Theme,
) {
  const border = "─".repeat(Math.max(1, width))
  const borders = lines
    .map((line, index) => (plainTerminalText(line) === border ? index : -1))
    .filter((index) => index >= 0)
  const start = (borders[1] ?? -1) + 1
  const end = borders[2]
  if (start <= 0 || end === undefined || end <= start) return lines

  const body: string[] = []
  const pending: Array<{ index: number; value: string }> = []
  let paragraph: "thinking" | "user" | undefined
  for (const line of lines.slice(start, end)) {
    const plain = plainTerminalText(line).trim()
    if (!plain) {
      paragraph = undefined
      if (line) body.push(line)
      continue
    }
    if (plain.startsWith("> ")) {
      paragraph = "user"
      body.push(theme.fg("dim", `${COMPACT_INDENT}› ${plain.slice(2)}`))
      continue
    }
    if (plain.startsWith("~ ")) {
      paragraph = "thinking"
      body.push(
        `${COMPACT_INDENT}${theme.fg("muted", theme.italic(plain.slice(2)))}`,
      )
      continue
    }
    if (plain.startsWith("→ ") || /^(?:output|error):/.test(plain)) {
      paragraph = undefined
    }
    if (paragraph) {
      body.push(
        theme.fg(
          paragraph === "user" ? "dim" : "muted",
          `${COMPACT_INDENT.repeat(2)}${paragraph === "thinking" ? theme.italic(plain) : plain}`,
        ),
      )
      continue
    }
    if (plain.startsWith("→ ")) {
      const value = plain.slice(2)
      pending.push({ index: body.length, value })
      body.push(compactTakeoverTool(value, undefined, "running", width, theme))
      continue
    }
    const result = /^(output|error):\s*(.*)$/.exec(plain)
    if (result) {
      const call = pending.shift()
      const status = result[1] === "error" ? "error" : "done"
      if (call) {
        body[call.index] = compactTakeoverTool(
          call.value,
          result[2],
          status,
          width,
          theme,
        )
      } else {
        body.push(
          compactTakeoverTool("output", result[2], status, width, theme),
        )
      }
      continue
    }
    const live = /^(\S+)(?:\s+·\s+)(running|done|error)(?:\s+·\s+(.*))?$/.exec(
      plain,
    )
    if (live) {
      const status =
        live[2] === "done" ? "done" : live[2] === "error" ? "error" : "running"
      body.push(compactTakeoverTool(live[1], live[3], status, width, theme))
      continue
    }
    body.push(line)
  }

  const height = end - start
  const visible = body.slice(-height)
  return [
    ...lines.slice(0, start),
    ...visible,
    ...Array.from({ length: height - visible.length }, () => ""),
    ...lines.slice(end),
  ]
}

// Keep subagent takeover styling owned by this extension: wrap its custom UI
// instance rather than coupling the subagents extension to a layout setting.
export function installMinimalCustomUi(
  ui: ExtensionUIContext,
  getMinimal: () => boolean,
) {
  const globalWithRenderers = globalThis as GlobalWithToolRenderers
  const editRenderer = createSubagentTranscriptToolRenderer(getMinimal)
  const previousTranscriptRenderer =
    globalWithRenderers[subagentTranscriptToolRendererKey]
  const transcriptRenderer: SubagentTranscriptToolRenderer = (request) =>
    editRenderer.render(request) ?? previousTranscriptRenderer?.(request)
  globalWithRenderers[subagentTranscriptToolRendererKey] = transcriptRenderer

  const originalCustom = ui.custom
  const custom: ExtensionUIContext["custom"] = (factory, options) =>
    originalCustom(
      (tui, theme, keybindings, done) =>
        Promise.resolve(factory(tui, theme, keybindings, done)).then(
          (component) => {
            if (!getMinimal() || component.constructor.name !== "TakeoverView")
              return component
            const render = component.render.bind(component)
            const invalidate = component.invalidate.bind(component)
            component.render = (width) =>
              compactSubagentTakeover(render(width), width, theme)
            component.invalidate = () => {
              editRenderer.invalidate()
              invalidate()
            }
            return component
          },
        ),
      options,
    )
  ui.custom = custom
  return () => {
    if (ui.custom === custom) ui.custom = originalCustom
    if (
      globalWithRenderers[subagentTranscriptToolRendererKey] ===
      transcriptRenderer
    ) {
      if (previousTranscriptRenderer)
        globalWithRenderers[subagentTranscriptToolRendererKey] =
          previousTranscriptRenderer
      else delete globalWithRenderers[subagentTranscriptToolRendererKey]
    }
  }
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
    const { text } = this as unknown as UserMessageState
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
