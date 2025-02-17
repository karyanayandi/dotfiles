-- luacheck: globals vim

return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    local function has_deno_json()
      return vim.fn.glob "deno.json" ~= ""
    end

    local function formatter_for_js_or_ts()
      return has_deno_json() and { "deno_fmt" } or { "prettierd" }
    end

    local formatters_by_ft = {
      astro = formatter_for_js_or_ts(),
      c = { "clang_format" },
      css = { "prettierd" },
      fish = { "fish_indent" },
      go = { "gofumpt", "goimports-reviser", "golines" },
      graphql = { "prettierd" },
      html = { "prettierd" },
      javascript = formatter_for_js_or_ts(),
      javascriptreact = formatter_for_js_or_ts(),
      json = { "prettierd" },
      jsonc = { "prettierd" },
      json5 = { "prettierd" },
      lua = { "stylua" },
      markdown = formatter_for_js_or_ts(),
      nix = { "alejandra" },
      php = { "phpcs_fixer", "prettierd" },
      python = { "isort", "black" },
      rust = { "rushfmt" },
      sh = { "shfmt" },
      svelte = formatter_for_js_or_ts(),
      typescript = formatter_for_js_or_ts(),
      typescriptreact = formatter_for_js_or_ts(),
      vue = formatter_for_js_or_ts(),
      yaml = { "prettierd", stop_after_first = true },
    }

    local function format_on_save(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true, async = false }
    end

    conform.setup {
      formatters_by_ft = formatters_by_ft,
      format_on_save = format_on_save,
    }
  end,
}
