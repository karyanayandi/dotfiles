return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "marilari88/neotest-vitest",
      "arthur944/neotest-bun",
    },
    keys = {
      { "<leader>tr", "<cmd>lua require('neotest').run.run()<cr>", desc = "Run nearest test" },
      { "<leader>ts", "<cmd>lua require('neotest').summary.toggle()<cr>", desc = "Toggle test summary" },
      { "<leader>to", "<cmd>lua require('neotest').output_panel.toggle()<cr>", desc = "Toggle test output panel" },
      { "<leader>ta", "<cmd>lua require('neotest').run.run({suite = true})<cr>", desc = "Run all test" },
    },
    config = function()
      require("neotest").setup {
        adapters = {
          require "neotest-vitest",
          require "neotest-bun",
        },
      }
    end,
  },
}
