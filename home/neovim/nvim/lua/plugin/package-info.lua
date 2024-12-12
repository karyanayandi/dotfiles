return {
  "vuki656/package-info.nvim",
  dependencies = "MunifTanjim/nui.nvim",
  config = function()
    local icons = require "config.icons"

    require("package-info").setup {
      icons = {
        enable = true,
        style = {
          up_to_date = "| " + icons.ui.CheckBox,
          outdated = "| " + icons.ui.MinusBox,
        },
      },
      autostart = true,
      hide_up_to_date = false,
      hide_unstable_versions = false,
      package_manager = "pnpm",
    }
  end,
}
