import { toJsonSchema, type JsonSchema } from "@valibot/to-json-schema"
import type * as v from "valibot"

type Schema = v.BaseSchema<unknown, unknown, v.BaseIssue<unknown>>
type UnsafeSchema<T> = JsonSchema & { "~unsafe"?: T }

export function toolSchema<TSchema extends Schema>(schema: TSchema) {
  const { $schema: _, ...jsonSchema } = toJsonSchema(schema)
  return jsonSchema as unknown as UnsafeSchema<v.InferOutput<TSchema>>
}

export function unsafeSchema<T = unknown>(schema: JsonSchema) {
  return { ...schema } as unknown as UnsafeSchema<T>
}
