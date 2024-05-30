return {
  { "moll/vim-bbye" },
  { "wakatime/vim-wakatime" },
  { "folke/trouble.nvim" },
  { "preservim/vimux" },
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "nvim-lua/popup.nvim",
    lazy = true,
  },
  {
    "simrat39/symbols-outline.nvim",
    lazy = true,
  },
  {
    "jamessan/vim-gnupg",
    lazy = false,
    ft = "markdown",
  },
  {
    "lambdalisue/suda.vim",
    event = "BufReadPre",
  },
  {
    "romainl/vim-cool",
    event = "BufReadPre",
  },
}
