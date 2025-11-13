return {
  "imNel/monorepo.nvim",
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  config = function()
    require("monorepo").setup {}
    require("telescope").load_extension "monorepo"
  end,
  keys = {
    {
      "<leader>m",
      group = "Monorepo",
    },
    {
      "<leader>ma",
      "<cmd>lua require('monorepo').add_project()<cr>",
      desc = "Add Project",
    },
    {
      "<leader>ml",
      "<cmd>lua require('telescope').extensions.monorepo.monorepo()<cr>",
      desc = "Monorepo List",
    },
    {
      "<leader>mr",
      "<cmd>lua require('monorepo').remove_project()<cr>",
      desc = "Remove Project",
    },
    {
      "<leader>mm",
      "<cmd>lua require('monorepo').toggle_project()<cr>",
      desc = "Toggle Project",
    },
  },
}
