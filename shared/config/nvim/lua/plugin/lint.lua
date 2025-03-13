-- TODO: add linting for github action, deno
-- luacheck: globals vim

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    local function javascript_linter()
      if vim.fn.glob "biome.json" ~= "" then
        return { "biomejs" }
      elseif vim.fn.glob "deno.json" ~= "" then
        return { "deno" }
      else
        return { "eslint" }
      end
    end

    lint.linters_by_ft = {
      astro = javascript_linter(),
      css = { "stylelint", "eslint" },
      fish = { "fish" },
      go = { "golangcilint" },
      javascript = javascript_linter(),
      javascriptreact = javascript_linter(),
      json = { "jsonlint" },
      lua = { "luacheck" },
      markdown = { "markdownlint" },
      sh = { "shellcheck" },
      nix = { "nix" },
      php = { "php", "phpcs" },
      python = { "python", "flake8" },
      svelte = javascript_linter(),
      typescript = javascript_linter(),
      typescriptreact = javascript_linter(),
      vue = javascript_linter(),
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    -- Handle disabling linters based on filetype/filename
    vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
      group = lint_augroup,
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local filename = vim.fn.bufname(bufnr)
        local filetype = vim.bo[bufnr].filetype

        -- Disable markdownlint for Avante and copilot-*
        if filetype == "markdown" and (filetype == "Avante" or filename:match "^copilot%-") then
          lint.linters_by_ft["markdown"] = {}
        elseif filetype == "markdown" then
          lint.linters_by_ft["markdown"] = { "markdownlint" }
        end

        -- Disable shellcheck for .env files
        if filetype == "sh" and filename:match "%.env$" then
          lint.linters_by_ft["sh"] = {}
        elseif filetype == "sh" then
          lint.linters_by_ft["sh"] = { "shellcheck" }
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
