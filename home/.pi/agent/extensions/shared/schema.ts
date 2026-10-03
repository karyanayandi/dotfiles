import { toJsonSchema, type JsonSchema } from "@valibot/to-json-schema"
import type * as v from "valibot"

type Schema = v.BaseSchema<unknown, unknown, v.BaseIssue<unknown>>

type UnsafeSchema<T> = JsonSchema & { "~unsafe": T }

export function toolSchema<TSchema extends Schema>(schema: TSchema) {
  const { $schema: _, ...jsonSchema } = toJsonSchema(schema)

  // SAFETY: Valibot generates this JSON Schema from TSchema; TypeBox's required marker carries only its static output type and must not reach providers.
  return jsonSchema as UnsafeSchema<v.InferOutput<TSchema>>
}

export function unsafeSchema(schema: JsonSchema) {
  return { ...schema }
}
