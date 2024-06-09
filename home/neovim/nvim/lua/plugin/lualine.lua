return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "AndreM222/copilot-lualine",
  },
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

    local filetype = {
      "filetype",
      icons_enabled = true,
      color = function()
        return { fg = "#E5E9F0" }
      end,
    }

    local branch = {
      "branch",
      icon = { "", align = "left" }
    }

    local copilot = {
      "copilot",
      show_colors = true,
      show_loading = true
    }

    -- local lsp_client = function()
    --   local clients = vim.lsp.get_clients()
    --   if next(clients) == nil then
    --     return ""
    --   end
    --
    --   local c = {}
    --   for _, client in pairs(clients) do
    --     table.insert(c, client.name)
    --   end
    --   return "\u{f085}  " .. table.concat(c, ", ")
    -- end

    require("lualine").setup {
      options = {
        globalstatus = true,
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { "alpha", "dashboard", "TelescopePrompt", "qf", "undotree", "spectre_panel" },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { branch },
        lualine_b = { filetype },
        lualine_c = { diff },
        lualine_x = { copilot, diagnostics },
        lualine_y = {},
        lualine_z = { "location" },
      },
      tabline = {},
      extensions = {},
    }
  end,
}
