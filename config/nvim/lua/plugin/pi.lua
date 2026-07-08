return {
  "carderne/pi-nvim",

  event = "VeryLazy",

  opts = {
    set_default_keymaps = false,
  },

  config = function(_, opts)
    require("pi-nvim").setup(opts)
    vim.keymap.set({ "n", "v" }, "<leader>as", ":Pi<CR>", { desc = "Send to pi" })
  end,
}
