-- luacheck: globals vim

return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local oil = require "oil"
    oil.setup {
      columns = { "icon" },
      view_options = { show_hidden = true },
      keymaps = {
        ["<C-h>"] = false,
        ["<M-h>"] = "actions.select_split",
      },
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" }),
      vim.keymap.set("n", "<space>-", "<CMD>require('oil').toggle_float()<CR>", { desc = "Open file Explorer" }),
    }
  end,
}
