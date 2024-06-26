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
      update_in_insert = false,
      always_visible = true,
    }

    local diff = {
      "diff",
      colored = true,
      symbols = { added = icons.git.Add .. "", modified = icons.git.Mod .. "", removed = icons.git.Remove .. "" }, -- changes diff symbols
      cond = hide_in_width,
      separator = "%#SLSeparator#" .. " " .. "%*",
    }

    local filename = {
      "filename",
      icons_enabled = true,
      file_status = false,
      path = 1,
      shorting_target = 20,
      color = function()
        return { fg = "#E5E9F0" }
      end,
    }

    local filetype = {
      "filetype",
      icons_enabled = true,
      color = function()
        return { fg = "#E5E9F0" }
      end,
    }

    local branch = {
      "branch",
      icon = { "", align = "left" },
    }

    require("lualine").setup {
      options = {
        globalstatus = true,
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { "alpha", "dashboard", "TelescopePrompt", "qf", "undotree", "spectre_panel", "NvimTree" },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { branch },
        lualine_b = { filename },
        lualine_c = { diff },
        lualine_x = { diagnostics },
        lualine_y = { filetype },
        lualine_z = { "location" },
      },
      extensions = {},
    }
  end,
}
