-- TODO: add linting for github action, deno
-- luacheck: globals vim

return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"
    local uv = vim.uv or vim.loop

    require("lint").linters.vp_lint = {
      cmd = function()
        local local_binary = vim.fn.fnamemodify("./node_modules/.bin/vp", ":p")
        return uv.fs_stat(local_binary) and local_binary or "vp"
      end,
      args = { "lint", "--format", "github" },
      stdin = false,
      stream = "stdout",
      ignore_exitcode = true,
      parser = (require "lint.parser").from_pattern(
        "::([^ ]+) file=(.*),line=(%d+),endLine=(%d+),col=(%d+),endColumn=(%d+),title=(.*)::(.*)",
        { "severity", "file", "lnum", "end_lnum", "col", "end_col", "code", "message" },
        { error = vim.diagnostic.severity.ERROR, warning = vim.diagnostic.severity.WARN },
        { source = "vp-lint" },
        {}
      ),
    }

    local oxlint_root_files = {
      "oxlint.json",
      ".oxlintrc.json",
      "oxlint.config.js",
      "oxlint.config.ts",
      ".oxlint.json",
      ".oxlint.jsonc",
      "oxc.json",
    }
    local biome_root_files = { "biome.json", "biome.jsonc" }
    local deno_root_files = { "deno.json", "deno.jsonc" }
    local eslint_root_files = {
      ".eslintrc",
      ".eslintrc.json",
      ".eslintrc.js",
      "eslint.config.cjs",
      "eslint.config.js",
      "eslint.config.mjs",
    }

    local function exists(file)
      return uv.fs_stat(file) ~= nil
    end

    local function has_any_file(files)
      for _, file in ipairs(files) do
        if exists(file) then
          return true
        end
      end
      return false
    end

    local function has_vite_plus()
      if not exists "vite.config.ts" then
        return false
      end
      if not exists "package.json" then
        return false
      end
      local pkg = vim.fn.readfile "package.json"
      if not pkg or #pkg == 0 then
        return false
      end
      return table.concat(pkg, "\n"):find "vite%-plus" ~= nil
    end

    local function javascript_linter()
      if has_vite_plus() then
        return { "vp_lint" }
      elseif has_any_file(oxlint_root_files) then
        return { "oxlint" }
      elseif has_any_file(biome_root_files) then
        return { "biomejs" }
      elseif has_any_file(deno_root_files) then
        return { "deno" }
      elseif has_any_file(eslint_root_files) then
        return { "eslint_d" }
      else
        return { "oxlint" }
      end
    end

    local js_linter = javascript_linter()

    lint.linters_by_ft = {
      astro = js_linter,
      css = js_linter,
      fish = { "fish" },
      javascript = js_linter,
      javascriptreact = js_linter,
      lua = { "luacheck" },
      markdown = { "vale" },
      sh = { "shellcheck" },
      nix = { "nix" },
      php = { "php" },
      python = { "python", "flake8" },
      rust = { "clippy" },
      svelte = js_linter,
      typescript = js_linter,
      typescriptreact = js_linter,
      vue = js_linter,
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    local function lintable(bufnr)
      local bt = vim.bo[bufnr].buftype
      return bt == "" or bt == "nowrite"
    end

    local function buf_linters(bufnr, filetype)
      if filetype == "markdown" then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if
          bufname:match "codecompanion"
          or bufname:match "CodeCompanion"
          or bufname:match "Avante"
          or bufname:match "copilot%-"
        then
          return {}
        end
        return nil
      elseif filetype == "sh" then
        local filename = vim.fn.bufname(bufnr)
        if filename:match "%.env$" then
          return {}
        end
        return nil
      end
      return nil
    end

    local function run_lint(bufnr)
      if not lintable(bufnr) then
        return
      end
      local ft = vim.bo[bufnr].filetype
      lint.try_lint(buf_linters(bufnr, ft), { ignore_errors = true })
    end

    local lint_timer = nil

    local function immediate_lint()
      if lint_timer then
        vim.fn.timer_stop(lint_timer)
        lint_timer = nil
      end
      run_lint(vim.api.nvim_get_current_buf())
    end

    local function debounced_lint(delay)
      if lint_timer then
        vim.fn.timer_stop(lint_timer)
        lint_timer = nil
      end
      lint_timer = vim.defer_fn(function()
        lint_timer = nil
        run_lint(vim.api.nvim_get_current_buf())
      end, delay or 300)
    end

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = lint_augroup,
      callback = immediate_lint,
    })

    vim.api.nvim_create_autocmd("InsertLeave", {
      group = lint_augroup,
      callback = function()
        debounced_lint(300)
      end,
    })

    vim.keymap.set("n", "<leader>ll", immediate_lint, { desc = "Trigger linting for current file" })
  end,
}
