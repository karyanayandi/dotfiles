-- luacheck: globals vim

return {
  "nvim-lualine/lualine.nvim",
  config = function()
    local custom_catppuccin = require "catppuccin.utils.lualine" "mocha"
    custom_catppuccin.normal.a.bg = nil

    local colors = require("catppuccin.palettes").get_palette "mocha"

    local hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end

    local icons = require "config.icons"

    local branch = {
      "branch",
      icon = { icons.git.Branch, align = "left" },
      use_mode_colors = false,
      color = function()
        return { bg = colors.surface0, fg = colors.text, gui = "bold" }
      end,
    }

    local diff = {
      "diff",
      symbols = {
        added = icons.git.Add,
        modified = icons.git.Mod,
        removed = icons.git.Remove,
      },
      colored = false,
      use_color_mode = true,
      diff_color = {
        added = "LuaLineDiffAdd",
        modified = "LuaLineDiffChange",
        removed = "LuaLineDiffDelete",
      },
      cond = hide_in_width,
      separator = "%#SLSeparator#" .. " " .. "%*",
      color = function()
        return { bg = colors.surface0, fg = colors.text }
      end,
    }

    local filename = {
      "filename",
      icons_enabled = true,
      symbols = {
        modified = "  ",
        readonly = "  ",
        unnamed = "  ",
        newfile = "  ",
      },
      cond = hide_in_width,
      path = 4,
      shorting_target = 10,
      use_color_mode = true,
      color = function()
        return { bg = colors.surface0, fg = colors.text }
      end,
    }

    local diagnostics = {
      "diagnostics",
      sources = { "nvim_diagnostic" },
      sections = { "error", "warn", "info", "hint" },
      symbols = {
        error = icons.diagnostics.Error .. "",
        warn = icons.diagnostics.Warning .. "",
        info = icons.diagnostics.Info .. "",
        hint = icons.diagnostics.Hint .. "",
      },
      colored = false,
      color = function()
        return { bg = colors.surface0, fg = colors.text }
      end,
      update_in_insert = false,
      always_visible = false,
    }

    local filetype = {
      "filetype",
      icons_enabled = true,
      icon_only = false,
      color = function()
        return { bg = colors.surface0, fg = colors.text }
      end,
    }

    require("lualine").setup {
      options = {
        globalstatus = true,
        icons_enabled = true,
        theme = custom_catppuccin,
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
        lualine_a = { branch, diff, filename },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = { diagnostics },
        lualine_z = { filetype },
      },
      extensions = {},
    }
  end,
}
