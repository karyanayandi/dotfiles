-- luacheck: globals vim

return {
  "RRethy/vim-illuminate",
  event = "VeryLazy",
  dependencies = { "nvim-treesitter" },
  config = function()
    vim.g.Illuminate_ftblacklist = { "snacks_dashboard", "snacks_terminal", "NvimTree" }
    vim.api.nvim_set_keymap("n", ";z", '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>', { noremap = true })
    vim.api.nvim_set_keymap(
      "n",
      "<a-p>",
      '<cmd>lua require"illuminate".next_reference{reverse=true,wrap=true}<cr>',
      { noremap = true }
    )

    require("illuminate").configure {
      providers = {
        "lsp",
        "treesitter",
        "regex",
      },
      delay = 200,
      filetypes_denylist = {
        "DressingSelect",
        "NvimTree",
        "Outline",
        "SnacksInputNormal",
        "TelescopePrompt",
        "Trouble",
        "dirvish",
        "fugitive",
        "lir",
        "neogitstatus",
        "packer",
        "snacks_dashboard",
        "snacks_terminal",
        "spectre_panel",
      },
      filetypes_allowlist = {},
      modes_denylist = {},
      modes_allowlist = {},
      providers_regex_syntax_denylist = {},
      providers_regex_syntax_allowlist = {},
      under_cursor = true,
    }
  end,
}
