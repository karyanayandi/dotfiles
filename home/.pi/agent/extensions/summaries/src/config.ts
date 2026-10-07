import * as v from "valibot"
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
  provider: "openai",
  model: "gpt-6-luna",
  reasoning: "off",
}

const extensionDirectory = dirname(dirname(fileURLToPath(import.meta.url)))

export const PRIVATE_CONFIG_PATH = join(
  extensionDirectory,
  "config.private.json",
)

const summaryConfigSchema = v.object({
  provider: v.pipe(v.string(), v.trim(), v.nonEmpty()),
  model: v.pipe(v.string(), v.trim(), v.nonEmpty()),
  reasoning: v.picklist(REASONING_LEVELS),
})

export function parseSummaryConfig<Value>(value: Value) {
  const result = v.safeParse(summaryConfigSchema, value)

  return result.success ? result.output : DEFAULT_SUMMARY_CONFIG
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
