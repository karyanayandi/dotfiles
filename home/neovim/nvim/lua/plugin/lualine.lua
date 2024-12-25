-- luacheck: globals vim

return {
  "nvim-lualine/lualine.nvim",
  config = function()
    local hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end

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

    local diff = {
      "diff",
      colored = true,
      symbols = { added = icons.git.Add .. "", modified = icons.git.Mod .. "", removed = icons.git.Remove .. "" },
      cond = hide_in_width,
      separator = "%#SLSeparator#" .. " " .. "%*",
    }

    local filetype = {
      "filetype",
      icons_enabled = true,
      color = function()
        return { bg = "#1b1f27", fg = "#E5E9F0" }
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
          "dashboard",
          "gitcommit",
          "TelescopePrompt",
          "qf",
          "undotree",
          "spectre_panel",
          "NvimTree",
          "snacks_dashboard",
          "snacks_terminal",
        },
        disable_buftypes = {
          "nofile",
          "snacks_dashboard",
          "snacks_terminal",
          "NvimTree",
          "copilot-chat",
          "copilot-overlay",
          "copilot-diff",
        },
      },
      sections = {
        lualine_a = { branch },
        lualine_b = {},
        lualine_c = { diff },
        lualine_x = { diagnostics },
        lualine_y = { filetype },
        lualine_z = { "location" },
      },
      extensions = {},
    }
  end,
}
