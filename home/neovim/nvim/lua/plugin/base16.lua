-- luacheck: globals vim

return {
  "RRethy/base16-nvim",
  lazy = false,
  priority = 10000,
  config = function()
    require("base16-colorscheme").setup()
    vim.cmd "colorscheme base16-onedark"
  end,
}
