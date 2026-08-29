import { randomUUID } from "node:crypto"
import { readFileSync } from "node:fs"
import { mkdir, rename, unlink, writeFile } from "node:fs/promises"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

class ConfigWriteError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options)
    this.name = "ConfigWriteError"
  }
}

export const REASONING_LEVELS = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
] as const

export type ReasoningLevel = (typeof REASONING_LEVELS)[number]

export interface SummaryConfig {
  readonly provider: string
  readonly model: string
  readonly reasoning: ReasoningLevel
}

export const DEFAULT_SUMMARY_CONFIG: SummaryConfig = {
  provider: "github-copilot",
  model: "gpt-4.1",
  reasoning: "off",
}

const extensionDirectory = dirname(dirname(fileURLToPath(import.meta.url)))
export const PRIVATE_CONFIG_PATH = join(
  extensionDirectory,
  "config.private.json",
)

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value)

const isReasoningLevel = (value: unknown): value is ReasoningLevel =>
  typeof value === "string" &&
  REASONING_LEVELS.includes(value as ReasoningLevel)

export function parseSummaryConfig(value: unknown) {
  if (!isRecord(value)) return DEFAULT_SUMMARY_CONFIG

  if (
    typeof value.provider !== "string" ||
    !value.provider.trim() ||
    typeof value.model !== "string" ||
    !value.model.trim() ||
    !isReasoningLevel(value.reasoning)
  ) {
    return DEFAULT_SUMMARY_CONFIG
  }

  return {
    provider: value.provider.trim(),
    model: value.model.trim(),
    reasoning: value.reasoning,
  } satisfies SummaryConfig
}

export function loadSummaryConfig() {
  try {
    return parseSummaryConfig(
      JSON.parse(readFileSync(PRIVATE_CONFIG_PATH, "utf8")),
    )
  } catch {
    return DEFAULT_SUMMARY_CONFIG
  }
}

export function saveSummaryConfig(config: SummaryConfig, signal?: AbortSignal) {
  const tempPath = `${PRIVATE_CONFIG_PATH}.${process.pid}.${randomUUID()}.tmp`
  const writeSignal = signal
    ? AbortSignal.any([signal, AbortSignal.timeout(5_000)])
    : AbortSignal.timeout(5_000)

  return (async () => {
    try {
      await mkdir(dirname(PRIVATE_CONFIG_PATH), { recursive: true })
      try {
        await writeFile(tempPath, `${JSON.stringify(config, null, 2)}\n`, {
          encoding: "utf8",
          mode: 0o600,
          signal: writeSignal,
        })
        await rename(tempPath, PRIVATE_CONFIG_PATH)
      } catch (error) {
        await unlink(tempPath).catch(() => undefined)
        throw error
      }
    } catch (cause) {
      throw new ConfigWriteError(
        cause instanceof Error ? cause.message : String(cause),
        { cause },
      )
    }
  })()
}
