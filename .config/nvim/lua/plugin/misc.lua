return {
  { "moll/vim-bbye" },
  { "wakatime/vim-wakatime" },
  { "preservim/vimux" },
  { "tpope/vim-sleuth" },
  { "MaxMEllon/vim-jsx-pretty" },
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "nvim-lua/popup.nvim",
    lazy = true,
  },
  {
    "kevinhwang91/nvim-fundo",
    dependencies = "kevinhwang91/promise-async",
    build = function()
      require("fundo").install()
    end,
    event = "BufReadPre",
    config = true,
  },
  {
    "romainl/vim-cool",
    event = "BufReadPre",
  },
}
