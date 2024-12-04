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

    local formatters_by_ft = {
      astro = has_deno_json() and { "deno_fmt", stop_after_first = true } or { "prettierd", stop_after_first = true },
      c = { "clang_format" },
      css = { "prettierd" },
      fish = { "fish_indent" },
      go = { "gofumpt", "goimports-reviser", "golines" },
      graphql = { "prettierd" },
      html = { "prettierd" },
      javascript = has_deno_json() and { "deno_fmt", stop_after_first = true }
        or { "prettierd", stop_after_first = true },
      javascriptreact = has_deno_json() and { "deno_fmt", stop_after_first = true }
        or { "prettierd", stop_after_first = true },
      json = { "prettierd" },
      lua = { "stylua" },
      markdown = has_deno_json() and { "deno_fmt", stop_after_first = true }
        or { "prettierd", stop_after_first = true },
      nix = { "alejandra" },
      php = { "phpcs_fixer", "prettierd" },
      python = { "isort", "black" },
      rust = { "rushfmt" },
      sh = { "shfmt" },
      svelte = has_deno_json() and { "deno_fmt", stop_after_first = true } or { "prettierd", stop_after_first = true },
      typescript = has_deno_json() and { "deno_fmt", stop_after_first = true }
        or { "prettierd", stop_after_first = true },
      typescriptreact = has_deno_json() and { "deno_fmt", stop_after_first = true }
        or { "prettierd", stop_after_first = true },
      vue = has_deno_json() and { "deno_fmt", stop_after_first = true } or { "prettierd", stop_after_first = true },
      yaml = { "prettierd", stop_after_first = true },
    }

    conform.setup {
      formatters_by_ft = formatters_by_ft,
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true, async = false }
      end,
    }
  end,
}
