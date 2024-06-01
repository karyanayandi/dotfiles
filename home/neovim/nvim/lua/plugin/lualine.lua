return {
  "nvim-lualine/lualine.nvim",
  config = function()
    local theme = require "lualine.themes.gruvbox-baby"

    local mode_color = {
      n = "#7fa2ac",
      i = "#6a9955",
      v = "#b16286",
      [""] = "#b16286",
      V = "#b16286",
      c = "#458588",
      no = "#7fa2ac",
      s = "#fb4934",
      S = "#fb4934",
      [""] = "#fb4934",
      ic = "#EBCB8B",
      R = "#fb4934",
      Rv = "#fb4934",
      cv = "#7fa2ac",
      ce = "#7fa2ac",
      r = "#fb4934",
      rm = "#458588",
      ["r?"] = "#458588",
      ["!"] = "#458588",
      t = "#ebdbb2",
    }

    local hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end

    local icons = require "config.icons"

    vim.api.nvim_set_hl(0, "SLGitIcon", { fg = "#504945", bg = "#dedede" })
    vim.api.nvim_set_hl(0, "SLBranchName", { fg = "#504945", bg = "#dedede", bold = false })
    vim.api.nvim_set_hl(0, "SLProgress", { fg = "#dedede", bg = "#2E3440" })
    vim.api.nvim_set_hl(0, "SLSeparator", { fg = "#808080", bg = "#252525" })

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
        return { fg = "#e5e9f0" }
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
        return { fg = "#e5e9f0" }
      end,
    }

    local location = {
      "location",
      color = function()
        return { fg = "#2e3440", bg = mode_color[vim.fn.mode()] }
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
