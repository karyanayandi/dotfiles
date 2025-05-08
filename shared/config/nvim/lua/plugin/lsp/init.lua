-- luacheck: globals vim

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
      "b0o/SchemaStore.nvim",
    },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local cmp_nvim_lsp = require "cmp_nvim_lsp"
      local mason = require "plugin.mason"

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
          "documentation",
          "detail",
          "additionalTextEdits",
        },
      }
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

      local function lsp_highlight_document(client)
        local illuminate = require "illuminate"
        illuminate.on_attach(client)
      end

      local function lsp_keymaps(bufnr)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", {
          desc = "Go to Definition",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", {
          desc = "Go to Declaration",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {
          desc = "Show Documentation",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gI", "<cmd>lua vim.lsp.buf.implementation()<CR>", {
          desc = "Go to Implementation",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", {
          desc = "Show References",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gl", "<cmd>lua vim.diagnostic.open_float()<CR>", {
          desc = "Show Diagnostics",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", {
          desc = "Show Signature Help",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<M-f>", "<cmd>Format<cr>", {
          desc = "Format",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<M-a>", "<cmd>lua vim.lsp.buf.code_action()<cr>", {
          desc = "Code Action",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<CR>", {
          desc = "Rename",
          noremap = true,
          silent = true,
        })
        vim.api.nvim_buf_set_keymap(bufnr, "i", "<F2>", "<cmd>lua vim.lsp.buf.rename()<CR>", {
          desc = "Rename",
          noremap = true,
          silent = true,
        })
      end

      vim.cmd [[ command! Format execute 'lua vim.lsp.buf.format({ async = true })' ]]

      local function on_attach(client, bufnr)
        lsp_keymaps(bufnr)
        lsp_highlight_document(client)
      end

      local icons = require "config.icons"

      local signs = {
        { name = "DiagnosticSignError", text = icons.diagnostics.Error },
        { name = "DiagnosticSignWarn", text = icons.diagnostics.Warning },
        { name = "DiagnosticSignHint", text = icons.diagnostics.Hint },
        { name = "DiagnosticSignInfo", text = icons.diagnostics.Info },
      }

      local config = {
        virtual_text = false,
        signs = {
          active = signs,
        },
        update_in_insert = true,
        underline = true,
        severity_sort = true,
        float = {
          focusable = true,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      }

      vim.diagnostic.config(config)

      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
      end

      local lspconfig = require "lspconfig"

      for _, server in pairs(mason.servers) do
        local opts = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        server = vim.split(server, "@")[1]

        local require_ok, conf_opts = pcall(require, "plugin.lsp.settings." .. server)
        if require_ok then
          opts = vim.tbl_deep_extend("force", conf_opts, opts)
        end

        if lspconfig[server] then
          lspconfig[server].setup(opts)
        else
          vim.notify("LSP server " .. server .. " not found in lspconfig", vim.log.levels.WARN)
        end
      end
    end,
  },
}
