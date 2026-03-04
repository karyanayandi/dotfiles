-- luacheck: globals vim

local M = {
  "mason-org/mason.nvim",
  cmd = "Mason",
  event = "VeryLazy",
  dependencies = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "mason-org/mason-lspconfig.nvim",
  },
}

-- Export these lists for use in other modules
M.servers = {
  "astro",
  "bashls",
  "biome",
  "clangd",
  "denols",
  "docker_compose_language_service",
  "dockerls",
  "emmet_ls",
  -- "eslint",
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
  "vue_ls",
  "vtsls",
  "yamlls",
}

M.formatters = {
  "alejandra",
  "biome",
  "black",
  "blade-formatter",
  "clang-format",
  "gofumpt",
  "goimports-reviser",
  "golines",
  "isort",
  "oxfmt",
  "prettierd",
  "pretty-php",
  "shfmt",
  "stylua",
}

M.linters = {
  "biome",
  "eslint_d",
  "flake8",
  "golangci-lint",
  "jsonlint",
  "luacheck",
  "markdownlint",
  "oxlint",
  -- "phpcs",
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
    automatic_installation = true,
  }

  local tools = {}

  vim.list_extend(tools, M.servers)
  vim.list_extend(tools, M.formatters)
  vim.list_extend(tools, M.linters)

  require("mason-tool-installer").setup {
    ensure_installed = tools,
    auto_update = true,
    run_on_start = false,
  }

  local mr = require "mason-registry"
  vim.defer_fn(function()
    mr:on(
      "update:success",
      vim.schedule_wrap(function()
        vim.cmd "MasonToolsUpdate"
      end)
    )
    mr.update()
  end, 3000)
end

return M
