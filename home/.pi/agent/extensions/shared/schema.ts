import { toJsonSchema, type JsonSchema } from "@valibot/to-json-schema"
import type * as v from "valibot"

type Schema = v.BaseSchema<unknown, unknown, v.BaseIssue<unknown>>
type UnsafeSchema<T> = JsonSchema & { "~unsafe": T }

/** Convert Valibot to the JSON Schema expected by pi while preserving input types. */
export function toolSchema<TSchema extends Schema>(schema: TSchema) {
  const { $schema: _, ...jsonSchema } = toJsonSchema(schema)
  return {
    ...jsonSchema,
    "~unsafe": null,
  } as unknown as UnsafeSchema<v.InferOutput<TSchema>>
}

/** Mark an existing JSON Schema as type-unsafe without depending on TypeBox. */
export function unsafeSchema<T = unknown>(schema: JsonSchema) {
  return { ...schema, "~unsafe": null } as unknown as UnsafeSchema<T>
}
