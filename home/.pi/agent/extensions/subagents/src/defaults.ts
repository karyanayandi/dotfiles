import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { getAgentDir } from "@earendil-works/pi-coding-agent"
import {
  BACKEND_NAMES,
  REASONING_EFFORTS,
  type BackendName,
  type ReasoningEffort,
} from "./domain.ts"

const configPath = join(getAgentDir(), "subagent-defaults.json")

export interface SubagentDefaults {
  readonly harness: BackendName
  readonly models: Partial<Record<BackendName, string>>
  readonly reasoningEfforts: Partial<Record<BackendName, ReasoningEffort>>
}

export const DEFAULT_SUBAGENT_DEFAULTS: SubagentDefaults = {
  harness: "pi",
  models: {},
  reasoningEfforts: {},
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value)

const isBackendName = (value: unknown): value is BackendName =>
  typeof value === "string" && BACKEND_NAMES.some((name) => name === value)

const isReasoningEffort = (value: unknown): value is ReasoningEffort =>
  typeof value === "string" &&
  REASONING_EFFORTS.some((effort) => effort === value)

export function parseSubagentDefaults(value: unknown) {
  if (!isRecord(value) || !isBackendName(value.harness)) {
    return DEFAULT_SUBAGENT_DEFAULTS
  }

  const modelValues = value.models
  const models = isRecord(modelValues)
    ? Object.fromEntries(
        BACKEND_NAMES.flatMap((harness) => {
          const model = modelValues[harness]
          return typeof model === "string" && model.trim()
            ? [[harness, model.trim()]]
            : []
        }),
      )
    : {}

  const reasoningEffortValues = value.reasoningEfforts
  const reasoningEfforts = isRecord(reasoningEffortValues)
    ? Object.fromEntries(
        BACKEND_NAMES.flatMap((harness) => {
          const effort = reasoningEffortValues[harness]
          return isReasoningEffort(effort) ? [[harness, effort]] : []
        }),
      )
    : {}

  return { harness: value.harness, models, reasoningEfforts }
}

export function loadSubagentDefaults() {
  if (!existsSync(configPath)) return DEFAULT_SUBAGENT_DEFAULTS

  try {
    return parseSubagentDefaults(JSON.parse(readFileSync(configPath, "utf8")))
  } catch (error) {
    console.error(`Subagent defaults: could not load ${configPath}: ${error}`)
    return DEFAULT_SUBAGENT_DEFAULTS
  }
}

export function saveSubagentDefaults(defaults: SubagentDefaults) {
  writeFileSync(configPath, `${JSON.stringify(defaults, null, 2)}\n`)
}
