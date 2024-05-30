return {
  "vim-test/vim-test",
  dependencies = {
    {
      "preservim/vimux",
    },
  },
  vim.cmd("let test#strategy = 'vimux'")
}
