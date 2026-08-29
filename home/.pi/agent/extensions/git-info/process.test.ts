import assert from "node:assert/strict"
import test from "node:test"
import { runCommand } from "./src/process.ts"

const runNode = (source: string, timeout = 1_000) =>
  runCommand(
    process.execPath,
    ["--input-type=module", "--eval", source],
    process.cwd(),
    timeout,
  )

test("captures output and tolerates command failures", async () => {
  const success = await runNode(
    'process.stdout.write("out"); process.stderr.write("err")',
  )
  assert.deepEqual(success, { code: 0, stderr: "err", stdout: "out" })

  const failure = await runNode("process.exitCode = 7")
  assert.equal(failure.code, 7)
})

test("renders platform failures without making callers handle them", async () => {
  const command = "git-info-command-that-does-not-exist"
  const result = await runCommand(command, [], process.cwd(), 1_000)

  assert.equal(result.code, 1)
  assert.match(result.stderr, new RegExp(`Failed to run ${command}:`))
  assert.match(result.stderr, /NotFound|not found|ENOENT/i)
})

test("reports command timeouts as failures", async () => {
  const result = await runNode("setTimeout(() => {}, 1_000)", 20)
  assert.equal(result.code, -1)
})

test("aborts subprocesses when caller cancels", async () => {
  const controller = new AbortController()
  controller.abort()

  await assert.rejects(
    runCommand(
      process.execPath,
      ["--input-type=module", "--eval", "setTimeout(() => {}, 1_000)"],
      process.cwd(),
      1_000,
      controller.signal,
    ),
    /Operation was aborted/,
  )
})
