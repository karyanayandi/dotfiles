-- luacheck: globals vim

return {
  "nvim-lualine/lualine.nvim",
  config = function()
    -- local hide_in_width = function()
    --   return vim.fn.winwidth(0) > 80
    -- end

    local icons = require "config.icons"

    local diagnostics = {
      "diagnostics",
      sources = { "nvim_diagnostic" },
      sections = { "error", "warn" },
      symbols = { error = icons.diagnostics.Error .. "", warn = icons.diagnostics.Warning .. "" },
      colored = true,
      color = function()
        return { bg = "#373b43", fg = "#E5E9F0" }
      end,
      update_in_insert = false,
      always_visible = true,
    }

    local filetype = {
      "filetype",
      icons_enabled = true,
      color = function()
        return { bg = "#252931", fg = "#E5E9F0" }
      end,
    }

    local branch = {
      "branch",
      icon = { icons.git.Branch, align = "left" },
    }

    require("lualine").setup {
      options = {
        globalstatus = true,
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        always_divide_middle = true,
        disabled_filetypes = {
          "NvimTree",
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
        disable_buftypes = {
          "NvimTree",
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
      },
      sections = {
        lualine_a = { branch },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = { diagnostics, filetype },
        lualine_z = {},
      },
      extensions = {},
    }
  end,
}
