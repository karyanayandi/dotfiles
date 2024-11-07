return {
  "lewis6991/gitsigns.nvim",
  config = function()
    local icons = require "config.icons"
    require("gitsigns").setup {
      signs = {
        add = {
          text = icons.git.SignBold,
        },
        change = {
          text = icons.git.SignBold,
        },
        delete = {
          text = icons.git.SignDelete,
        },
        topdelete = {
          text = icons.git.SignDelete,
        },
        changedelete = {
          text = icons.git.SignBold,
        },
      },
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
      update_debounce = 200,
      max_file_length = 40000,
      preview_config = {
        border = "rounded",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
    }
  end,
}
