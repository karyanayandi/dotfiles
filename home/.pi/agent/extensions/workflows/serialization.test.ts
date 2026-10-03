import assert from "node:assert/strict"
import { mkdtempSync, readFileSync, rmSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import * as v from "valibot"
import { safeStringify, writeFileAtomic } from "./serialization.ts"

test("safeStringify handles cycles, bigint, depth, and size", () => {
  interface CyclicFixture {
    bigint: bigint
    nested: { deeper: { deepest: boolean } }
    large: string
    self?: CyclicFixture
  }

  const value: CyclicFixture = {
    bigint: 42n,
    nested: { deeper: { deepest: true } },
    large: "x".repeat(20_000),
  }

  value.self = value

  const text = safeStringify(value, {
    maxBytes: 2_048,
    maxDepth: 2,
    maxStringBytes: 512,
  })

  assert.ok(Buffer.byteLength(text, "utf8") <= 2_048)
  const parsed: unknown = JSON.parse(text)
  assert.ok(v.is(v.record(v.string(), v.unknown()), parsed))
  assert.match(text, /42n/)
  assert.match(text, /circular/)
  assert.match(text, /truncated/)
})

test("serialization preserves arbitrary primitive and unreadable property markers", () => {
  const value = {
    missing: undefined,
    nan: Number.NaN,
    infinity: Infinity,
    symbol: Symbol("fixture"),
    callable: function fixture() {
      return "unused"
    },
    date: new Date("2020-01-01T00:00:00Z"),
    invalidDate: new Date(Number.NaN),
    get unreadable() {
      throw new Error("denied")
    },
  }

  assert.deepEqual(JSON.parse(safeStringify(value)), {
    missing: "[undefined]",
    nan: "[number: NaN]",
    infinity: "[number: Infinity]",
    symbol: "[symbol: fixture]",
    callable: "[function: fixture]",
    date: "2020-01-01T00:00:00.000Z",
    invalidDate: "[date: invalid]",
    unreadable: "[unreadable property: denied]",
  })
  assert.equal(safeStringify(true), "true")
  assert.equal(safeStringify(null), "null")
})

test("atomic writes leave complete readable content", () => {
  const directory = mkdtempSync(join(tmpdir(), "pi-workflow-test-"))

  try {
    const file = join(directory, "artifact.json")
    writeFileAtomic(file, '{"value":1}')
    writeFileAtomic(file, '{"value":2}')
    assert.deepEqual(JSON.parse(readFileSync(file, "utf8")), { value: 2 })
  } finally {
    rmSync(directory, { recursive: true, force: true })
  }
})
