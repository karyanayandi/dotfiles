return {
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
}
