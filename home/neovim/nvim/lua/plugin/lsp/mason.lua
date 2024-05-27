local servers = {
  "astro",
  "cssls",
  "cssmodules_ls",
  "html",
  "jsonls",
  "lua_ls",
  "tsserver",
  "pyright",
  "yamlls",
  "bashls",
  "clangd",
  "rust_analyzer",
  "tailwindcss",
  -- "deno",
  -- "stylua",
  -- "shellcheck",
  -- "shfmt",
  -- "flake8",
}

local settings = {
  ui = {
    border = "none",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
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

local opts = {}

for _, server in pairs(servers) do
  opts = {
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
