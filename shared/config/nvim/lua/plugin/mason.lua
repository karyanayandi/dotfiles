-- luacheck: globals vim

local M = {
  "williamboman/mason.nvim",
  cmd = "Mason",
  event = "BufReadPre",
  dependencies = {
    {
      "williamboman/mason-lspconfig.nvim",
      {
        "TabulateJarl8/mason-nvim-lint",
        branch = "patch-1",
      },
      "LittleEndianRoot/mason-conform",
      lazy = true,
    },
  },
}

-- Export these lists for use in other modules
M.servers = {
  "astro",
  "bashls",
  "biome",
  "clangd",
  -- "denols",
  "docker_compose_language_service",
  "dockerls",
  "emmet_ls",
  "eslint",
  "golangci_lint_ls",
  "gopls",
  "html",
  "intelephense",
  "jsonls",
  "lua_ls",
  "marksman",
  -- "nil_ls",
  "prismals",
  "pyright",
  "rust_analyzer",
  "sqls",
  "svelte",
  "tailwindcss",
  "taplo",
  "templ",
  -- "ts_ls",
  "volar",
  "vtsls",
  "yamlls",
}

M.formatters = {
  "alejandra",
  "biome",
  "black",
  "clang-format",
  "gofumpt",
  "goimports-reviser",
  "golines",
  "isort",
  "php-cs-fixer",
  "prettierd",
  "shfmt",
  "stylua",
}

M.linters = {
  -- "biome",
  "flake8",
  "golangci-lint",
  "jsonlint",
  "luacheck",
  "markdownlint",
  "phpcs",
  "stylelint",
}

function M.config()
  local icons = require "config.icons"

  local settings = {
    ui = {
      border = "none",
      icons = {
        package_installed = icons.ui.Installed,
        package_pending = icons.ui.Pending,
        package_uninstalled = icons.ui.Uninstalled,
      },
    },
    log_level = vim.log.levels.INFO,
    max_concurrent_installers = 4,
  }

  require("mason").setup(settings)
  require("mason-lspconfig").setup {
    ensure_installed = M.servers,
    automatic_installation = true,
  }
  require("mason-conform").setup {
    ensure_installed = M.formatters,
    automatic_installation = false,
  }
  require("mason-nvim-lint").setup {
    ensure_installed = M.linters,
    ignore_install = { "eslint", "fish", "nix", "php", "python" },
    automatic_installation = true,
  }
end

return M
