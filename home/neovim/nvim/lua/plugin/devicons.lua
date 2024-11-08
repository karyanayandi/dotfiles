return {
  "nvim-tree/nvim-web-devicons",
  lazy = true,
  config = function()
    local icons = require "config.icons"

    require("nvim-web-devicons").set_icon {
      sh = {
        icon = icons.ui.Terminal,
        color = "#8ec07c",
        cterm_color = "59",
        name = "Sh",
      },
      [".gitattributes"] = {
        icon = icons.git.Logo,
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitAttributes",
      },
      [".gitconfig"] = {
        icon = icons.ui.Gear,
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitConfig",
      },
      [".gitignore"] = {
        icon = icons.git.Logo,
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitIgnore",
      },
      [".gitlab-ci.yml"] = {
        icon = icons.git.GitLab,
        color = "#d65d0e",
        cterm_color = "166",
        name = "GitlabCI",
      },
      [".gitmodules"] = {
        icon = icons.git.Logo,
        color = "#d65d0e",
        cterm_color = "59",
        name = "GitModules",
      },
      ["diff"] = {
        icon = icons.git.Diff,
        color = "#d65d0e",
        cterm_color = "59",
        name = "Diff",
      },
    }
  end,
}
