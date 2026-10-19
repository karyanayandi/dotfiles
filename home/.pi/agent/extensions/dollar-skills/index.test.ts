import assert from "node:assert/strict"
import test from "node:test"
import { mkdtempSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"

import { expandDollarSkill, searchSkills } from "./index.ts"

test("expands dollar skills throughout prompts using native skill blocks", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "dollar-skills-"))
  t.after(() => rmSync(directory, { recursive: true, force: true }))
  const commands = ["react-doctor", "accessibility"].map((name) => {
    const path = join(directory, `${name}.md`)
    writeFileSync(
      path,
      `---\nname: ${name}\ndescription: Test skill\n---\n\nUse ${name}.\n`,
    )
    return { name: `skill:${name}`, sourceInfo: { path } }
  })
  const blocks = commands.map(
    ({ name, sourceInfo }) =>
      `<skill name="${name.slice(6)}" location="${sourceInfo.path}">\nReferences are relative to ${directory}.\n\nUse ${name.slice(6)}.\n</skill>`,
  )

  for (const [input, expected] of [
    ["$react-doctor src", `${blocks[0]} src`],
    ["  $react-doctor", `  ${blocks[0]}`],
    [
      "Use $react-doctor and $accessibility.",
      `Use ${blocks[0]} and ${blocks[1]}.`,
    ],
    ["$react-doctor\n$accessibility", `${blocks[0]}\n${blocks[1]}`],
    ["$react-doctor $react-doctor", `${blocks[0]} ${blocks[0]}`],
    ["$missing $accessibility", `$missing ${blocks[1]}`],
  ]) {
    assert.equal(expandDollarSkill(input, commands), expected)
  }

  for (const input of [
    "$missing",
    "cost $100",
    "x$react-doctor",
    "$react-doctor-extra",
    "$react-doctor_suffix",
  ]) {
    assert.equal(expandDollarSkill(input, commands), undefined)
  }
  rmSync(commands[0].sourceInfo.path)
  assert.throws(() => expandDollarSkill("$react-doctor", commands), /ENOENT/)
})

test("searches skill names and descriptions with literal case-insensitive terms", () => {
  const commands = [
    { name: "skill:react-doctor", description: "Diagnose React issues" },
    {
      name: "skill:accessibility",
      description: "Keyboard navigation and WCAG",
    },
  ]

  assert.deepEqual(searchSkills("doctor", commands), ["react-doctor"])
  assert.deepEqual(searchSkills("KEYBOARD", commands), ["accessibility"])
  assert.deepEqual(searchSkills("WCAG", commands), ["accessibility"])
  assert.deepEqual(searchSkills(".", commands), [])
  assert.deepEqual(searchSkills("0", commands), [])
  assert.deepEqual(searchSkills("", commands), [
    "react-doctor",
    "accessibility",
  ])
})
