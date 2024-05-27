-- TODO: add formatting for deno

return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    conform.setup {
      formatters_by_ft = {
        c = { "clang_format" },
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
        astro = { "prettierd" },
        svelte = { "prettierd" },
        vue = { "prettierd" },
        php = { "phpcs_fixer", "prettierd" },
        css = { "prettierd" },
        html = { "prettierd" },
        json = { "prettierd" },
        yaml = { "prettierd" },
        markdown = { "prettierd" },
        graphql = { "prettierd" },
        lua = { "stylua" },
        nix = { "alejandra" },
        python = { "isort", "black" },
        go = { "gofumpt", "goimports-reviser", "golines" },
        sh = { "shfmt" },
        fish = { "fish_indent" },
        rust = { "rushfmt" },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true, async = false }
      end,
    }

    vim.keymap.set({ "n", "v" }, "<leader>lp", function()
      conform.format {
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      }
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
