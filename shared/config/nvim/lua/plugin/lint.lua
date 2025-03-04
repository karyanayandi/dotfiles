-- luacheck: globals vim
-- TODO: add linting for github action, deno

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"

    local function has_deno_json()
      return vim.fn.glob "deno.json" ~= ""
    end

    local function lint_for_js_or_ts()
      return has_deno_json() and { "deno" } or { "eslint_d" }
    end

    lint.linters_by_ft = {
      astro = lint_for_js_or_ts(),
      css = { "stylelint", "eslint_d" },
      fish = { "fish" },
      go = { "golangcilint" },
      javascript = lint_for_js_or_ts(),
      javascriptreact = lint_for_js_or_ts(),
      json = { "jsonlint" },
      lua = { "luacheck" },
      markdown = { "markdownlint" },
      sh = { "shellcheck" },
      nix = { "nix" },
      php = { "php", "phpcs" },
      python = { "python", "flake8" },
      svelte = lint_for_js_or_ts(),
      typescript = lint_for_js_or_ts(),
      typescriptreact = lint_for_js_or_ts(),
      vue = lint_for_js_or_ts(),
      yaml = { "yamllint" },
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
  end,
}
