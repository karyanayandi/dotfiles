import assert from "node:assert/strict"
import { test } from "node:test"

import { diffLines, parseDiff, renderDiffText } from "./diff.ts"

const theme = {
  fg: (color: string, text: string) => `<${color}>${text}</${color}>`,
  bold: (text: string) => `**${text}**`,
} as never

test("parseDiff handles legacy and canonical line formats", () => {
  const entries = parseDiff("+13 foo\n-12 bar\n 11 baz\n@@ -12,3 +13,5 @@")
  assert.deepEqual(
    entries.map((e) => [e.kind, e.oldNum, e.newNum, e.content]),
    [
      ["add", null, 13, "foo"],
      ["remove", 12, null, "bar"],
      ["context", 11, 11, "baz"],
      ["meta", null, null, "@@ -12,3 +13,5 @@"],
    ],
  )
  const canonical = parseDiff("+13|foo\n-12|bar\n 11|baz")
  assert.equal(canonical[0]?.kind, "add")
  assert.equal(canonical[0]?.content, "foo")
  assert.equal(canonical[1]?.kind, "remove")
  assert.equal(canonical[2]?.kind, "context")
})

test("diffLines computes LCS diff with correct numbering", () => {
  const entries = diffLines(["a", "b", "c", "d"], ["a", "x", "c", "e"])
  assert.deepEqual(
    entries.map((e) => [e.kind, e.oldNum, e.newNum, e.content]),
    [
      ["context", 1, 1, "a"],
      ["remove", 2, null, "b"],
      ["add", null, 2, "x"],
      ["context", 3, 3, "c"],
      ["remove", 4, null, "d"],
      ["add", null, 4, "e"],
    ],
  )
})

test("renderDiffText collapses long diffs and numbers lines", () => {
  const big = Array.from(
    { length: 40 },
    (_, i) => `+${i + 1}|line ${i + 1}`,
  ).join("\n")
  const collapsed = renderDiffText(parseDiff(big), theme, false)
  const collapsedLines = collapsed.split("\n")
  assert.equal(collapsedLines.length, 25)
  assert.match(collapsedLines.at(-1) ?? "", /more lines/)
  const expanded = renderDiffText(parseDiff(big), theme, true)
  assert.equal(expanded.split("\n").length, 40)
  assert.match(expanded.split("\n")[0] ?? "", /toolDiffAdded.*1.*line 1/)
})

test("renderDiffText handles empty diff", () => {
  assert.equal(renderDiffText([], theme, false), "")
})
