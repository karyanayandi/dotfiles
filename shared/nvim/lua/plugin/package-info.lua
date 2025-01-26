-- luacheck: globals vim

return {
  "vuki656/package-info.nvim",
  dependencies = "MunifTanjim/nui.nvim",
  config = function()
    require("package-info").setup {
      icons = {
        enable = true,
        style = {
          up_to_date = "|  ",
          outdated = "|  ",
        },
      },
      autostart = true,
      hide_up_to_date = false,
      hide_unstable_versions = false,
      package_manager = "pnpm",
    }

    vim.api.nvim_set_keymap(
      "n",
      "<leader>ns",
      "<cmd>lua require('package-info').show()<cr>",
      { desc = "which_key_ignore", silent = true, noremap = true }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>nu",
      "<cmd>lua require('package-info').update()<cr>",
      { desc = "which_key_ignore", silent = true, noremap = true }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>ni",
      "<cmd>lua require('package-info').install()<cr>",
      { desc = "which_key_ignore", silent = true, noremap = true }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>nc",
      "<cmd>lua require('package-info').change_version()<cr>",
      { desc = "which_key_ignore", silent = true, noremap = true }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>nd",
      "<cmd>lua require('package-info').delete()<cr>",
      { desc = "which_key_ignore", silent = true, noremap = true }
    )
  end,
}
