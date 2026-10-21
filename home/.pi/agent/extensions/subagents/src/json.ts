import * as v from "valibot"
import type { JsonValue } from "./domain.ts"

export const jsonValueSchema: v.GenericSchema<JsonValue> = v.lazy(() =>
  v.union([
    v.string(),
    v.number(),
    v.boolean(),
    v.null(),
    v.undefined(),
    v.array(jsonValueSchema),
    v.record(v.string(), jsonValueSchema),
  ]),
)

export const jsonRecordSchema = v.record(v.string(), jsonValueSchema)
