-- luacheck: globals vim

return {
  "rcarriga/nvim-notify",
  config = function()
    local icons = require "config.icons"

    require("notify").setup {
      stages = "fade",
      render = "minimal",
      timeout = 3000,
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

    local banned_messages = { "No information available" }
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, ...)
      for _, banned in ipairs(banned_messages) do
        if msg == banned then
          return
        end
      end
      return require "notify"(msg, ...)
    end
  end,
}
