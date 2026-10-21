return {
  name = "tsrs",
  description = "TypeScript compiler and language server written in Rust.",
  homepage = "https://github.com/oxc-project/tsrs",
  licenses = { "Apache-2.0" },
  languages = { "TypeScript", "JavaScript" },
  categories = { "LSP", "Compiler" },
  source = { id = "pkg:npm/tsrs@0.18.0-ts7.1.0-dev.20260929" },
  bin = { tsrs = "npm:tsrs" },
}
