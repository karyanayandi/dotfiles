import assert from "node:assert/strict"
import { test } from "node:test"
import * as v from "valibot"
import { toolSchema, unsafeSchema } from "./schema.ts"

test("toolSchema emits pi-compatible JSON Schema", () => {
  const schema = toolSchema(
    v.object({
      count: v.pipe(v.number(), v.integer(), v.minValue(1), v.maxValue(3)),
      source: v.optional(v.picklist(["web", "news"])),
    }),
  )

  assert.equal(schema.type, "object")
  assert.deepEqual(schema.required, ["count"])
  assert.deepEqual(schema.properties?.count, {
    type: "integer",
    minimum: 1,
    maximum: 3,
  })
  assert.deepEqual(schema.properties?.source, {
    enum: ["web", "news"],
    type: "string",
  })
  assert.equal(schema["~unsafe"], null)
})

test("unsafeSchema preserves caller JSON Schema", () => {
  assert.deepEqual(unsafeSchema({ type: "string", minLength: 1 }), {
    type: "string",
    minLength: 1,
    "~unsafe": null,
  })
})
