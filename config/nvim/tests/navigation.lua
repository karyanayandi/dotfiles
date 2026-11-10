-- nvim --headless -u NONE -l config/nvim/tests/navigation.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugin = vim.fn.expand "~/.local/share/nvim/lazy/vim-herdr-navigation"
local spec = dofile(root .. "/lua/plugin/vim-tmux-navigator.lua")
assert(spec.lazy == false)
spec.init()
assert(vim.g.tmux_navigator_no_mappings == 1)
assert(#spec.keys == 1 and spec.keys[1][1] == "<c-\\>")
local calls = {}
vim.fn.system = function(args)
  table.insert(calls, args)
  return ""
end
for _, direction in ipairs { "Left", "Down", "Up", "Right" } do
  vim.api.nvim_create_user_command("TmuxNavigate" .. direction, function()
    table.insert(calls, direction)
  end, {})
end
spec.dependencies[1].config { dir = plugin }
local directions = { h = "left", j = "down", k = "up", l = "right" }
for _, backend in ipairs { "plain", "tmux", "desktop", "herdr" } do
  vim.env.TMUX = backend ~= "plain" and "/tmp/tmux" or nil
  vim.env.HC_TERMINAL_ID = (backend == "desktop" or backend == "herdr") and "t1" or nil
  vim.env.HERDR_PANE_ID = backend == "herdr" and "pane1" or nil
  vim.env.HERDR_BIN_PATH = nil
  for key, direction in pairs(directions) do
    vim.cmd "only"
    calls = {}
    local mapping = vim.fn.maparg("<C-" .. key .. ">", "n", false, true)
    mapping.callback()
    if backend == "herdr" then
      assert(vim.deep_equal(calls, { { "herdr", "pane", "focus", "--direction", direction, "--pane", "pane1" } }))
    elseif backend == "desktop" then
      assert(vim.deep_equal(calls, { { "herdr-app", "do", "pane.go", "--direction", direction } }))
    elseif backend == "tmux" then
      assert(vim.deep_equal(calls, { direction:sub(1, 1):upper() .. direction:sub(2) }))
    else
      assert(#calls == 0)
    end
    vim.cmd((key == "h" or key == "l") and "vsplit" or "split")
    vim.cmd("wincmd " .. ({ h = "l", l = "h", j = "k", k = "j" })[key])
    local previous = vim.api.nvim_get_current_win()
    calls = {}
    mapping.callback()
    assert(vim.api.nvim_get_current_win() ~= previous, backend .. ": split did not change")
    assert(#calls == 0, backend .. ": split escaped to multiplexer")
  end
end
vim.fn.writefile({ '{"editor":"passed","backends":["plain","tmux","desktop","herdr"]}' }, "/tmp/herdr-navigation-editor.json")
vim.api.nvim_out_write "PASS navigation: four directions, real splits, four backends, tmux previous key\n"
