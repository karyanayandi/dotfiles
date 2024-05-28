return {
  "kyazdani42/nvim-web-devicons",
  lazy = true,
  config = function()
    require("nvim-web-devicons").set_icon {
      sh = {
        icon = "",
        color = "#8ec07c",
        cterm_color = "59",
        name = "Sh",
      },
      [".gitattributes"] = {
        icon = "",
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitAttributes",
      },
      [".gitconfig"] = {
        icon = "",
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitConfig",
      },
      [".gitignore"] = {
        icon = "",
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitIgnore",
      },
      [".gitlab-ci.yml"] = {
        icon = "",
        color = "#d65d0e",
        cterm_color = "166",
        name = "GitlabCI",
      },
      [".gitmodules"] = {
        icon = "",
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitModules",
      },
      ["diff"] = {
        icon = "",
        color = "#d65d0e",
        cterm_color = "59",
        name = "Diff",
      },
    }
  end,
}
