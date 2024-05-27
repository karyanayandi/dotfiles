return {
  tools = {
    on_initialized = function()
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "CursorHold", "InsertLeave" }, {
        pattern = { "*.rs" },
        callback = function()
          vim.lsp.codelens.refresh()
        end,
      })
    end,
    inlay_hints = {
      only_current_line = false,
      only_current_line_autocmd = "CursorHold",
      show_parameter_hints = false,
      show_variable_name = false,
      parameter_hints_prefix = " ",
      other_hints_prefix = " ",
      max_len_align = false,
      max_len_align_padding = 1,
      right_align = false,
      right_align_padding = 7,
      highlight = "Comment",
    },
    hover_actions = {
      auto_focus = false,
      border = "rounded",
      width = 60,
    },
  },
  server = {
    cmd = { "rustup", "run", "nightly", os.getenv "HOME" .. "/.local/bin/rust-analyzer" },
    on_attach = require("plugin.lsp.handlers").on_attach,
    capabilities = require("plugin.lsp.handlers").capabilities,
    settings = {
      ["rust-analyzer"] = {
        lens = {
          enable = true,
        },
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  },
}
