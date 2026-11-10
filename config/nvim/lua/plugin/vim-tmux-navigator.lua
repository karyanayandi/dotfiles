return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  dependencies = {
    {
      "paulbkim-dev/vim-herdr-navigation",
      config = function(plugin)
        dofile(plugin.dir .. "/editor/nvim.lua")
      end,
    },
  },
  keys = {
    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
  },
}
