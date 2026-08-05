return {
  "carderne/pi-nvim",
  event = "VeryLazy",
  opts = {
    set_default_keymaps = false,
  },

  config = function(_, opts)
    require("pi-nvim").setup(opts)

    vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>Pi<CR>", { desc = "Pi dialog" })
    vim.keymap.set("n", "<leader>aS", "<cmd>PiSend<CR>", { desc = "Pi send prompt" })
    vim.keymap.set("n", ";p", "<cmd>PiSend<CR>", { desc = "Pi send prompt" })
    vim.keymap.set("v", "<leader>av", "<cmd>PiSendSelection<CR>", { desc = "Pi send selection" })
    vim.keymap.set("n", "<leader>aP", "<cmd>PiPing<CR>", { desc = "Pi ping" })
    vim.keymap.set("n", "<leader>as", "<cmd>PiSessions<CR>", { desc = "Pi sessions" })
  end,
}
