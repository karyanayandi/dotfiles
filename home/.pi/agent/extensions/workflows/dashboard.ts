/**
 * /workflows dashboard: a borderless run list, phase and agent view, and
 * compact conversation transcript.
 */

import * as fs from "node:fs"
import * as path from "node:path"
import { stripVTControlCharacters } from "node:util"
import * as v from "valibot"
import {
  getAgentDir,
  getMarkdownTheme,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent"
import {
  Key,
  Markdown,
  matchesKey,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
  type KeybindingsManager,
  type TUI,
} from "@earendil-works/pi-tui"
import { ACTIVITY_FRAME_MS } from "@pi/shared/activity-status"
import {
  agentContext,
  countStates,
  formatElapsed,
  formatUsage,
  aggregateUsage,
  phaseGroups,
  resultJson,
  shortenHome,
  stateGlyph,
  statusColor,
  statusGlyph,
  statusWord,
  type Theme,
  type AgentRecord,
  type PhaseGroup,
  type TranscriptEntry,
  type WorkflowDetails,
} from "./model.ts"

const GUTTER = "  "

const NOTICE_TTL_MS = 4000

const ARTIFACT_REFRESH_MS = 500

const TRANSCRIPT_SCROLL_STEP = 20

function terminalText(text: string): string {
  const safeText = stripVTControlCharacters(text).replaceAll("\t", "  ")
  let sanitized = ""

  for (const character of safeText) {
    const codePoint = character.codePointAt(0)

    if (
      codePoint === undefined ||
      codePoint <= 0x1f ||
      (codePoint >= 0x7f && codePoint <= 0x9f) ||
      (codePoint >= 0x202a && codePoint <= 0x202e) ||
      (codePoint >= 0x2066 && codePoint <= 0x2069)
    )
      continue

    sanitized += character
  }

  return sanitized
}

function oneLine(text: string): string {
  return terminalText(text.replace(/\s+/g, " ")).trim()
}

function wrapSelection(index: number, delta: number, length: number): number {
  if (length === 0) return 0

  return (index + delta + length) % length
}

export interface RunEntry {
  runId: string
  details: WorkflowDetails
  live: boolean
}

function runsDir(): string {
  return path.join(getAgentDir(), "workflows")
}

const ArtifactString = v.fallback(v.optional(v.string()), undefined)

const ArtifactNumber = v.fallback(v.optional(v.number()), undefined)

const TranscriptArtifact = v.object({
  role: v.picklist(["user", "assistant", "thinking", "tool", "toolResult"]),
  text: v.string(),
  name: ArtifactString,
  isError: v.optional(v.unknown()),
  timestamp: ArtifactNumber,
})

const AgentArtifact = v.object({
  index: ArtifactNumber,
  label: ArtifactString,
  phase: ArtifactString,
  state: v.optional(v.unknown()),
  model: ArtifactString,
  contextWindow: ArtifactNumber,
  startedAt: ArtifactNumber,
  finishedAt: ArtifactNumber,
  error: ArtifactString,
  preview: ArtifactString,
  usage: v.optional(v.unknown()),
  transcript: v.optional(v.unknown()),
})

const UsageArtifact = v.object({
  input: v.fallback(v.optional(v.number(), 0), 0),
  output: v.fallback(v.optional(v.number(), 0), 0),
  cacheRead: v.fallback(v.optional(v.number(), 0), 0),
  cacheWrite: v.fallback(v.optional(v.number(), 0), 0),
  cost: v.fallback(v.optional(v.number(), 0), 0),
  turns: v.fallback(v.optional(v.number(), 0), 0),
  contextTokens: ArtifactNumber,
})

const PhaseArtifact = v.object({ title: v.string(), detail: ArtifactString })

const MetaArtifact = v.object({
  name: ArtifactString,
  description: ArtifactString,
  phases: v.optional(v.unknown()),
})

const WorkflowArtifact = v.object({
  meta: v.optional(v.unknown()),
  agents: v.optional(v.unknown()),
  startedAt: ArtifactNumber,
  finishedAt: ArtifactNumber,
  phases: v.optional(v.unknown()),
  status: v.optional(v.unknown()),
  sessionId: ArtifactString,
  name: ArtifactString,
  description: ArtifactString,
  background: v.optional(v.unknown()),
  currentPhase: ArtifactString,
  result: v.optional(v.unknown()),
  resultArtifact: ArtifactString,
  transcriptArtifact: ArtifactString,
  error: ArtifactString,
})

function normalizeTranscript<T>(value: T): TranscriptEntry[] {
  if (!Array.isArray(value)) return []
  const transcript: TranscriptEntry[] = []

  for (const item of value) {
    const parsed = v.safeParse(TranscriptArtifact, item)

    if (!parsed.success) continue
    const entry = parsed.output
    transcript.push({
      role: entry.role,
      text: entry.text,
      name: entry.name,
      isError: entry.isError === true,
      timestamp: entry.timestamp,
    })
  }

  return transcript
}

/** Leniently normalize a workflow.json (including runs from older tooling). */
export function normalizeDetails<T>(
  runId: string,
  raw: T,
): WorkflowDetails | undefined {
  const parsed = v.safeParse(WorkflowArtifact, raw)

  if (!parsed.success) return undefined
  const record = parsed.output
  const parsedMeta = v.safeParse(MetaArtifact, record.meta)
  const meta = parsedMeta.success ? parsedMeta.output : undefined

  const rawAgents = Array.isArray(record.agents) ? record.agents : []
  const startedAt = record.startedAt ?? 0
  const agents: AgentRecord[] = []

  for (const item of rawAgents) {
    const parsedAgent = v.safeParse(AgentArtifact, item)

    if (!parsedAgent.success) continue
    const a = parsedAgent.output
    const parsedUsage = v.safeParse(UsageArtifact, a.usage)

    const state =
      a.state === "error" || a.state === "failed"
        ? "error"
        : a.state === "running"
          ? "running"
          : "done"

    agents.push({
      index: a.index ?? agents.length + 1,
      label: a.label ?? `agent-${agents.length + 1}`,
      phase: a.phase,
      state,
      model: a.model,
      contextWindow:
        a.contextWindow !== undefined &&
        Number.isFinite(a.contextWindow) &&
        a.contextWindow > 0
          ? a.contextWindow
          : undefined,
      startedAt: a.startedAt ?? startedAt,
      finishedAt: a.finishedAt,
      error: a.error !== "[undefined]" ? a.error : undefined,
      preview: a.preview ?? "",
      usage: parsedUsage.success
        ? parsedUsage.output
        : {
            input: 0,
            output: 0,
            cacheRead: 0,
            cacheWrite: 0,
            cost: 0,
            turns: 0,
          },
      transcript: normalizeTranscript(a.transcript),
    })
  }

  const rawPhases = Array.isArray(record.phases)
    ? record.phases
    : Array.isArray(meta?.phases)
      ? meta.phases
      : []

  const phases: WorkflowDetails["phases"] = []

  for (const item of rawPhases) {
    const parsedPhase = v.safeParse(PhaseArtifact, item)

    if (!parsedPhase.success) continue

    const phase: WorkflowDetails["phases"][number] = {
      title: parsedPhase.output.title,
    }

    if (parsedPhase.output.detail !== undefined)
      phase.detail = parsedPhase.output.detail

    phases.push(phase)
  }

  const status =
    record.status === "running" ||
    record.status === "failed" ||
    record.status === "aborted"
      ? record.status
      : "completed"

  return {
    runId,
    sessionId: record.sessionId,
    name: record.name ?? meta?.name,
    description: record.description ?? meta?.description,
    background: record.background === true,
    status,
    startedAt,
    finishedAt: record.finishedAt,
    phases,
    currentPhase: record.currentPhase,
    agents,
    result: record.result,
    resultArtifact: record.resultArtifact,
    transcriptArtifact: record.transcriptArtifact,
    error: record.error,
  }
}

export function sessionWorkflowRunIds(ctx: ExtensionContext): Set<string> {
  const runIds = new Set<string>()

  for (const entry of ctx.sessionManager.getEntries()) {
    if (
      entry.type !== "message" ||
      entry.message.role !== "toolResult" ||
      entry.message.toolName !== "workflow"
    ) {
      continue
    }

    const details = entry.message.details

    const parsed = v.safeParse(v.object({ runId: v.string() }), details)

    if (parsed.success) runIds.add(parsed.output.runId)
  }

  return runIds
}

export function loadRunEntries(
  active: Map<string, WorkflowDetails>,
  sessionId: string,
  referencedRunIds: ReadonlySet<string>,
): RunEntry[] {
  let names: string[] = []

  try {
    names = fs.readdirSync(runsDir()).filter((name) => name.startsWith("wf_"))
  } catch {
    // No runs yet.
  }

  const entries: RunEntry[] = []

  for (const runId of names) {
    const live = active.get(runId)

    if (live) {
      entries.push({ runId, details: live, live: true })
      continue
    }

    try {
      const raw = JSON.parse(
        fs.readFileSync(path.join(runsDir(), runId, "workflow.json"), "utf8"),
      )

      const details = normalizeDetails(runId, raw)

      if (
        details &&
        (details.sessionId === sessionId || referencedRunIds.has(runId))
      ) {
        const runDir = path.join(runsDir(), runId)

        if (details.resultArtifact) {
          try {
            details.result = JSON.parse(
              fs.readFileSync(
                path.join(runDir, path.basename(details.resultArtifact)),
                "utf8",
              ),
            )
          } catch {
            // Keep the compact compatibility marker from workflow.json.
          }
        }

        if (details.transcriptArtifact) {
          try {
            const transcripts = v.parse(
              v.record(v.string(), v.unknown()),
              JSON.parse(
                fs.readFileSync(
                  path.join(runDir, path.basename(details.transcriptArtifact)),
                  "utf8",
                ),
              ),
            )

            for (const agent of details.agents) {
              agent.transcript = normalizeTranscript(
                transcripts[String(agent.index)],
              )
            }
          } catch {
            // Older or partially written artifacts simply lack transcripts.
          }
        }

        if (details.status === "running") {
          details.status = "aborted"
          details.finishedAt = details.finishedAt ?? Date.now()
          details.error =
            details.error ?? "Recovered stale run that was not active"

          for (const agent of details.agents) {
            if (agent.state !== "running") continue
            agent.state = "error"
            agent.error = agent.error ?? "Run ended before this agent settled"
            agent.finishedAt = details.finishedAt
          }
        }

        entries.push({ runId, details, live: false })
      }
    } catch {
      // Skip unreadable runs.
    }
  }

  return entries.sort((a, b) => b.details.startedAt - a.details.startedAt)
}

function buildReport(details: WorkflowDetails): string {
  const { done, failed } = countStates(details)

  const lines: string[] = [
    `# Workflow ${details.name ?? details.runId}`,
    "",
    `- Run: ${details.runId}`,
    `- Status: ${statusWord(details.status)}`,
    `- Agents: ${done}/${details.agents.length} ok${failed ? `, ${failed} failed` : ""}`,
    `- Elapsed: ${formatElapsed(details.startedAt, details.finishedAt)}`,
  ]

  const totals = formatUsage(aggregateUsage(details.agents))

  if (totals) lines.push(`- Usage: ${totals}`)

  if (details.description) lines.push("", details.description)

  if (details.error) lines.push("", `**Error:** ${details.error}`)

  for (const group of phaseGroups(details, true)) {
    lines.push("", `## ${group.title}`, "")

    if (group.agents.length === 0) {
      lines.push("_no agents_")
      continue
    }

    for (const agent of group.agents) {
      const status =
        agent.state === "done"
          ? "ok"
          : agent.state === "error"
            ? "FAILED"
            : "running"

      const stats = [
        agent.model,
        agentContext(agent),
        formatElapsed(agent.startedAt, agent.finishedAt),
      ]
        .filter(Boolean)
        .join(" · ")

      lines.push(`- **${agent.label}**. ${status}${stats ? ` (${stats})` : ""}`)

      if (agent.error) lines.push(`  - error: ${agent.error}`)
    }
  }

  if (details.result !== undefined) {
    lines.push(
      "",
      "## Result",
      "",
      "```json",
      resultJson(details.result),
      "```",
    )
  }

  lines.push("")

  return lines.join("\n")
}

type View = "list" | "detail" | "transcript"

type DetailFocus = "phases" | "agents"

export class WorkflowDashboard {
  private view: View = "list"
  private entries: RunEntry[] = []
  private listIndex = 0
  private phaseIndex = 0
  private agentIndex = 0
  private detailFocus: DetailFocus = "phases"
  private transcriptScroll = 0
  private transcriptRowCount = 0
  private transcriptViewportSize = 1
  private current?: RunEntry
  private notice?: string
  private noticeAt = 0
  private disposed = false
  private timer?: ReturnType<typeof setInterval>
  private lastRefreshAt = 0
  private tui: TUI
  private theme: Theme
  private keybindings: Pick<KeybindingsManager, "getKeys" | "matches">
  private getActive: () => Map<string, WorkflowDetails>
  private sessionId: string
  private referencedRunIds: ReadonlySet<string>
  private close: () => void

  constructor(
    tui: TUI,
    theme: Theme,
    keybindings: Pick<KeybindingsManager, "getKeys" | "matches">,
    getActive: () => Map<string, WorkflowDetails>,
    sessionId: string,
    referencedRunIds: ReadonlySet<string>,
    close: () => void,
    initialRunId?: string,
  ) {
    this.tui = tui
    this.theme = theme
    this.keybindings = keybindings
    this.getActive = getActive
    this.sessionId = sessionId
    this.referencedRunIds = referencedRunIds
    this.close = close
    this.refresh()

    if (initialRunId) {
      const entry = this.entries.find(
        (e) => e.runId === initialRunId || e.runId.endsWith(initialRunId),
      )

      if (entry) {
        this.current = entry
        this.listIndex = this.entries.indexOf(entry)
        this.view = "detail"
      }
    }

    this.syncTimer()
  }

  dispose() {
    if (this.disposed) return
    this.disposed = true

    if (this.timer) clearInterval(this.timer)
    this.timer = undefined
  }

  invalidate() {
    // Rendering is derived on every call; no cached content to invalidate.
  }

  private needsTimer(): boolean {
    return (
      this.entries.some((entry) => entry.live) ||
      this.current?.live === true ||
      this.notice !== undefined
    )
  }

  private syncTimer() {
    if (this.disposed) return

    if (!this.needsTimer()) {
      if (this.timer) clearInterval(this.timer)
      this.timer = undefined

      return
    }

    if (this.timer) return

    this.timer = setInterval(() => {
      if (this.disposed) return

      if (Date.now() - this.lastRefreshAt >= ARTIFACT_REFRESH_MS) this.refresh()
      this.tui.requestRender()
      this.syncTimer()
    }, ACTIVITY_FRAME_MS)
  }

  private refresh() {
    const selected = this.entries[this.listIndex]?.runId
    this.entries = loadRunEntries(
      this.getActive(),
      this.sessionId,
      this.referencedRunIds,
    )

    if (selected) {
      const index = this.entries.findIndex((e) => e.runId === selected)

      if (index >= 0) this.listIndex = index
    }

    this.listIndex = Math.min(
      this.listIndex,
      Math.max(0, this.entries.length - 1),
    )

    if (this.current) {
      const refreshed = this.entries.find(
        (e) => e.runId === this.current?.runId,
      )

      if (refreshed) this.current = refreshed
    }

    if (this.notice && Date.now() - this.noticeAt > NOTICE_TTL_MS)
      this.notice = undefined

    this.lastRefreshAt = Date.now()
  }

  private groups(): PhaseGroup[] {
    if (!this.current) return []

    return phaseGroups(this.current.details, true)
  }

  private selectedGroup(): PhaseGroup | undefined {
    return this.groups()[this.phaseIndex]
  }

  private selectedAgent(): AgentRecord | undefined {
    return this.selectedGroup()?.agents[this.agentIndex]
  }

  private clampAgentIndex() {
    const agents = this.selectedGroup()?.agents ?? []
    this.agentIndex = Math.min(this.agentIndex, Math.max(0, agents.length - 1))
  }

  private saveReport() {
    const entry = this.current

    if (!entry) return
    const target = path.join(runsDir(), entry.runId, "report.md")

    try {
      fs.writeFileSync(target, buildReport(entry.details), "utf8")
      this.notice = `saved report.md · ${shortenHome(target)}`
    } catch (error) {
      this.notice = `save failed: ${error instanceof Error ? error.message : String(error)}`
    }

    this.noticeAt = Date.now()
  }

  handleInput(data: string) {
    const up = this.keybindings.matches(data, "tui.select.up") || data === "k"

    const down =
      this.keybindings.matches(data, "tui.select.down") || data === "j"

    const left =
      this.keybindings.matches(data, "tui.editor.cursorLeft") || data === "h"

    const right =
      this.keybindings.matches(data, "tui.editor.cursorRight") || data === "l"

    const confirm = this.keybindings.matches(data, "tui.select.confirm")
    const cancel = this.keybindings.matches(data, "tui.select.cancel")

    if (this.view === "list") {
      if (up) {
        this.listIndex = wrapSelection(this.listIndex, -1, this.entries.length)
      } else if (down) {
        this.listIndex = wrapSelection(this.listIndex, 1, this.entries.length)
      } else if (data === "g") {
        this.listIndex = 0
      } else if (data === "G") {
        this.listIndex = Math.max(0, this.entries.length - 1)
      } else if (confirm) {
        const entry = this.entries[this.listIndex]

        if (entry) {
          this.current = entry
          this.phaseIndex = 0
          this.agentIndex = 0
          this.detailFocus = "phases"
          this.view = "detail"
        }
      } else if (cancel) {
        this.close()

        return
      }
    } else if (this.view === "detail") {
      if (this.detailFocus === "phases") {
        if (up) {
          this.phaseIndex = wrapSelection(
            this.phaseIndex,
            -1,
            this.groups().length,
          )
          this.agentIndex = 0
        } else if (down) {
          this.phaseIndex = wrapSelection(
            this.phaseIndex,
            1,
            this.groups().length,
          )
          this.agentIndex = 0
        } else if (data === "g") {
          this.phaseIndex = 0
          this.agentIndex = 0
        } else if (data === "G") {
          this.phaseIndex = Math.max(0, this.groups().length - 1)
          this.agentIndex = 0
        } else if (
          right ||
          (confirm && (this.selectedGroup()?.agents.length ?? 0) > 0)
        ) {
          if ((this.selectedGroup()?.agents.length ?? 0) > 0) {
            this.detailFocus = "agents"
            this.clampAgentIndex()
          }
        } else if (cancel) {
          this.view = "list"
          this.refresh()
        }
      } else {
        const agents = this.selectedGroup()?.agents ?? []

        if (up) {
          this.agentIndex = wrapSelection(this.agentIndex, -1, agents.length)
        } else if (down) {
          this.agentIndex = wrapSelection(this.agentIndex, 1, agents.length)
        } else if (data === "g") {
          this.agentIndex = 0
        } else if (data === "G") {
          this.agentIndex = Math.max(0, agents.length - 1)
        } else if (left || cancel) {
          this.detailFocus = "phases"
        } else if (confirm && this.selectedAgent()) {
          this.transcriptScroll = 0
          this.view = "transcript"
        }
      }

      if (data === "s") this.saveReport()
    } else {
      const maxScroll = Math.max(
        0,
        this.transcriptRowCount - this.transcriptViewportSize,
      )

      const scrollStep =
        data === "j" || data === "k" ? TRANSCRIPT_SCROLL_STEP : 1

      const pageStep = Math.max(1, this.transcriptViewportSize - 2)

      if (up) {
        this.transcriptScroll = Math.max(0, this.transcriptScroll - scrollStep)
      } else if (down) {
        this.transcriptScroll = Math.min(
          maxScroll,
          this.transcriptScroll + scrollStep,
        )
      } else if (matchesKey(data, Key.ctrl("u"))) {
        this.transcriptScroll = Math.max(0, this.transcriptScroll - pageStep)
      } else if (matchesKey(data, Key.ctrl("d"))) {
        this.transcriptScroll = Math.min(
          maxScroll,
          this.transcriptScroll + pageStep,
        )
      } else if (data === "g") {
        this.transcriptScroll = 0
      } else if (data === "G") {
        this.transcriptScroll = maxScroll
      } else if (cancel || left) {
        this.view = "detail"
        this.detailFocus = "agents"
      }
    }

    this.syncTimer()
    this.tui.requestRender()
  }

  render(width: number): string[] {
    if (width <= 0) return []

    const height = Math.max(0, this.tui.terminal.rows - 1)

    if (height === 0) return []

    const agent = this.selectedAgent()
    let lines: string[]

    if (this.view === "transcript" && this.current && agent) {
      lines = this.renderTranscript(this.current.details, agent, width, height)
    } else if (this.view === "detail" && this.current) {
      lines = this.renderDetail(this.current.details, width, height)
    } else {
      lines = this.renderList(width, height)
    }

    return lines
      .slice(0, height)
      .map((line) => truncateToWidth(line, width, ""))
  }

  private split(left: string, right: string, width: number): string {
    if (width <= 0) return ""

    if (width < 64) return truncateToWidth(`${left} ${right}`, width, "…")

    const rightText = truncateToWidth(right, width, "…")

    const leftText = truncateToWidth(
      left,
      Math.max(0, width - visibleWidth(rightText) - 1),
      "…",
    )

    const pad = Math.max(
      1,
      width - visibleWidth(leftText) - visibleWidth(rightText),
    )

    return leftText + " ".repeat(pad) + rightText
  }

  /** Scroll window keeping `selected` visible. */
  private windowed<T>(items: T[], selected: number, size: number) {
    if (items.length <= size) return { items, offset: 0 }

    const offset = Math.max(
      0,
      Math.min(selected - Math.floor(size / 2), items.length - size),
    )

    return { items: items.slice(offset, offset + size), offset }
  }

  private keys(binding: Parameters<KeybindingsManager["getKeys"]>[0]) {
    return this.keybindings.getKeys(binding).join("/") || "unbound"
  }

  private hintLine(hint: string, width: number): string {
    const text = this.notice ? oneLine(this.notice) : hint
    const color = this.notice ? "accent" : "dim"

    return truncateToWidth(this.theme.fg(color, `${GUTTER}${text}`), width)
  }

  private renderList(width: number, height: number): string[] {
    const theme = this.theme

    const footer = this.hintLine(
      `${this.keys("tui.select.up")}/${this.keys("tui.select.down")} select · ${this.keys("tui.select.confirm")} open · ${this.keys("tui.select.cancel")} close`,
      width,
    )

    const header = this.split(
      `${GUTTER}${theme.bold(theme.fg("accent", "Workflows"))}`,
      theme.fg(
        "dim",
        `${this.entries.length} run${this.entries.length === 1 ? "" : "s"}`,
      ),
      width,
    )

    if (height === 1) return [footer]
    const bodyHeight = Math.max(0, height - 2)
    const body: string[] = []

    if (this.entries.length === 0) {
      body.push(theme.fg("dim", `${GUTTER}no workflow runs yet`))
    } else {
      const { items, offset } = this.windowed(
        this.entries,
        this.listIndex,
        bodyHeight,
      )

      for (const [visibleIndex, entry] of items.entries()) {
        const index = offset + visibleIndex
        const selected = index === this.listIndex
        const details = entry.details
        const label = oneLine(details.name ?? details.runId)

        const title = selected
          ? theme.fg("accent", label)
          : theme.fg("text", label)

        const { done, failed } = countStates(details)
        const settled = done + failed
        const left = `${selected ? theme.fg("accent", "› ") : GUTTER}${statusGlyph(details.status, theme)} ${title} ${theme.fg("dim", oneLine(details.runId))}`

        const right = theme.fg(
          "muted",
          `${settled}/${details.agents.length} · ${formatElapsed(details.startedAt, details.finishedAt)} · ${statusWord(details.status)}`,
        )

        const line =
          width >= 64
            ? this.split(left, right, width)
            : truncateToWidth(`${left} ${right}`, width, "…")

        body.push(line)
      }
    }

    while (body.length < bodyHeight) body.push("")

    return [header, ...body.slice(0, bodyHeight), footer]
  }

  private phaseRow(group: PhaseGroup, index: number): string {
    const selected = index === this.phaseIndex
    const focused = selected && this.detailFocus === "phases"

    const done = group.agents.filter(
      (agent) => agent.state !== "running",
    ).length

    const title = oneLine(group.title)

    const styledTitle = focused
      ? this.theme.fg("accent", title)
      : this.theme.fg("text", title)

    const count = group.agents.length
      ? `${done}/${group.agents.length}`
      : "empty"

    const row = `${focused ? this.theme.fg("accent", "› ") : "  "}${groupGlyph(group, this.theme)} ${styledTitle} ${this.theme.fg("dim", count)}`

    return row
  }

  private agentRow(agent: AgentRecord, index: number): string {
    const selected = index === this.agentIndex
    const focused = selected && this.detailFocus === "agents"

    const label = focused
      ? this.theme.fg("accent", oneLine(agent.label))
      : this.theme.fg("text", oneLine(agent.label))

    const metadata = [
      oneLine(agent.model ?? ""),
      agentContext(agent),
      formatElapsed(agent.startedAt, agent.finishedAt),
      formatUsage(agent.usage),
    ]
      .filter(Boolean)
      .join(" · ")

    const row = `${focused ? this.theme.fg("accent", "› ") : "  "}${stateGlyph(agent.state, this.theme)} ${label}${metadata ? this.theme.fg("dim", ` · ${metadata}`) : ""}`

    return row
  }

  private renderDetailFocus(
    groups: PhaseGroup[],
    selectedGroup: PhaseGroup | undefined,
    bodyHeight: number,
  ): string[] {
    const theme = this.theme

    if (this.detailFocus === "phases") {
      if (groups.length === 0)
        return [theme.fg("dim", `${GUTTER}no agents or phases yet`)]

      const visible = this.windowed(groups, this.phaseIndex, bodyHeight)

      return visible.items.map(
        (group, index) =>
          `${GUTTER}${this.phaseRow(group, visible.offset + index)}`,
      )
    }

    const agents = selectedGroup?.agents ?? []

    if (agents.length === 0)
      return [theme.fg("dim", `${GUTTER}no agents in this phase yet`)]

    const visible = this.windowed(agents, this.agentIndex, bodyHeight)
    const rows: string[] = []

    for (const [visibleIndex, agent] of visible.items.entries()) {
      rows.push(
        `${GUTTER}${this.agentRow(agent, visible.offset + visibleIndex)}`,
      )

      if (agent.error)
        rows.push(
          theme.fg("error", `${GUTTER}  error: ${oneLine(agent.error)}`),
        )
    }

    return rows
  }

  private renderDetailColumns(
    groups: PhaseGroup[],
    selectedGroup: PhaseGroup | undefined,
    width: number,
    bodyHeight: number,
  ): string[] {
    const hasHeadings = bodyHeight > 2
    const dataHeight = Math.max(0, bodyHeight - Number(hasHeadings))
    const leftWidth = Math.floor((width - GUTTER.length - 2) / 3)
    const rightWidth = Math.max(0, width - GUTTER.length - 2 - leftWidth)
    const phaseWindow = this.windowed(groups, this.phaseIndex, dataHeight)
    const agentList = selectedGroup?.agents ?? []
    const agentWindow = this.windowed(agentList, this.agentIndex, dataHeight)

    const phaseRows = groups.length
      ? phaseWindow.items.map((group, index) =>
          this.phaseRow(group, phaseWindow.offset + index),
        )
      : [this.theme.fg("dim", "no agents or phases yet")]

    const agentRows = agentList.length
      ? agentWindow.items.flatMap((agent, index) => [
          this.agentRow(agent, agentWindow.offset + index),
          ...(agent.error
            ? [this.theme.fg("error", `error: ${oneLine(agent.error)}`)]
            : []),
        ])
      : [
          this.theme.fg(
            "dim",
            groups.length ? "no agents in this phase yet" : "",
          ),
        ]

    const lines: string[] = []

    for (let index = 0; index < bodyHeight; index++) {
      const isHeading = hasHeadings && index === 0
      const rowIndex = index - Number(hasHeadings)

      const left = isHeading
        ? this.theme.fg("muted", this.theme.bold("Phases"))
        : (phaseRows[rowIndex] ?? "")

      const right = isHeading
        ? this.theme.fg(
            "muted",
            this.theme.bold(
              selectedGroup
                ? `${oneLine(selectedGroup.title)} · ${agentList.length} agents`
                : "Agents",
            ),
          )
        : (agentRows[rowIndex] ?? "")

      const leftText = truncateToWidth(left, leftWidth, "…")
      const rightText = truncateToWidth(right, rightWidth, "…")

      lines.push(
        `${GUTTER}${leftText}${" ".repeat(Math.max(0, leftWidth - visibleWidth(leftText)))}  ${rightText}`,
      )
    }

    return lines
  }

  private renderDetail(
    details: WorkflowDetails,
    width: number,
    height: number,
  ): string[] {
    const theme = this.theme
    const { done, failed } = countStates(details)
    const settled = done + failed

    const summary =
      theme.fg(
        "muted",
        `${settled}/${details.agents.length} agents · ${formatElapsed(details.startedAt, details.finishedAt)} · `,
      ) + theme.fg(statusColor(details.status), statusWord(details.status))

    const header = this.split(
      `${GUTTER}${statusGlyph(details.status, theme)} ${theme.bold(theme.fg("accent", `Workflow · ${oneLine(details.name ?? details.runId)}`))}`,
      summary,
      width,
    )

    const totals = formatUsage(aggregateUsage(details.agents))

    const metadata = [
      oneLine(details.description ?? details.runId),
      totals,
      details.error ? `error: ${oneLine(details.error)}` : "",
    ]
      .filter(Boolean)
      .join(" · ")

    const headerHeight = height >= 4 ? 2 : 1
    const headers = [header]

    if (headerHeight === 2)
      headers.push(
        truncateToWidth(`${GUTTER}${theme.fg("dim", metadata)}`, width),
      )

    const groups = this.groups()
    this.phaseIndex = Math.min(this.phaseIndex, Math.max(0, groups.length - 1))
    const selectedGroup = groups[this.phaseIndex]
    this.clampAgentIndex()
    const bodyHeight = Math.max(0, height - headerHeight - 1)

    const body =
      width >= 80
        ? this.renderDetailColumns(groups, selectedGroup, width, bodyHeight)
        : this.renderDetailFocus(groups, selectedGroup, bodyHeight)

    while (body.length < bodyHeight) body.push("")

    const hint =
      this.detailFocus === "phases"
        ? `j/k select phase · l/${this.keys("tui.editor.cursorRight")}/${this.keys("tui.select.confirm")} agents · ${this.keys("tui.select.cancel")} back · s save report`
        : `j/k select agent · h/${this.keys("tui.editor.cursorLeft")}/${this.keys("tui.select.cancel")} phases · ${this.keys("tui.select.confirm")} transcript · s save report`

    return [
      ...headers,
      ...body.slice(0, bodyHeight),
      this.hintLine(hint, width),
    ]
  }

  private transcriptRows(agent: AgentRecord, width: number): string[] {
    const theme = this.theme
    const contentWidth = Math.max(1, width - GUTTER.length)
    const rows: string[] = []

    if (agent.transcript.length === 0)
      return [
        theme.fg(
          "dim",
          `${GUTTER}transcript unavailable (this run predates transcript capture)`,
        ),
      ]

    for (const entry of agent.transcript) {
      if (entry.role === "assistant" || entry.role === "thinking") {
        const text = terminalText(entry.text).trim()

        if (text) {
          const markdown = new Markdown(text, 0, 0, getMarkdownTheme()).render(
            contentWidth,
          )

          for (const line of markdown) {
            rows.push(
              truncateToWidth(
                `${GUTTER}${entry.role === "thinking" ? theme.fg("muted", theme.italic(line)) : line}`,
                width,
              ),
            )
          }
        }
      } else {
        const text = terminalText(entry.text).trim()

        const prefix =
          entry.role === "user"
            ? `${theme.fg("accent", theme.bold("User"))} `
            : entry.role === "tool"
              ? `${theme.fg("warning", "·")} `
              : `${theme.fg(entry.isError ? "error" : "success", entry.isError ? "✕" : "✓")} `

        const label = entry.role === "tool" ? oneLine(entry.name ?? "tool") : ""

        const body =
          entry.role === "tool"
            ? `${theme.fg("toolTitle", theme.bold(label))}${text ? ` ${theme.fg("toolOutput", text)}` : ""}`
            : theme.fg(entry.isError ? "error" : "dim", text)

        const wrapped = wrapTextWithAnsi(
          body,
          Math.max(1, width - GUTTER.length - visibleWidth(prefix)),
        )

        for (let index = 0; index < wrapped.length; index++) {
          const lead = index === 0 ? prefix : " ".repeat(visibleWidth(prefix))
          rows.push(truncateToWidth(`${GUTTER}${lead}${wrapped[index]}`, width))
        }
      }

      if (rows.length > 0 && rows.at(-1) !== "") rows.push("")
    }

    while (rows.length > 0 && rows.at(-1) === "") rows.pop()

    return rows
  }

  private renderTranscript(
    details: WorkflowDetails,
    agent: AgentRecord,
    width: number,
    height: number,
  ): string[] {
    const theme = this.theme
    const rows = this.transcriptRows(agent, width)
    const headerHeight = height >= 4 ? 2 : 1
    const bodyHeight = Math.max(0, height - headerHeight - 1)
    this.transcriptRowCount = rows.length
    this.transcriptViewportSize = bodyHeight
    const maxScroll = Math.max(0, rows.length - bodyHeight)
    this.transcriptScroll = Math.min(this.transcriptScroll, maxScroll)

    const visible = rows.slice(
      this.transcriptScroll,
      this.transcriptScroll + bodyHeight,
    )

    const last = Math.min(rows.length, this.transcriptScroll + bodyHeight)
    const position = `${rows.length ? this.transcriptScroll + 1 : 0}-${last}/${rows.length}`
    const header = `${GUTTER}${stateGlyph(agent.state, theme)} ${theme.bold(theme.fg("accent", `Workflow agent · ${oneLine(agent.label)}`))}`

    const metadata = [
      oneLine(details.name ?? details.runId),
      oneLine(agent.phase ?? "unphased"),
      oneLine(agent.model ?? ""),
      agentContext(agent),
      formatUsage(agent.usage),
      formatElapsed(agent.startedAt, agent.finishedAt),
      `${agent.transcript.length} entries`,
      `Transcript ${position}`,
    ]
      .filter(Boolean)
      .join(" · ")

    const headers = [header]

    if (headerHeight === 2)
      headers.push(
        truncateToWidth(`${GUTTER}${theme.fg("muted", metadata)}`, width),
      )

    while (visible.length < bodyHeight) visible.push("")

    const hint = `${this.keys("tui.select.up")}/${this.keys("tui.select.down")}/jk scroll · ctrl-u/d page · g/G top/bottom · h/${this.keys("tui.editor.cursorLeft")}/${this.keys("tui.select.cancel")} back`

    return [...headers, ...visible, this.hintLine(hint, width)]
  }
}

function groupGlyph(group: PhaseGroup, theme: Theme): string {
  if (group.agents.some((agent) => agent.state === "running"))
    return stateGlyph("running", theme)

  if (group.agents.some((agent) => agent.state === "error"))
    return stateGlyph("error", theme)

  return group.agents.length === 0
    ? theme.fg("dim", "·")
    : stateGlyph("done", theme)
}

/** Open the dashboard as a full-screen overlay. */
export async function showWorkflowDashboard(
  ctx: ExtensionContext,
  getActive: () => Map<string, WorkflowDetails>,
  initialRunId?: string,
): Promise<void> {
  await ctx.ui.custom<void>(
    (tui, theme, keybindings, done) => {
      const dashboard: WorkflowDashboard = new WorkflowDashboard(
        tui,
        theme,
        keybindings,
        getActive,
        ctx.sessionManager.getSessionId(),
        sessionWorkflowRunIds(ctx),
        () => {
          dashboard.dispose()
          done(undefined)
        },
        initialRunId,
      )

      return dashboard
    },
    {
      overlay: true,
      overlayOptions: { anchor: "center", width: "100%", maxHeight: "100%" },
    },
  )
}
