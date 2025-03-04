-- luacheck: globals vim

local icons = require "config.icons"

local servers = {
  "astro",
  "bashls",
  "clangd",
  "docker_compose_language_service",
  "dockerls",
  "emmet_ls",
  "golangci_lint_ls",
  "gopls",
  "html",
  "intelephense",
  "jsonls",
  "lua_ls",
  "marksman",
  "prismals",
  "pyright",
  "rust_analyzer",
  "sqls",
  "svelte",
  "tailwindcss",
  "taplo",
  "templ",
  "ts_ls",
  "vtsls",
  "yamlls",
}

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
  ensure_installed = servers,
  automatic_installation = true,
}

local lspconfig = require "lspconfig"

for _, server in pairs(servers) do
  local opts = {
    on_attach = require("plugin.lsp.handlers").on_attach,
    capabilities = require("plugin.lsp.handlers").capabilities,
  }

  server = vim.split(server, "@")[1]

  local require_ok, conf_opts = pcall(require, "plugin.lsp.settings." .. server)
  if require_ok then
    opts = vim.tbl_deep_extend("force", conf_opts, opts)
  end

  lspconfig[server].setup(opts)
end
