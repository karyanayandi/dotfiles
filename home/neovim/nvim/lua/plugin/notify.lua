-- luacheck: globals vim

return {
  "rcarriga/nvim-notify",
  config = function()
    local icons = require "config.icons"

    require("notify").setup {
      stages = "fade",
      render = "minimal",
      timeout = 3000,
      background_colour = "Normal",
      minimum_width = 10,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
      icons = {
        ERROR = icons.diagnostics.Error,
        WARN = icons.diagnostics.Warning,
        INFO = icons.diagnostics.Information,
        DEBUG = icons.ui.Bug,
        TRACE = icons.ui.Pencil,
      },
    }

    local notify_filter = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, ...)
      if type(msg) == "string" and msg:match "character_offset must be called with valid offset encoding" then
        return
      end

      notify_filter(msg, ...)
    end
  end,
}
