return {
  "ravenxrz/DAPInstall.nvim",
  lazy = true,
  config = function()
    require("dap_install").setup {}
    require("dap_install").config("python", {})
  end,
}
