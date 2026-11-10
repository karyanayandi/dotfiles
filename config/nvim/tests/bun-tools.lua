local repo = vim.fn.getcwd()
local lazy = vim.fn.stdpath "data" .. "/lazy/"
vim.opt.rtp:append(lazy .. "conform.nvim")
vim.opt.rtp:append(lazy .. "nvim-lint")
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/src", "p")
vim.fn.writefile(
  { "[fmt]", "semi = false", "singleQuote = true", "[lint.rules]", '"no-console" = "error"' },
  root .. "/bunfig.toml"
)
vim.fn.writefile({ '{"scripts":{"fmt":"exit 99","lint":"exit 99"}}' }, root .. "/package.json")
local filename = root .. "/src/example.ts"
vim.fn.writefile({ 'console.log("hello");' }, filename)

local function check()
  dofile(repo .. "/config/nvim/lua/plugin/conform.lua").config()
  dofile(repo .. "/config/nvim/lua/plugin/lint.lua").config()
  vim.cmd.edit(filename)
  vim.bo.filetype = "typescript"
  vim.fn.writefile({ 'export const message = "saved without lint errors";' }, filename)
  local bufnr = vim.api.nvim_get_current_buf()
  local conform = require "conform"
  local lint = require "lint"
  assert(conform.list_formatters_for_buffer(bufnr)[1] == "bun_fmt", "Bun must be the default formatter")
  conform.format { bufnr = bufnr, async = false, timeout_ms = 10000, lsp_format = "never" }
  assert(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1] == "console.log('hello')",
    "Bun must read [fmt] from bunfig.toml"
  )
  vim.api.nvim_exec_autocmds("InsertLeave", { buffer = bufnr })
  assert(
    vim.wait(10000, function()
      return #vim.diagnostic.get(bufnr, { namespace = lint.get_namespace "bun_lint" }) > 0
    end, 20),
    "Bun must read [lint.rules] and publish diagnostics for unsaved content"
  )
  local diagnostic = vim.diagnostic.get(bufnr, { namespace = lint.get_namespace "bun_lint" })[1]
  assert(diagnostic.severity == vim.diagnostic.severity.ERROR, "Expected no-console error")
  assert(diagnostic.lnum == 0 and diagnostic.col == 0, "Expected correct diagnostic position")
  assert(diagnostic.message:find("Unexpected console", 1, true), "Expected no-console message")

  local original = lint.try_lint
  local selected
  lint.try_lint = function(names)
    selected = names
  end
  vim.fn.writefile({ "{}" }, root .. "/.oxlintrc.jsonc")
  vim.fn.writefile({ "{}" }, root .. "/.oxfmtrc.json")
  vim.b[bufnr].js_formatter = nil
  assert(conform.list_formatters_for_buffer(bufnr)[1] == "oxfmt", "Explicit Oxfmt config must win")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "console.log('changed')" })
  vim.api.nvim_exec_autocmds("BufWritePost", { buffer = bufnr })
  assert(selected and selected[1] == "oxlint", "Nested files must use explicit Oxlint config")
  vim.fn.delete(root .. "/.oxlintrc.jsonc")
  local other = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(other, root .. "/src/other.ts")
  vim.api.nvim_set_current_buf(other)
  vim.bo.filetype = "typescript"
  vim.api.nvim_exec_autocmds("BufWritePost", { buffer = other })
  assert(selected[1] == "bun_lint", "Linter selection must be per buffer")
  lint.try_lint = original
  vim.fn.delete(root .. "/.oxfmtrc.json")
  vim.fn.delete(root .. "/bunfig.toml")
  vim.api.nvim_buf_set_lines(other, 0, -1, false, { "const value='default'" })
  assert(conform.list_formatters_for_buffer(other)[1] == "bun_fmt", "No config must select Bun")
  conform.format { bufnr = other, async = false, timeout_ms = 10000, lsp_format = "never" }
  assert(
    vim.api.nvim_buf_get_lines(other, 0, -1, false)[1] == 'const value = "default";',
    "Bun must work without bunfig.toml"
  )
end

local ok, err = xpcall(check, debug.traceback)
vim.fn.delete(root, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd "cquit 1"
end
print "PASS: Bun config, formatting, lint diagnostics, script bypass, and config selection"
vim.cmd "qa!"
