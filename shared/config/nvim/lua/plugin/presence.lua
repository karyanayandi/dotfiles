return {
  "andweeb/presence.nvim",
  event = "VeryLazy",
  config = function()
    require("presence").setup {
      auto_update = true,
      neovim_image_text = "text editor for non-skill isssue engineers",
      main_image = "neovim",
      log_level = nil,
      debounce_timeout = 10,
      enable_line_number = false,
      blacklist = {},
      buttons = true,
      file_assets = {},
      show_time = true,
      editing_text = "Editing %s",
      file_explorer_text = "Exploring %s",
      git_commit_text = "Committing changes",
      workspace_text = "Working on %s",
      line_number_text = "Line %s out of %s",
    }
  end,
}
