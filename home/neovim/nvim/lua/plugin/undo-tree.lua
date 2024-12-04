return {
  "jiaoshijie/undotree",
  opts = {
    float_diff = false,
    layout = "left_bottom",
    ignore_filetype = { "Undotree", "UndotreeDiff", "qf", "TelescopePrompt", "spectre_panel" },
    window = {
      winblend = 4,
    },
    keymaps = {
      ["j"] = "move_next",
      ["k"] = "move_prev",
      ["J"] = "move_change_next",
      ["K"] = "move_change_prev",
      ["<cr>"] = "action_enter",
      ["p"] = "enter_diffbuf",
      ["q"] = "quit",
    },
  },
  event = "BufReadPre",
  dependencies = "nvim-lua/plenary.nvim",
}
