-- nvim --headless -u NONE -l config/nvim/tests/theme.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local original_home = vim.env.HOME
local tmp = vim.fn.tempname()
vim.opt.runtimepath:append(root)
vim.opt.runtimepath:append(original_home .. "/.local/share/nvim/lazy/base16-nvim")
vim.opt.runtimepath:append(original_home .. "/.local/share/nvim/lazy/nvim-web-devicons")
vim.opt.runtimepath:append(original_home .. "/.local/share/nvim/lazy/lualine.nvim")
vim.env.HOME = tmp
local directory = tmp .. "/.config/theme/generated"
vim.fn.mkdir(directory, "p")
local path = directory .. "/nvim.lua"

local function write_palette(seed, replace)
  local palette = {}
  for i = 0, 15 do
    palette[string.format("base%02X", i)] = string.format("#%06x", seed + i)
  end
  local destination = replace and path .. ".next" or path
  vim.fn.writefile(vim.split("return " .. vim.inspect(palette), "\n"), destination)
  if replace then
    assert(vim.uv.fs_rename(destination, path))
  end
  return palette
end

local ok, err = xpcall(function()
  write_palette(0x123450)
  local theme = require "config.theme"
  theme.apply()
  theme.watch()
  theme.watch() -- Repeated activation must not install another watcher.
  require("plugin.devicons").config()
  require("plugin.render-markdown").config()
  require("plugin.lualine").config()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved text", "keep editing" })
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  local buffer = vim.api.nvim_get_current_buf()
  for index, seed in ipairs { 0x345670, 0x567890, 0x789ab0 } do
    local palette = write_palette(seed, index > 1)
    assert(
      vim.wait(3000, function()
        return vim.api.nvim_get_hl(0, { name = "Normal" }).bg == seed
      end, 20),
      "Normal highlight did not reload"
    )
    assert(vim.api.nvim_get_hl(0, { name = "RenderMarkdownCode" }).bg == seed + 1)
    local _, color = require("nvim-web-devicons").get_icon_color("file.sh", "sh")
    assert(color == palette.base0B, "Devicon color stayed stale")
    assert(vim.api.nvim_get_hl(0, { name = "lualine_c_normal" }).bg == seed, "Lualine highlight stayed stale")
    local branch = require("lualine").get_config().sections.lualine_a[1]
    assert(branch.color().bg == palette.base01, "Lualine component retained its old palette")
    assert(vim.api.nvim_get_current_buf() == buffer)
    assert(vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1] == "unsaved text")
    assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 2, 3 }))
  end
  print "PASS Neovim live palette, repeated replacement, plugin highlights, and edit state"
end, debug.traceback)
vim.env.HOME = original_home
vim.fn.delete(tmp, "rf")
if not ok then
  error(err)
end
