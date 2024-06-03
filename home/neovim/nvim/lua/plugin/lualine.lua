return {
  "nvim-lualine/lualine.nvim",
  config = function()
    local theme = require "lualine.themes.onenord"

    local mode_color = {
      n = "#88C0D0",
      i = "#A3BE8C",
      v = "#BF616A",
      [""] = "#BF616A",
      V = "#BF616A",
      c = "#458588",
      no = "#88C0D0",
      s = "#D08770",
      S = "#D08770",
      [""] = "#D08770",
      ic = "#EBCB8B",
      R = "#D08770",
      Rv = "#D08770",
      cv = "#88C0D0",
      ce = "#88C0D0",
      r = "#D08770",
      rm = "#8FBCBB",
      ["r?"] = "#8FBCBB",
      ["!"] = "#8FBCBB",
      t = "#EBCB8B",
    }

    local hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end

    local icons = require "config.icons"

    vim.api.nvim_set_hl(0, "SLGitIcon", { fg = "#4C566A", bg = "#ECEFF4" })
    vim.api.nvim_set_hl(0, "SLBranchName", { fg = "#4C566A", bg = "#ECEFF4", bold = false })
    vim.api.nvim_set_hl(0, "SLProgress", { fg = "#ECEFF4", bg = "#2E3440" })
    vim.api.nvim_set_hl(0, "SLSeparator", { fg = "#3B4252", bg = "#2E3440" })

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

    local filetype = {
      "filetype",
      icons_enabled = true,
      color = function()
        return { fg = "#E5E9F0" }
      end,
    }

    local branch = {
      "branch",
      icons_enabled = true,
      icon = "%#SLGitIcon#" .. "" .. "%*" .. "%#SLBranchName#",
    }

    local filename = {
      "filename",
      file_status = false,
      path = 1,
      shorting_target = 20,
      color = function()
        return { fg = "#E5E9F0" }
      end,
    }

    local location = {
      "location",
      color = function()
        return { fg = "#2E3440", bg = mode_color[vim.fn.mode()] }
      end,
    }

    require("lualine").setup {
      options = {
        globalstatus = true,
        icons_enabled = true,
        theme = theme,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { "alpha", "dashboard" },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { branch },
        lualine_b = { filename },
        lualine_c = { diagnostics },
        lualine_x = { diff },
        lualine_y = { filetype },
        lualine_z = { location },
      },
      tabline = {},
      extensions = {},
    }
  end,
}
