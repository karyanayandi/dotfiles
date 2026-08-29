import { homedir } from "node:os"
import { dirname, join } from "node:path"
import { readFile, rm } from "node:fs/promises"
import { expect, it } from "vitest"
import {
  buildFdArgs,
  buildRgArgs,
  FD_DEFAULT_LIMIT,
  normalizeSearchPath,
} from "./src/args.ts"
import {
  FD_INTEL_DARWIN_VERSION,
  InstallError,
  readBoundedResponse,
  releaseAsset,
  resolveBinary,
  TOOL_SPECS,
  UnsupportedPlatformError,
  type BinaryEnv,
  type ReleaseAsset,
  type ResolvedBinary,
} from "./src/binaries.ts"
import { formatCapturedOutput, formatOutput } from "./src/output.ts"
import { executeSearchProcess } from "./src/process.ts"
import { installNotifications, makeBinaryInitializers } from "./index.ts"

it("fd args: defaults list everything with default limit", () => {
  expect(buildFdArgs({})).toEqual([
    "--color=never",
    "--max-results",
    String(FD_DEFAULT_LIMIT),
    "--",
    "",
  ])
})

it("fd args: all options translate and pattern stays behind --", () => {
  expect(
    buildFdArgs({
      pattern: "-rf",
      path: "@src",
      type: "file",
      extension: ".ts",
      glob: true,
      hidden: true,
      max_depth: 3,
      limit: 50,
    }),
  ).toEqual([
    "--color=never",
    "--hidden",
    "--glob",
    "--type",
    "f",
    "--extension",
    "ts",
    "--max-depth",
    "3",
    "--max-results",
    "50",
    "--",
    "-rf",
    "src",
  ])
})

it("fd args: out-of-range values clamp", () => {
  expect(buildFdArgs({ max_depth: 500, limit: 1_000_000 })).toEqual([
    "--color=never",
    "--max-depth",
    "64",
    "--max-results",
    "10000",
    "--",
    "",
  ])
})

it("rg args: defaults use smart-case and safe separators", () => {
  expect(buildRgArgs({ pattern: "--help" })).toEqual([
    "--line-number",
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--smart-case",
    "--max-count",
    "100",
    "--",
    "--help",
  ])
})

it("rg args: all options translate", () => {
  expect(
    buildRgArgs({
      pattern: "TODO",
      path: "@lib",
      glob: "*.ts",
      file_type: "ts",
      case_sensitive: true,
      fixed_strings: true,
      hidden: true,
      context: 2,
      limit: 10,
    }),
  ).toEqual([
    "--line-number",
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--case-sensitive",
    "--fixed-strings",
    "--hidden",
    "--context",
    "2",
    "--glob",
    "*.ts",
    "--type",
    "ts",
    "--max-count",
    "10",
    "--",
    "TODO",
    "lib",
  ])
})

it("rg args: case_sensitive false forces ignore-case", () => {
  const args = buildRgArgs({ pattern: "x", case_sensitive: false })
  expect(args).toContain("--ignore-case")
  expect(args).not.toContain("--smart-case")
})

it("path normalization strips leading @ and expands ~", () => {
  expect(normalizeSearchPath("@src/lib")).toBe("src/lib")
  expect(normalizeSearchPath("~")).toBe(homedir())
  expect(normalizeSearchPath("~/projects")).toBe(join(homedir(), "projects"))
  expect(normalizeSearchPath(" plain ")).toBe("plain")
})

function makeEnv(options: {
  available?: string[]
  installShouldFail?: boolean
}): BinaryEnv & { installs: ReleaseAsset[]; probes: string[] } {
  const installs: ReleaseAsset[] = []
  const probes: string[] = []
  const installed = new Set<string>()
  return {
    installs,
    probes,
    async probe(command) {
      probes.push(command)
      return (
        (options.available ?? []).includes(command) || installed.has(command)
      )
    },
    async install(asset, destination) {
      if (options.installShouldFail) throw new InstallError("network down")
      installs.push(asset)
      installed.add(destination)
    },
  }
}

const darwinArm = { os: "darwin", arch: "arm64" } as const

it("binary resolution: system fd wins and nothing installs", async () => {
  const env = makeEnv({ available: ["fd"] })
  await expect(
    resolveBinary(TOOL_SPECS.fd, "/repo/bin", darwinArm, env),
  ).resolves.toEqual({
    tool: "fd",
    command: "fd",
    source: "system",
  })
  expect(env.installs).toHaveLength(0)
})

it("binary resolution: fdfind is accepted as system fd", async () => {
  const env = makeEnv({ available: ["fdfind"] })
  await expect(
    resolveBinary(TOOL_SPECS.fd, "/repo/bin", darwinArm, env),
  ).resolves.toEqual({
    tool: "fd",
    command: "fdfind",
    source: "system",
  })
  expect(env.installs).toHaveLength(0)
})

it("binary resolution: existing bin fallback is used silently", async () => {
  const env = makeEnv({ available: ["/repo/bin/rg"] })
  await expect(
    resolveBinary(TOOL_SPECS.rg, "/repo/bin", darwinArm, env),
  ).resolves.toEqual({
    tool: "rg",
    command: "/repo/bin/rg",
    source: "bundled",
  })
  expect(env.installs).toHaveLength(0)
})

it("binary resolution: missing everywhere triggers one install", async () => {
  const env = makeEnv({ available: [] })
  const resolved = await resolveBinary(
    TOOL_SPECS.rg,
    "/repo/bin",
    darwinArm,
    env,
  )

  expect(resolved.source).toBe("installed")
  expect(resolved.command).toBe("/repo/bin/rg")
  expect(env.installs).toHaveLength(1)
  expect(env.installs[0]?.url).toMatch(
    /^https:\/\/github\.com\/BurntSushi\/ripgrep\//,
  )
})

it("binary resolution: install failure surfaces typed error", async () => {
  const env = makeEnv({ available: [], installShouldFail: true })
  await expect(
    resolveBinary(TOOL_SPECS.fd, "/repo/bin", darwinArm, env),
  ).rejects.toMatchObject({
    name: "InstallError",
    message: "network down",
  })
})

it("binary resolution: unsupported platform fails without installing", async () => {
  const env = makeEnv({ available: [] })
  await expect(
    resolveBinary(
      TOOL_SPECS.fd,
      "/repo/bin",
      { os: "linux", arch: "s390x" },
      env,
    ),
  ).rejects.toBeInstanceOf(UnsupportedPlatformError)
  expect(env.installs).toHaveLength(0)
})

it("binary initialization caches failures independently", async () => {
  const env = makeEnv({ available: ["rg"], installShouldFail: true })
  const initializers = makeBinaryInitializers("/repo/bin", darwinArm, env)
  expect(env.probes).toEqual([])

  const fd = initializers.fd()
  expect(initializers.fd()).toBe(fd)
  await expect(fd).rejects.toBeInstanceOf(InstallError)
  await expect(initializers.rg()).resolves.toEqual({
    tool: "rg",
    command: "rg",
    source: "system",
  })
})

it("release assets cover macOS and Linux on arm64 and x64 over HTTPS", () => {
  for (const os of ["darwin", "linux"] as const) {
    for (const arch of ["arm64", "x64"] as const) {
      for (const tool of ["fd", "rg"] as const) {
        const asset = releaseAsset(tool, { os, arch })
        expect(asset).toBeDefined()
        expect(asset?.url).toMatch(/^https:\/\//)
        expect(asset?.url.endsWith(asset.fileName)).toBe(true)
        expect(asset?.sha256).toMatch(/^[a-f0-9]{64}$/)
      }
    }
  }
})

it("linux assets use statically linked musl builds", () => {
  expect(releaseAsset("fd", { os: "linux", arch: "x64" })?.url).toContain(
    "unknown-linux-musl",
  )
})

it("Intel macOS uses latest fd release publishing target", () => {
  expect(releaseAsset("fd", { os: "darwin", arch: "x64" })?.version).toBe(
    FD_INTEL_DARWIN_VERSION,
  )
})

it("bounded downloads reject oversized declared and streamed bodies", async () => {
  await expect(
    readBoundedResponse(
      new Response("small", { headers: { "content-length": "100" } }),
      10,
    ),
  ).rejects.toThrow(/size limit/)
  await expect(
    readBoundedResponse(new Response("this body is too large"), 5),
  ).rejects.toThrow(/size limit/)
})

it("notifications: only fresh installs notify", () => {
  const system: ResolvedBinary = { tool: "fd", command: "fd", source: "system" }
  const bundled: ResolvedBinary = {
    tool: "rg",
    command: "/repo/bin/rg",
    source: "bundled",
  }
  const installed: ResolvedBinary = {
    tool: "rg",
    command: "/repo/bin/rg",
    source: "installed",
    version: "15.2.0",
  }

  expect(installNotifications([system, bundled])).toEqual([])
  expect(installNotifications([system, installed])).toEqual([
    expect.stringMatching(/downloaded rg 15\.2\.0/),
  ])
})

it("process output streams to complete spill file", async () => {
  const result = await executeSearchProcess({
    command: process.execPath,
    args: ["-e", 'process.stdout.write("line\\n".repeat(3000))'],
    cwd: process.cwd(),
    tempPrefix: "pi-search-test-",
  })
  const formatted = formatCapturedOutput(result.output)

  expect(result.code).toBe(0)
  expect(formatted.truncated).toBe(true)
  expect(formatted.lineCount).toBe(3000)
  expect(formatted.text).toMatch(/2000 of 3000 lines/)
  expect(formatted.fullOutputPath).toBeDefined()

  const path = formatted.fullOutputPath
  expect(await readFile(path!, "utf8")).toBe("line\n".repeat(3000))
  await rm(dirname(path!), { recursive: true, force: true })
})

it("process cancellation kills child and removes unretained output", async () => {
  const controller = new AbortController()
  const result = executeSearchProcess({
    command: process.execPath,
    args: ["-e", "setTimeout(() => {}, 10_000)"],
    cwd: process.cwd(),
    tempPrefix: "pi-search-abort-",
    signal: controller.signal,
  })
  controller.abort()

  await expect(result).rejects.toMatchObject({ name: "AbortError" })
})

it("output: small results pass through untouched", async () => {
  const formatted = await formatOutput("a.ts\nb.ts\n", {
    tempPrefix: "pi-fd-",
    persistFullOutput: () => Promise.reject(new Error("should not persist")),
  })
  expect(formatted).toEqual({
    text: "a.ts\nb.ts",
    lineCount: 2,
    truncated: false,
  })
})

it("output: oversized results truncate and persist", async () => {
  const bigOutput = Array.from(
    { length: 3000 },
    (_, index) => `file-${index}.ts`,
  ).join("\n")
  let persisted: string | undefined
  const formatted = await formatOutput(bigOutput, {
    tempPrefix: "pi-fd-",
    persistFullOutput: async (full) => {
      persisted = full
      return "/tmp/fake/output.txt"
    },
  })

  expect(formatted.truncated).toBe(true)
  expect(formatted.fullOutputPath).toBe("/tmp/fake/output.txt")
  expect(persisted).toBe(bigOutput)
  expect(formatted.text).toMatch(/\[Output truncated: 2000 of 3000 lines/)
  expect(formatted.text).toMatch(
    /Full output saved to: \/tmp\/fake\/output\.txt\]/,
  )
  expect(formatted.text.split("\n")[0]).toBe("file-0.ts")
})
