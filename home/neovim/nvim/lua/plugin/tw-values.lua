return {
  "MaximilianLloyd/tw-values.nvim",
  config = true,
  lazy = true,
  ft = { "typescript", "typescriptreact", "vue", "html", "svelte", "astro" },
  keys = {
    { "<leader>ov", "<cmd>TWValues<cr>", desc = "Show tailwind CSS values" },
  },
  opts = {
    show_unknown_classes = true,
  },
}
