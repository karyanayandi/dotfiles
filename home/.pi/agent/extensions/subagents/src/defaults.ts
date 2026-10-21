import * as v from "valibot"
import { jsonRecordSchema, jsonValueSchema } from "./json.ts"
import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { getAgentDir } from "@earendil-works/pi-coding-agent"
import {
  BACKEND_NAMES,
  type JsonValue,
  type JsonRecord,
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

function isRecord(value: JsonValue): value is JsonRecord {
  return v.is(jsonRecordSchema, value)
}

function isBackendName(value: JsonValue): value is BackendName {
  return v.is(v.picklist(BACKEND_NAMES), value)
}

function isReasoningEffort(value: JsonValue): value is ReasoningEffort {
  return v.is(v.picklist(REASONING_EFFORTS), value)
}

export function parseSubagentDefaults(value: JsonValue) {
  if (!isRecord(value) || !isBackendName(value.harness)) {
    return DEFAULT_SUBAGENT_DEFAULTS
  }

  const modelValues = value.models

  const models = isRecord(modelValues)
    ? Object.fromEntries(
        BACKEND_NAMES.flatMap((harness) => {
          const model = modelValues[harness]

          return v.is(v.string(), model) && model.trim()
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
    const result = v.safeParse(
      jsonValueSchema,
      JSON.parse(readFileSync(configPath, "utf8")),
    )

    return result.success
      ? parseSubagentDefaults(result.output)
      : DEFAULT_SUBAGENT_DEFAULTS
  } catch (error) {
    console.error(
      `Subagent defaults: could not load ${configPath}: ${String(error)}`,
    )

    return DEFAULT_SUBAGENT_DEFAULTS
  }
}

export function saveSubagentDefaults(defaults: SubagentDefaults) {
  writeFileSync(configPath, `${JSON.stringify(defaults, null, 2)}\n`)
}
