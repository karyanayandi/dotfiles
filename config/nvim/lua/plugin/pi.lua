return {
  "carderne/pi-nvim",

  event = "VeryLazy",

  opts = {
    set_default_keymaps = false,
  },

  config = function(_, opts)
    require("pi-nvim").setup(opts)

    vim.keymap.set({ "n", "v" }, "<leader>as", "<cmd>Pi<CR>", { desc = "Pi dialog" })
    vim.keymap.set("n", "<leader>aa", "<cmd>PiSend<CR>", { desc = "Pi send prompt" })
    vim.keymap.set("n", "<leader>af", "<cmd>PiSendFile<CR>", { desc = "Pi send file" })
    vim.keymap.set("v", "<leader>av", "<cmd>PiSendSelection<CR>", { desc = "Pi send selection" })
    vim.keymap.set("n", "<leader>ab", "<cmd>PiSendBuffer<CR>", { desc = "Pi send buffer" })
    vim.keymap.set("n", "<leader>ap", "<cmd>PiPing<CR>", { desc = "Pi ping" })
    vim.keymap.set("n", "<leader>aS", "<cmd>PiSessions<CR>", { desc = "Pi sessions" })
  end,
}
