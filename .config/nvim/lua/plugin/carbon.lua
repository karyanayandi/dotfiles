return {
  "ellisonleao/carbon-now.nvim",
  lazy = true,
  cmd = "CarbonNow",
  config = function()
    require("carbon-now").setup({
      options = {
        bg = "gray",
        drop_shadow_blur = "68px",
        drop_shadow = false,
        drop_shadow_offset_y = "20px",
        font_family = "Fira Code",
        font_size = "18px",
        line_height = "133%",
        line_numbers = true,
        theme = "One Dark",
        watermark = false,
        width = "680",
        window_theme = "sharp",
        padding_horizontal = "0px",
        padding_vertical = "0px",
      }
    })
  end,
}
