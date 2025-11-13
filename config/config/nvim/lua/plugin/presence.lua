return {
  "andweeb/presence.nvim",
  event = "VeryLazy",
  config = function()
    require("presence").setup {
      auto_update = true,
      neovim_image_text = "just VS Code but without mouse",
      main_image = "neovim",
      log_level = nil,
      debounce_timeout = 10,
      enable_line_number = false,
      blacklist = {},
      buttons = true,
      file_assets = {},
      show_time = true,
      editing_text = false,
      file_explorer_text = false,
      git_commit_text = false,
      workspace_text = false,
      line_number_text = false,
    }
  end,
}
