-- luacheck: globals vim

-- Conditionally enable LSP servers based on config files
local function should_enable_biome()
  return vim.fn.glob "biome.json" ~= "" or vim.fn.glob "biome.jsonc" ~= ""
end

local function should_enable_eslint()
  return vim.fn.glob ".eslintrc" ~= ""
    or vim.fn.glob ".eslintrc.json" ~= ""
    or vim.fn.glob ".eslintrc.js" ~= ""
    or vim.fn.glob "eslint.config.cjs" ~= ""
    or vim.fn.glob "eslint.config.js" ~= ""
    or vim.fn.glob "eslint.config.mjs" ~= ""
end

local function should_enable_deno()
  return vim.fn.glob "deno.json" ~= "" or vim.fn.glob "deno.jsonc" ~= ""
end

-- Build server list
local servers = {
  "astro",
  "bashls",
  "clangd",
  "docker_compose_language_service",
  "dockerls",
  "emmet_ls",
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
  "svelteserver",
  "tailwindcss",
  "taplo",
  "templ",
  -- "vue_ls",
  -- "vtsls",
  "yamlls",
}

-- Conditionally add biome
if should_enable_biome() then
  table.insert(servers, "biome")
end

-- Conditionally add eslint
if should_enable_eslint() then
  table.insert(servers, "eslint")
end

-- Mutually exclusive: deno or ts_ls
if should_enable_deno() then
  table.insert(servers, "denols")
else
  table.insert(servers, "ts_ls")
end

-- Enable LSP servers
vim.lsp.enable(servers)

-- Configure diagnostic display with custom signs
local icons = require "config.icons"

local signs = {
  { name = "DiagnosticSignError", text = icons.diagnostics.Error },
  { name = "DiagnosticSignWarn", text = icons.diagnostics.Warning },
  { name = "DiagnosticSignHint", text = icons.diagnostics.Hint },
  { name = "DiagnosticSignInfo", text = icons.diagnostics.Info },
}

vim.diagnostic.config {
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
  virtual_text = false,
  virtual_lines = false,
  signs = {
    active = signs,
    text = {
      [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
      [vim.diagnostic.severity.WARN] = icons.diagnostics.Warning,
      [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
      [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
}

-- Enable inlay hints
vim.lsp.inlay_hint.enable(false)

-- Create default capabilities without cmp
local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()

vim.lsp.config("*", {
  capabilities = lsp_capabilities,
})

local cmp_nvim_lsp = require "cmp_nvim_lsp"

local ext_capabilities = vim.tbl_deep_extend("force", {}, lsp_capabilities, cmp_nvim_lsp.default_capabilities())

vim.lsp.config("*", {
  capabilities = ext_capabilities,
})

local keymap = vim.keymap
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }

    opts.desc = "Go to definition"
    keymap.set("n", "gd", vim.lsp.buf.definition, opts)

    opts.desc = "Go to Declaration"
    keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

    opts.desc = "Show Documentation"
    keymap.set("n", "K", vim.lsp.buf.hover, opts)

    opts.desc = "Go to Implementation"
    keymap.set("n", "gI", vim.lsp.buf.implementation, opts)

    opts.desc = "Show References"
    keymap.set("n", "gr", vim.lsp.buf.references, opts)

    opts.desc = "Show Diagnostics"
    keymap.set("n", "gl", vim.diagnostic.open_float, opts)

    opts.desc = "Show Signature Help"
    keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)

    opts.desc = "Format"
    keymap.set("n", "<M-f>", "<cmd>Format<cr>", opts)

    opts.desc = "Code Action"
    keymap.set("n", "<M-a>", vim.lsp.buf.code_action, opts)

    opts.desc = "Rename"
    keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
  end,
})
