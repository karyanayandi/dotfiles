return {
  "monaqa/dial.nvim",
  config = function()
    local dial_augend = require "dial.augend"
    local dial_config = require "dial.config"

    dial_config.augends:register_group {
      default = {
        dial_augend.integer.alias.decimal,
        dial_augend.integer.alias.hex,
        dial_augend.date.alias["%Y/%m/%d"],
      },
      typescript = {
        dial_augend.integer.alias.decimal,
        dial_augend.integer.alias.hex,
        dial_augend.constant.new { elements = { "let", "const" } },
      },
      visual = {
        dial_augend.integer.alias.decimal,
        dial_augend.integer.alias.hex,
        dial_augend.date.alias["%Y/%m/%d"],
        dial_augend.constant.alias.alpha,
        dial_augend.constant.alias.Alpha,
      },
      mygroup = {
        dial_augend.constant.new {
          elements = { "and", "or" },
          word = true,
          cyclic = true,
        },
        dial_augend.constant.new {
          elements = { "True", "False" },
          word = true,
          cyclic = true,
        },
        dial_augend.constant.new {
          elements = { "public", "private" },
          word = true,
          cyclic = true,
        },
        dial_augend.constant.new {
          elements = { "&&", "||" },
          word = false,
          cyclic = true,
        },
        dial_augend.date.alias["%m/%d/%Y"],
        dial_augend.constant.alias.bool,
        dial_augend.integer.alias.decimal,
        dial_augend.integer.alias.hex,
        dial_augend.semver.alias.semver,
      },
    }

    local map = require "dial.map"

    vim.api.nvim_set_keymap("n", "+", map.inc_normal "mygroup", { noremap = false })
    vim.api.nvim_set_keymap("n", "-", map.dec_normal "mygroup", { noremap = true })
    vim.api.nvim_set_keymap("v", "+", map.inc_normal "visual", { noremap = true })
    vim.api.nvim_set_keymap("v", "-", map.dec_normal "visual", { noremap = true })

    vim.cmd [[
  autocmd FileType typescript,javascript lua vim.api.nvim_buf_set_keymap(0, "n", "-", require("dial.map").inc_normal("typescript"), {noremap = true})
]]
  end,
}
