-- luacheck: globals vim

return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"
    local util = require "conform.util"

    local biome_root_files = { "biome.json", "biome.jsonc" }
    local deno_root_files = { "deno.json", "deno.jsonc" }
    local oxfmt_root_files = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxc.json" }
    local prettier_root_files = {
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.json5",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettierrc.js",
      ".prettierrc.cjs",
      "prettier.config.js",
      "prettier.config.cjs",
    }

    local function has_any_file(files)
      for _, file in ipairs(files) do
        if vim.fn.glob(file) ~= "" then
          return true
        end
      end
      return false
    end

    local function javascript_formatter()
      if has_any_file(oxfmt_root_files) or vim.fn.glob "oxc.json" ~= "" then
        return { "oxfmt" }
      elseif has_any_file(biome_root_files) then
        return { "biome" }
      elseif has_any_file(deno_root_files) then
        return { "deno_fmt" }
      elseif has_any_file(prettier_root_files) then
        return { "prettierd" }
      else
        return { "oxfmt" }
      end
    end

    local biome_root = util.root_file(biome_root_files)
    local oxfmt_root = util.root_file(oxfmt_root_files)
    local prettier_root = util.root_file(prettier_root_files)

    local formatters_by_ft = {
      astro = javascript_formatter,
      blade = { "blade-formatter" },
      c = { "clang_format" },
      css = javascript_formatter,
      go = { "gofumpt", "goimports-reviser", "golines" },
      graphql = { "prettierd" },
      html = javascript_formatter,
      javascript = javascript_formatter,
      javascriptreact = javascript_formatter,
      json = javascript_formatter,
      jsonc = javascript_formatter,
      json5 = javascript_formatter,
      lua = { "stylua" },
      markdown = javascript_formatter,
      nix = { "alejandra" },
      php = { "pretty-php" },
      python = { "isort", "black" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      svelte = javascript_formatter,
      typescript = javascript_formatter,
      typescriptreact = javascript_formatter,
      vue = javascript_formatter,
      yaml = javascript_formatter,
    }

    local function format_on_save(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 3000, lsp_fallback = true, async = false }
    end

    conform.setup {
      formatters_by_ft = formatters_by_ft,
      formatters = {
        oxfmt = {
          command = "vp",
          args = { "fmt", "--write", "$FILENAME" },
          stdin = false,
          cwd = oxfmt_root,
          -- require_cwd = true,
        },
        biome = {
          command = "node_modules/.bin/biome",
          args = { "format", "--stdin-file-path", "$FILENAME" },
          stdin = true,
          cwd = biome_root,
          require_cwd = true,
        },
        biome_fix = {
          command = "node_modules/.bin/biome",
          args = { "check", "--write", "--stdin-file-path", "$FILENAME" },
          stdin = true,
          cwd = biome_root,
          require_cwd = true,
        },
        prettier = {
          command = "node_modules/.bin/prettier",
          args = { "--stdin-filepath", "$FILENAME" },
          stdin = true,
          cwd = prettier_root,
          require_cwd = true,
        },
      },
      format_on_save = format_on_save,
    }
  end,
}
