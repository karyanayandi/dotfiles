-- luacheck: globals vim

return {
  {
    "RRethy/base16-nvim",
    priority = 10,
    config = function()
      vim.cmd "colorscheme base16-gruvbox-dark-hard"
    end,
  },
}
