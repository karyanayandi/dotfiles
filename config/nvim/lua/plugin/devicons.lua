return {
  "nvim-tree/nvim-web-devicons",
  lazy = true,
  config = function()
    local icons = require "config.icons"
    local colors = require("base16-colorscheme").colors

    require("nvim-web-devicons").set_icon {
      sh = {
        icon = icons.ui.Terminal,
        color = colors.base0B,
        name = "Sh",
      },
      [".gitattributes"] = {
        icon = icons.git.Logo,
        color = colors.base09,
        name = "GitAttributes",
      },
      [".gitconfig"] = {
        icon = icons.ui.Gear,
        color = colors.base09,
        name = "GitConfig",
      },
      [".gitignore"] = {
        icon = icons.git.Logo,
        color = colors.base09,
        name = "GitIgnore",
      },
      [".gitlab-ci.yml"] = {
        icon = icons.git.GitLab,
        color = colors.base09,
        name = "GitlabCI",
      },
      [".gitmodules"] = {
        icon = icons.git.Logo,
        color = colors.base09,
        name = "GitModules",
      },
      ["diff"] = {
        icon = icons.git.Diff,
        color = colors.base09,
        name = "Diff",
      },
    }
  end,
}
