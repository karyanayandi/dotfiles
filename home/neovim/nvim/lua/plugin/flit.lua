return {
  "ggandor/flit.nvim",
  config = function()
    require("flit").setup {
      keys = { f = "f", F = "F", t = "t", T = "T" },
      labeled_modes = "v",
      clever_repeat = true,
      multiline = true,
      opts = {},
    }
  end,
}
