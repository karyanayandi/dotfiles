return {
  "luisiacc/gruvbox-baby",
  lazy = false,
  priority = 1001,
  config = function()
    vim.g.gruvbox_baby_telescope_theme = 1
    vim.g.gruvbox_baby_function_style = "NONE"
    vim.g.gruvbox_baby_keyword_style = "italic"
    vim.g.gruvbox_baby_comment_style = "italic"
    vim.cmd.colorscheme('gruvbox-baby')
  end
}
