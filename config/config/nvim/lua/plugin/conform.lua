-- luacheck: globals vim

return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    local function javascript_formatter()
      if vim.fn.glob "biome.json" ~= "" then
        return { "biome" }
      elseif vim.fn.glob "deno.json" ~= "" then
        return { "deno_fmt" }
      else
        return { "prettierd" }
      end
    end

    local formatters_by_ft = {
      astro = javascript_formatter(),
      blade = { "blade-formatter" },
      c = { "clang_format" },
      css = { "prettierd" },
      go = { "gofumpt", "goimports-reviser", "golines" },
      graphql = { "prettierd" },
      html = { "prettierd" },
      javascript = javascript_formatter(),
      javascriptreact = javascript_formatter(),
      json = { "prettierd" },
      jsonc = { "prettierd" },
      json5 = { "prettierd" },
      lua = { "stylua" },
      markdown = javascript_formatter(),
      nix = { "alejandra" },
      php = { "pretty-php" },
      python = { "isort", "black" },
      sh = { "shfmt" },
      svelte = javascript_formatter(),
      typescript = javascript_formatter(),
      typescriptreact = javascript_formatter(),
      vue = javascript_formatter(),
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
