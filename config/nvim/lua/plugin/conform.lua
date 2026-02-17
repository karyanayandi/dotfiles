-- luacheck: globals vim

return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    local function javascript_formatter()
      if vim.fn.glob ".oxfmtrc.json" ~= "" or vim.fn.glob ".oxfmtrc.jsonc" ~= "" or vim.fn.glob "oxc.json" ~= "" then
        return { "oxfmt" }
      elseif vim.fn.glob "biome.json" ~= "" or vim.fn.glob "biome.jsonc" ~= "" then
        return { "biome" }
      elseif vim.fn.glob "deno.json" ~= "" or vim.fn.glob "deno.jsonc" ~= "" then
        return { "deno_fmt" }
      elseif
        vim.fn.glob ".prettierrc" ~= ""
        or vim.fn.glob ".prettierrc.json" ~= ""
        or vim.fn.glob ".prettierrc.js" ~= ""
        or vim.fn.glob "prettier.config.js" ~= ""
      then
        return { "prettierd" }
      else
        return { "oxlint" }
      end
    end

    local formatters_by_ft = {
      astro = javascript_formatter,
      blade = { "blade-formatter" },
      c = { "clang_format" },
      css = { "prettierd" },
      go = { "gofumpt", "goimports-reviser", "golines" },
      graphql = { "prettierd" },
      html = { "prettierd" },
      javascript = javascript_formatter,
      javascriptreact = javascript_formatter,
      json = { "prettierd" },
      jsonc = { "prettierd" },
      json5 = { "prettierd" },
      lua = { "stylua" },
      markdown = javascript_formatter,
      nix = { "alejandra" },
      php = { "pretty-php" },
      python = { "isort", "black" },
      sh = { "shfmt" },
      svelte = javascript_formatter,
      typescript = javascript_formatter,
      typescriptreact = javascript_formatter,
      vue = javascript_formatter,
      yaml = { "prettierd", stop_after_first = true },
    }

    local function format_on_save(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 3000, lsp_fallback = true, async = false }
    end

    conform.setup {
      formatters_by_ft = formatters_by_ft,
      format_on_save = format_on_save,
    }
  end,
}
