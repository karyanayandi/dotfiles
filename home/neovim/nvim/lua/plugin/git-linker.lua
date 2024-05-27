return {
  "ruifm/gitlinker.nvim",
  config = function()
    require("gitlinker").setup {
      opts = {
        callbacks = {
          ["github.com"] = require("gitlinker.hosts").get_github_type_url,
        },
        add_current_line_on_normal_mode = true,
        action_callback = require("gitlinker.actions").open_in_browser,
        print_url = false,
        mappings = "<leader>gy",
      },
    }
  end,
}
