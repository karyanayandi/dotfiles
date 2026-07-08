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

    local function has_root_file(dir, files)
      return vim.fs.find(files, { upward = true, path = dir, limit = 1 })[1] ~= nil
    end

    local function has_vite_plus(dir)
      if not has_root_file(dir, "vite.config.ts") then
        return false
      end
      local pkg = vim.fs.find("package.json", { upward = true, path = dir, limit = 1 })[1]
      if not pkg then
        return false
      end
      local content = table.concat(vim.fn.readfile(pkg), "\n")
      return content:find "vite%-plus" ~= nil
    end

    local function javascript_formatter(bufnr)
      local cached = vim.b[bufnr].js_formatter
      if cached then
        return cached
      end

      local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
      local formatters
      if has_vite_plus(dir) then
        formatters = { "oxfmt" }
      elseif has_root_file(dir, oxfmt_root_files) then
        formatters = { "oxfmt" }
      elseif has_root_file(dir, biome_root_files) then
        formatters = { "biome" }
      elseif has_root_file(dir, deno_root_files) then
        formatters = { "deno_fmt" }
      elseif has_root_file(dir, prettier_root_files) then
        formatters = { "prettierd" }
      else
        formatters = { "oxfmt" }
      end

      vim.b[bufnr].js_formatter = formatters
      return formatters
    end

    local biome_root = util.root_file(biome_root_files)
    local oxfmt_root = util.root_file(oxfmt_root_files)
    local prettier_root = util.root_file(prettier_root_files)
    local vite_root = util.root_file { "vite.config.ts" }

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
          cwd = oxfmt_root or vite_root,
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
