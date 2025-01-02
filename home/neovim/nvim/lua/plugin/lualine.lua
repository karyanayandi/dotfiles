-- luacheck: globals vim

return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "meuter/lualine-so-fancy.nvim",
  },
  event = { "BufReadPost", "BufNewFile", "VeryLazy" },
  config = function()
    -- local hide_in_width = function()
    --   return vim.fn.winwidth(0) > 80
    -- end

    local icons = require "config.icons"

    -- local diagnostics = {
    --   "diagnostics",
    --   sources = { "nvim_diagnostic" },
    --   sections = { "error", "warn" },
    --   symbols = { error = icons.diagnostics.Error .. "", warn = icons.diagnostics.Warning .. "" },
    --   colored = true,
    --   color = function()
    --     return { bg = "#373b43", fg = "#E5E9F0" }
    --   end,
    --   update_in_insert = false,
    --   always_visible = true,
    -- }
    --
    -- local diff = {
    --   "diff",
    --   colored = true,
    --   symbols = { added = icons.git.Add .. "", modified = icons.git.Mod .. "", removed = icons.git.Remove .. "" },
    --   cond = hide_in_width,
    --   separator = "%#SLSeparator#" .. " " .. "%*",
    -- }

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
        lualine_a = {},
        lualine_b = { "fancy_branch" },
        lualine_c = {
          {
            "filename",
            path = 1, -- 2 for full path
            symbols = {
              modified = "  ",
              readonly = "  ",
              unnamed = "  ",
            },
          },
          { "fancy_diagnostics", sources = { "nvim_lsp" }, symbols = { error = " ", warn = " ", info = " " } },
          { "fancy_searchcount" },
        },
        -- lualine_x = { diagnostics },
        lualine_x = { "fancy_lsp_servers", "fancy_diff", "progress" },
        -- lualine_y = { filetype },
        lualine_y = { filetype },
        lualine_z = {},
      },
      extensions = {},
    }
  end,
}
