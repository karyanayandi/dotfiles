import * as v from "valibot"
import { jsonRecordSchema, jsonValueSchema } from "./json.ts"
import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { getAgentDir } from "@earendil-works/pi-coding-agent"
import {
  type JsonValue,
  REASONING_EFFORTS,
  type ReasoningEffort,
} from "./domain.ts"

const configPath = join(getAgentDir(), "subagent-defaults.json")

export interface SubagentDefaults {
  model?: string
  reasoningEffort?: ReasoningEffort
}

export const DEFAULT_SUBAGENT_DEFAULTS: SubagentDefaults = {}

export function parseSubagentDefaults(value: JsonValue): SubagentDefaults {
  if (!v.is(jsonRecordSchema, value)) return DEFAULT_SUBAGENT_DEFAULTS

  const model =
    value.model ??
    (v.is(jsonRecordSchema, value.models) ? value.models.pi : undefined)

  const reasoningEffort =
    value.reasoningEffort ??
    (v.is(jsonRecordSchema, value.reasoningEfforts)
      ? value.reasoningEfforts.pi
      : undefined)

  const defaults: SubagentDefaults = {}

  if (v.is(v.string(), model) && model.trim()) defaults.model = model.trim()

  if (v.is(v.picklist(REASONING_EFFORTS), reasoningEffort))
    defaults.reasoningEffort = reasoningEffort

  return defaults
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
