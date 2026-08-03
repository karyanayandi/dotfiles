import assert from "node:assert/strict"
import { test } from "node:test"

import { renderDefaultCall } from "./tools.ts"

const theme = {
  fg: (color: string, text: string) => `<${color}>${text}</${color}>`,
  bold: (text: string) => `**${text}**`,
} as never

test("renderDefaultCall shows name and compact args", () => {
  const line = renderDefaultCall(
    "ctx_execute",
    { language: "javascript", code: "const a = 1\nconst b = 2" },
    theme,
  )
  assert.match(line, /ctx_execute/)
  assert.match(line, /language=javascript/)
  assert.match(line, /code=const a = 1 const b = 2/)
})

test("renderDefaultCall truncates long values", () => {
  const line = renderDefaultCall("ctx_execute", { code: "x".repeat(200) }, theme)
  const plain = line
    .replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")
    .replace(/<\/?\w+>/g, "")
    .replace(/\s+/g, "")
  assert.match(plain, /code=x{39}…$/)
})

test("renderDefaultCall handles empty args", () => {
  assert.match(renderDefaultCall("ctx_stats", undefined, theme), /ctx_stats/)
  assert.match(renderDefaultCall("ctx_stats", {}, theme), /ctx_stats/)
  assert.match(
    renderDefaultCall("ctx_execute", { code: "\n  \n" }, theme),
    /ctx_execute/,
  )
})
