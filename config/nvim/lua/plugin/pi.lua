return {
  "pablopunk/pi.nvim",

  event = "VeryLazy",

  opts = {
    provider = "ollama",
    thinking = "off",
    context = {
      max_bytes = 24000,
      ask = { surrounding_lines = 80 },
      selection = { surrounding_lines = 40 },
      diagnostics = { enabled = false },
    },
    skills = true,
    extensions = true,
  },

  config = function(_, opts)
    require("pi").setup(opts)
    vim.keymap.set("n", "<leader>aa", ":PiAsk<CR>", { desc = "Ask pi (buffer context)" })
    vim.keymap.set("v", "<leader>aa", ":PiAskSelection<CR>", { desc = "Ask pi (selection context)" })
  end,
}
