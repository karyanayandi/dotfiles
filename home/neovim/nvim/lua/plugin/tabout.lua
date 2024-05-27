return {
  "abecodes/tabout.nvim",
  lazy = true,
  dependencies = { "nvim-treesitter" },
  config = function()
    require("tabout").setup {
      tabkey = "<tab>",
      backwards_tabkey = "<s-tab>",
      act_as_tab = true,
      act_as_shift_tab = false,
      default_tab = "<C-t>",
      default_shift_tab = "<C-d>",
      enable_backwards = false,
      completion = true,
      tabouts = {
        { open = "'", close = "'" },
        { open = '"', close = '"' },
        { open = "`", close = "`" },
        { open = "(", close = ")" },
        { open = "[", close = "]" },
        { open = "{", close = "}" },
      },
      ignore_beginning = false,
      exclude = { "markdown" },
    }
  end,
}
