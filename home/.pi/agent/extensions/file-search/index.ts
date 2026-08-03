/**
 * file-search — first-class `fd` and `rg` tools for pi.
 *
 * On session start the extension resolves a usable binary for each tool:
 * a normally installed system binary is preferred (silently), then an
 * existing fallback in this repo's `bin/` directory (silently), and only
 * when neither exists is an official release downloaded into `bin/` — the
 * single case that shows a UI notification. Tools await that initialization
 * before executing, and report a clear error if it failed.
 */

import { NodeServices } from "@effect/platform-node"
import type {
  AgentToolResult,
  ExtensionAPI,
  ExtensionContext,
  Theme,
} from "@earendil-works/pi-coding-agent"
import {
  Container,
  Text,
  truncateToWidth,
  type Component,
} from "@earendil-works/pi-tui"
import { Cause, Data, Effect, Exit } from "effect"
import { type Static, Type } from "typebox"
import { StringEnum } from "@earendil-works/pi-ai"
import {
  buildFdArgs,
  buildRgArgs,
  FD_MAX_DEPTH_LIMIT,
  FD_MAX_LIMIT,
  RG_MAX_CONTEXT,
  RG_MAX_COUNT_LIMIT,
} from "./src/args.ts"
import {
  currentTarget,
  liveBinaryEnv,
  repositoryBinDir,
  resolveBinary,
  TOOL_SPECS,
  type BinaryEnv,
  type BinarySource,
  type PlatformTarget,
  type ResolvedBinary,
} from "./src/binaries.ts"
import { formatCapturedOutput, type CapturedOutput } from "./src/output.ts"
import {
  FD_PARAMETER_DESCRIPTIONS,
  FD_PROMPT_GUIDELINES,
  FD_PROMPT_SNIPPET,
  FD_TOOL_DESCRIPTION,
  RG_PARAMETER_DESCRIPTIONS,
  RG_PROMPT_GUIDELINES,
  RG_PROMPT_SNIPPET,
  RG_TOOL_DESCRIPTION,
} from "./src/prompt.ts"
import { discardCapturedOutput, executeSearchProcess } from "./src/process.ts"

export function makeBinaryInitializers(
  binDir: string,
  target: PlatformTarget,
  env: BinaryEnv,
) {
  return {
    fd: Effect.runSync(
      Effect.cached(resolveBinary(TOOL_SPECS.fd, binDir, target, env)),
    ),
    rg: Effect.runSync(
      Effect.cached(resolveBinary(TOOL_SPECS.rg, binDir, target, env)),
    ),
  }
}

/** Human-readable install notice, shown only for fresh downloads. */
export function installNotifications(binaries: readonly ResolvedBinary[]) {
  return binaries
    .filter((binary) => binary.source === "installed")
    .map(
      (binary) =>
        `file-search: no system ${binary.tool} found — downloaded ${binary.tool} ${binary.version ?? ""}`.trimEnd() +
        ` to ${repositoryBinDir()}`,
    )
}

class SingleLine implements Component {
  constructor(private text: string) {}

  setText(text: string): void {
    this.text = text
  }

  render(width: number): string[] {
    if (width <= 0) return []
    return [truncateToWidth(this.text, width, "…", true)]
  }

  invalidate(): void {}
}

function statusIcon(theme: Theme, isPartial: boolean, isError: boolean): string {
  return isPartial
    ? theme.fg("muted", "·")
    : isError
      ? theme.fg("error", "✕")
      : theme.fg("success", "✓")
}

function compactLine(
  name: string,
  subject: string,
  meta: string | undefined,
  flags: readonly string[],
  theme: Theme,
  isPartial: boolean,
  isError: boolean,
  summary?: string,
): string {
  let text = `${statusIcon(theme, isPartial, isError)} ${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("accent", subject)}`
  if (meta) text += theme.fg("muted", ` ${meta}`)
  if (flags.length > 0) text += " " + theme.fg("dim", flags.join(" "))
  if (summary) text += theme.fg(isError ? "error" : "muted", ` — ${summary}`)
  return text
}

function errorSummary(result: AgentToolResult<unknown>): string | undefined {
  const lines = result.content
    .flatMap((part) => (part.type === "text" ? [part.text] : []))
    .join("\n")
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
  return lines.length > 0 ? lines.at(-1) : undefined
}

class SearchError extends Data.TaggedError("SearchError")<{
  readonly message: string
}> {}

interface SearchOutcome {
  readonly output: CapturedOutput
  readonly noMatches: boolean
  readonly binarySource: BinarySource
}

export interface FdToolDetails {
  readonly binarySource: BinarySource
  readonly matchCount: number
  readonly truncated: boolean
  readonly fullOutputPath?: string
}

export interface RgToolDetails {
  readonly binarySource: BinarySource
  readonly outputLines: number
  readonly truncated: boolean
  readonly fullOutputPath?: string
}

const EXEC_TIMEOUT_MS = 60_000

function causeMessage<E>(cause: Cause.Cause<E>) {
  const [first] = Cause.prettyErrors(cause)
  return first?.message ?? Cause.pretty(cause)
}

function unwrapToolExit<A, E>(exit: Exit.Exit<A, E>, tool: "fd" | "rg") {
  if (Exit.isSuccess(exit)) return exit.value
  if (Cause.hasInterruptsOnly(exit.cause)) {
    throw new Error(`${tool} search was cancelled.`)
  }
  throw new Error(causeMessage(exit.cause))
}

export default function fileSearchTools(pi: ExtensionAPI) {
  let notified = false

  const binDir = repositoryBinDir()
  const target = currentTarget()
  const initializers = makeBinaryInitializers(binDir, target, liveBinaryEnv)

  pi.on("session_start", async (_event, ctx) => {
    const exit = await Effect.runPromiseExit(
      Effect.gen(function* () {
        const initialized = yield* Effect.all(
          {
            fd: Effect.exit(initializers.fd),
            rg: Effect.exit(initializers.rg),
          },
          { concurrency: "unbounded" },
        )
        if (!ctx.hasUI || notified) return

        notified = true
        for (const tool of ["fd", "rg"] as const) {
          const toolExit = initialized[tool]
          if (Exit.isSuccess(toolExit)) {
            for (const message of installNotifications([toolExit.value])) {
              ctx.ui.notify(message, "info")
            }
          } else {
            ctx.ui.notify(
              `file-search ${tool} setup failed: ${causeMessage(toolExit.cause)}`,
              "error",
            )
          }
        }
      }),
    )

    if (Exit.isFailure(exit) && ctx.hasUI && !notified) {
      notified = true
      ctx.ui.notify(
        `file-search setup failed: ${causeMessage(exit.cause)}`,
        "error",
      )
    }
  })

  /** Await init, stream the binary output to disk, and classify its exit. */
  function runSearch(tool: "fd" | "rg", args: string[], ctx: ExtensionContext) {
    return Effect.gen(function* () {
      const binary = yield* initializers[tool]
      const result = yield* executeSearchProcess({
        command: binary.command,
        args,
        cwd: ctx.cwd,
        tempPrefix: `pi-${tool}-`,
      })

      // ripgrep exits 1 for "no matches"; fd exits 0 even with no results.
      if (tool === "rg" && result.code === 1 && result.output.lineCount === 0) {
        return {
          output: result.output,
          noMatches: true,
          binarySource: binary.source,
        } satisfies SearchOutcome
      }
      if (result.code !== 0) {
        yield* discardCapturedOutput(result.output)
        const detail = result.stderr.trim() || `exit code ${result.code}`
        return yield* new SearchError({ message: `${tool} failed: ${detail}` })
      }
      return {
        output: result.output,
        noMatches: result.output.lineCount === 0,
        binarySource: binary.source,
      } satisfies SearchOutcome
    }).pipe(
      Effect.timeout(EXEC_TIMEOUT_MS),
      Effect.mapError((error) => {
        if (error instanceof SearchError) return error
        return new SearchError({
          message:
            error._tag === "TimeoutError"
              ? `${tool} timed out.`
              : error instanceof Error
                ? error.message
                : String(error),
        })
      }),
      Effect.provide(NodeServices.layer),
    )
  }

  pi.registerTool<ReturnType<typeof fdParameters>, FdToolDetails>({
    name: "fd",
    label: "Find Files",
    renderShell: "self",
    description: FD_TOOL_DESCRIPTION,
    promptSnippet: FD_PROMPT_SNIPPET,
    promptGuidelines: FD_PROMPT_GUIDELINES,
    parameters: fdParameters(),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const exit = await Effect.runPromiseExit(
        Effect.gen(function* () {
          const outcome = yield* runSearch("fd", buildFdArgs(params), ctx)
          if (outcome.noMatches) {
            return {
              content: [{ type: "text", text: "No files found" }],
              details: {
                binarySource: outcome.binarySource,
                matchCount: 0,
                truncated: false,
              },
            } satisfies AgentToolResult<FdToolDetails>
          }

          const formatted = formatCapturedOutput(outcome.output)
          return {
            content: [{ type: "text", text: formatted.text }],
            details: {
              binarySource: outcome.binarySource,
              matchCount: formatted.lineCount,
              truncated: formatted.truncated,
              fullOutputPath: formatted.fullOutputPath,
            },
          } satisfies AgentToolResult<FdToolDetails>
        }),
        signal ? { signal } : undefined,
      )
      return unwrapToolExit(exit, "fd")
    },

    renderCall(args, theme, context) {
      const line =
        context.lastComponent instanceof SingleLine
          ? context.lastComponent
          : new SingleLine("")
      context.state.line = line
      line.setText(
        compactLine(
          "fd",
          args.pattern ? `"${args.pattern}"` : "(all)",
          args.path ? `in ${args.path}` : undefined,
          fdFlags(args),
          theme,
          context.isPartial,
          context.isError,
        ),
      )
      return line
    },

    renderResult(result, { expanded, isPartial }, theme, context) {
      const details = result.details
      const summary = context.isError
        ? errorSummary(result)
        : !details || details.matchCount === 0
          ? "No files found"
          : `${details.matchCount} ${details.matchCount === 1 ? "entry" : "entries"}${details.truncated ? " (truncated)" : ""}`
      context.state.line?.setText(
        compactLine(
          "fd",
          context.args.pattern ? `"${context.args.pattern}"` : "(all)",
          context.args.path ? `in ${context.args.path}` : undefined,
          fdFlags(context.args),
          theme,
          isPartial,
          context.isError,
          summary,
        ),
      )
      if (!expanded) return new Container()
      const preview =
        details && details.matchCount > 0
          ? expandedPreview(result, details.fullOutputPath, theme)
          : ""
      return preview ? new Text(preview, 0, 0) : new Container()
    },
  })

  pi.registerTool<ReturnType<typeof rgParameters>, RgToolDetails>({
    name: "rg",
    label: "Search Content",
    renderShell: "self",
    description: RG_TOOL_DESCRIPTION,
    promptSnippet: RG_PROMPT_SNIPPET,
    promptGuidelines: RG_PROMPT_GUIDELINES,
    parameters: rgParameters(),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const exit = await Effect.runPromiseExit(
        Effect.gen(function* () {
          const outcome = yield* runSearch("rg", buildRgArgs(params), ctx)
          if (outcome.noMatches) {
            return {
              content: [{ type: "text", text: "No matches found" }],
              details: {
                binarySource: outcome.binarySource,
                outputLines: 0,
                truncated: false,
              },
            } satisfies AgentToolResult<RgToolDetails>
          }

          const formatted = formatCapturedOutput(outcome.output)
          return {
            content: [{ type: "text", text: formatted.text }],
            details: {
              binarySource: outcome.binarySource,
              outputLines: formatted.lineCount,
              truncated: formatted.truncated,
              fullOutputPath: formatted.fullOutputPath,
            },
          } satisfies AgentToolResult<RgToolDetails>
        }),
        signal ? { signal } : undefined,
      )
      return unwrapToolExit(exit, "rg")
    },

    renderCall(args, theme, context) {
      const line =
        context.lastComponent instanceof SingleLine
          ? context.lastComponent
          : new SingleLine("")
      context.state.line = line
      line.setText(
        compactLine(
          "rg",
          `"${args.pattern}"`,
          args.path ? `in ${args.path}` : undefined,
          rgFlags(args),
          theme,
          context.isPartial,
          context.isError,
        ),
      )
      return line
    },

    renderResult(result, { expanded, isPartial }, theme, context) {
      const details = result.details
      const summary = context.isError
        ? errorSummary(result)
        : !details || details.outputLines === 0
          ? "No matches found"
          : `${details.outputLines} output ${details.outputLines === 1 ? "line" : "lines"}${details.truncated ? " (truncated)" : ""}`
      context.state.line?.setText(
        compactLine(
          "rg",
          `"${context.args.pattern}"`,
          context.args.path ? `in ${context.args.path}` : undefined,
          rgFlags(context.args),
          theme,
          isPartial,
          context.isError,
          summary,
        ),
      )
      if (!expanded) return new Container()
      const preview =
        details && details.outputLines > 0
          ? expandedPreview(result, details.fullOutputPath, theme)
          : ""
      return preview ? new Text(preview, 0, 0) : new Container()
    },
  })
}

type FdParams = Static<ReturnType<typeof fdParameters>>
type RgParams = Static<ReturnType<typeof rgParameters>>

function fdFlags(args: FdParams): string[] {
  return [
    args.type && `type=${args.type}`,
    args.extension && `ext=${args.extension}`,
    args.glob && "glob",
    args.hidden && "hidden",
    args.max_depth !== undefined && `depth≤${args.max_depth}`,
  ].filter((flag): flag is string => typeof flag === "string")
}

function rgFlags(args: RgParams): string[] {
  return [
    args.glob && `glob=${args.glob}`,
    args.file_type && `type=${args.file_type}`,
    args.fixed_strings && "literal",
    args.hidden && "hidden",
    args.context !== undefined && `ctx=${args.context}`,
  ].filter((flag): flag is string => typeof flag === "string")
}

const PREVIEW_LINES = 20

interface ThemeLike {
  fg(color: string, text: string): string
}

function expandedPreview(
  result: { content: { type: string; text?: string }[] },
  fullOutputPath: string | undefined,
  theme: ThemeLike,
) {
  let text = ""
  const content = result.content[0]
  if (content?.type === "text" && content.text) {
    const lines = content.text.split("\n")
    for (const line of lines.slice(0, PREVIEW_LINES)) {
      text += `\n${theme.fg("dim", line)}`
    }
    if (lines.length > PREVIEW_LINES) {
      text += `\n${theme.fg("muted", `... ${lines.length - PREVIEW_LINES} more lines`)}`
    }
  }
  if (fullOutputPath) {
    text += `\n${theme.fg("dim", `Full output: ${fullOutputPath}`)}`
  }
  return text
}

function fdParameters() {
  return Type.Object({
    pattern: Type.Optional(
      Type.String({ description: FD_PARAMETER_DESCRIPTIONS.pattern }),
    ),
    path: Type.Optional(
      Type.String({ description: FD_PARAMETER_DESCRIPTIONS.path }),
    ),
    type: Type.Optional(
      StringEnum(["file", "directory", "symlink"] as const, {
        description: FD_PARAMETER_DESCRIPTIONS.type,
      }),
    ),
    extension: Type.Optional(
      Type.String({ description: FD_PARAMETER_DESCRIPTIONS.extension }),
    ),
    glob: Type.Optional(
      Type.Boolean({ description: FD_PARAMETER_DESCRIPTIONS.glob }),
    ),
    hidden: Type.Optional(
      Type.Boolean({ description: FD_PARAMETER_DESCRIPTIONS.hidden }),
    ),
    max_depth: Type.Optional(
      Type.Integer({
        description: FD_PARAMETER_DESCRIPTIONS.max_depth,
        minimum: 1,
        maximum: FD_MAX_DEPTH_LIMIT,
      }),
    ),
    limit: Type.Optional(
      Type.Integer({
        description: FD_PARAMETER_DESCRIPTIONS.limit,
        minimum: 1,
        maximum: FD_MAX_LIMIT,
      }),
    ),
  })
}

function rgParameters() {
  return Type.Object({
    pattern: Type.String({ description: RG_PARAMETER_DESCRIPTIONS.pattern }),
    path: Type.Optional(
      Type.String({ description: RG_PARAMETER_DESCRIPTIONS.path }),
    ),
    glob: Type.Optional(
      Type.String({ description: RG_PARAMETER_DESCRIPTIONS.glob }),
    ),
    file_type: Type.Optional(
      Type.String({ description: RG_PARAMETER_DESCRIPTIONS.file_type }),
    ),
    case_sensitive: Type.Optional(
      Type.Boolean({ description: RG_PARAMETER_DESCRIPTIONS.case_sensitive }),
    ),
    fixed_strings: Type.Optional(
      Type.Boolean({ description: RG_PARAMETER_DESCRIPTIONS.fixed_strings }),
    ),
    hidden: Type.Optional(
      Type.Boolean({ description: RG_PARAMETER_DESCRIPTIONS.hidden }),
    ),
    context: Type.Optional(
      Type.Integer({
        description: RG_PARAMETER_DESCRIPTIONS.context,
        minimum: 0,
        maximum: RG_MAX_CONTEXT,
      }),
    ),
    limit: Type.Optional(
      Type.Integer({
        description: RG_PARAMETER_DESCRIPTIONS.limit,
        minimum: 1,
        maximum: RG_MAX_COUNT_LIMIT,
      }),
    ),
  })
}
