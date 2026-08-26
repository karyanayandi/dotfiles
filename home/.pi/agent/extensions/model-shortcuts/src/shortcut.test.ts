import assert from "node:assert/strict"
import { describe, test } from "node:test"
import { isShortcut } from "./shortcut.ts"

describe("isShortcut", () => {
  test("accepts Pi shortcut formats", () => {
    assert.equal(isShortcut("ctrl+1"), true)
    assert.equal(isShortcut("ctrl+shift+p"), true)
    assert.equal(isShortcut("ctrl++"), true)
    assert.equal(isShortcut("f12"), true)
  })

  test("rejects invalid shortcuts", () => {
    assert.equal(isShortcut("ctrl+ctrl+p"), false)
    assert.equal(isShortcut("ctrl+wat"), false)
    assert.equal(isShortcut("Ctrl+1"), false)
  })
})
