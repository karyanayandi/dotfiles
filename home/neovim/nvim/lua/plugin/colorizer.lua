return {
  "NvChad/nvim-colorizer.lua",
  lazy = false,
  config = function()
    require("colorizer").setup {
      filetypes = {
        "astro",
        "css",
        "html",
        "javascript",
        "javascriptreact",
        "lua",
        "nix",
        "sh",
        "svelte",
        "typescript",
        "typescriptreact",
        "yaml",
      },
      user_default_options = {
        rgb_fn = true,
        tailwind = "both",
      },
      buftypes = {},
    }
  end,
}
