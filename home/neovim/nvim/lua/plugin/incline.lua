-- luacheck: globals vim

return {
  "b0o/incline.nvim",
  event = "BufReadPre",
  enabled = true,
  config = function()
    require("incline").setup {
      highlight = {
        groups = {
          InclineNormal = { guibg = "#282c34", guifg = "#E5E9F0" },
          InclineNormalNC = { guifg = "#E5E9F0", guibg = "#282c34" },
        },
      },
      window = { margin = { vertical = 0, horizontal = 1 } },
      ignore = {
        buftypes = "special",
        wintypes = "special",
        filetypes = {
          "NvimTree",
          "COMMIT_EDITMSG",
          "TelescopePrompt",
          "copilot-chat",
          "copilot-diff",
          "copilot-overlay",
          "dashboard",
          "gitcommit",
          "nofile",
          "qf",
          "snacks_dashboard",
          "snacks_terminal",
          "spectre_panel",
          "undotree",
        },
        floating_wins = true,
        unlisted_buffers = true,
      },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        local icon, color = require("nvim-web-devicons").get_icon_color(filename)
        return { { icon, guifg = color }, { " " }, { filename } }
      end,
    }
  end,
}
