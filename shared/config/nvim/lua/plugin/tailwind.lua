return {
  -- {
  --   "razak17/tailwind-fold.nvim",
  --   opts = {
  --     symbol = "…", -- 󱏿
  --     highlight = {
  --       fg = "#98c379",
  --     },
  --   },
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  --   ft = {
  --     "astro",
  --     "blade",
  --     "edge",
  --     "eruby",
  --     "html",
  --     "htmldjango",
  --     "javascript",
  --     "javascriptreact",
  --     "php",
  --     "svelte",
  --     "tsx",
  --     "typescriptreact",
  --     "vue",
  --   },
  --   keys = {
  --     { "<leader>tu", "<cmd>TailwindFoldToggle<cr>", desc = "which_key_ignore" },
  --   },
  -- },
  {
    "MaximilianLloyd/tw-values.nvim",
    config = true,
    lazy = true,
    ft = { "typescript", "typescriptreact", "vue", "html", "svelte", "astro" },
    keys = {
      { "<leader>tw", "<cmd>TWValues<cr>", desc = "which_key_ignore" },
    },
    opts = {
      show_unknown_classes = true,
    },
  },
}
