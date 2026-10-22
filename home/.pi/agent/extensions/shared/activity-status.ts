import type { ExtensionContext } from "@earendil-works/pi-coding-agent"

type Theme = ExtensionContext["ui"]["theme"]

interface ActivityCounts {
  running: number
  done: number
  failed: number
}

export const ACTIVITY_FRAME_MS = 120

const spinnerFrames = ["◜", "◝", "◞", "◟"]

const inputSpinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

type ActivityState = "running" | "done" | "error" | "stopped" | "queued"

export function activityIndicator(
  theme: Theme,
  state: ActivityState,
  now = Date.now(),
) {
  if (state === "running") {
    const frame = Math.floor(now / ACTIVITY_FRAME_MS) % spinnerFrames.length

    return theme.fg("text", spinnerFrames[frame] ?? spinnerFrames[0])
  }

  if (state === "done") return theme.fg("success", "✓")

  if (state === "error") return theme.fg("error", "✕")

  if (state === "stopped") return theme.fg("muted", "▪")

  return theme.fg("warning", "○")
}

export function inputActivityIndicator(
  theme: Theme,
  working: boolean,
  now = Date.now(),
) {
  if (!working) return theme.fg("text", "┃")
  const frame = Math.floor(now / ACTIVITY_FRAME_MS) % inputSpinnerFrames.length

  return theme.fg("text", inputSpinnerFrames[frame] ?? inputSpinnerFrames[0])
}

export function formatActivityStatus(
  theme: Theme,
  label: "subagents" | "workflows" | "background terminal",
  counts: ActivityCounts,
) {
  const parts: string[] = []

  if (counts.running > 0) {
    parts.push(
      `${activityIndicator(theme, "running")} ${theme.fg("muted", `${counts.running} running`)}`,
    )
  }

  if (counts.done > 0) {
    parts.push(theme.fg("success", `✓ ${counts.done} done`))
  }

  if (counts.failed > 0) {
    parts.push(theme.fg("error", `✕ ${counts.failed} failed`))
  }

  const command = label === "background terminal" ? "ps" : label
  parts.push(theme.fg("accent", `/${command}`) + theme.fg("dim", " to view"))

  return `${theme.fg("muted", `${label}:`)} ${parts.join(theme.fg("dim", " · "))}`
}
