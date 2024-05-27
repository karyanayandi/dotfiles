return {
  "mfussenegger/nvim-dap",
  "rcarriga/nvim-dap-ui",
  event = "VeryLazy",
  dependencies = { "rcarriga/nvim-dap-ui" },
  config = function()
    local dap = require "dap"
    local dapui = require "dapui"

    dapui.setup {
      icons = { expanded = "▾", collapsed = "▸" },
      mappings = {
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.25 },
            "breakpoints",
          },
          size = 40,
          position = "right",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 0.25,
          position = "bottom",
        },
      },
      floating = {
        max_height = nil,
        max_width = nil,
        border = "single",
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = { indent = 1 },
      render = {
        max_type_length = nil,
      },
    }

    local icons = require "config.icons"

    vim.fn.sign_define(
      "DapBreakpoint",
      { text = icons.ui.Bug, texthl = "DiagnosticSignError", linehl = "", numhl = "" }
    )

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end

    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end

    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end,
}
