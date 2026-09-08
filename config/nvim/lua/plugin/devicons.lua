return {
  "nvim-tree/nvim-web-devicons",
  lazy = true,
  config = function()
    local icons = require "config.icons"
    local function apply_colors()
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
    end
    apply_colors()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("WallpaperDevicons", { clear = true }),
      callback = apply_colors,
    })
  end,
}
