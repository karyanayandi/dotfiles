return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    {
      "f",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump {
          search = { forward = true, wrap = false, multi_window = false },
        }
      end,
      desc = "Flash",
    },
    {
      "F",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump {
          search = { forward = false, wrap = false, multi_window = false },
        }
      end,
      desc = "Flash Treesitter",
    },
  },
}
