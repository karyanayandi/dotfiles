-- luacheck: globals vim

local M = {}

--- Discover available themes by scanning themes directory
--- @return table list of theme names
function M.discover_themes()
  local config_dir = vim.fn.stdpath "config"
  local themes_dir = config_dir .. "/../../themes"
  local themes = {}

  if vim.fn.isdirectory(themes_dir) == 0 then
    return themes
  end

  for name, type in vim.fs.dir(themes_dir) do
    if type == "directory" and name ~= "current" then
      local theme_file = themes_dir .. "/" .. name .. "/nvim/theme.lua"
      if vim.fn.filereadable(theme_file) == 1 then
        table.insert(themes, name)
      end
    end
  end

  table.sort(themes)
  return themes
end

--- Switch to a new theme by updating symlink
--- @param theme_name string
function M.switch_theme(theme_name)
  local config_dir = vim.fn.stdpath "config"
  local themes_dir = config_dir .. "/../../themes"
  local current_dir = themes_dir .. "/current"

  -- Validate theme exists
  local themes = M.discover_themes()
  local theme_found = false
  for _, name in ipairs(themes) do
    if name == theme_name then
      theme_found = true
      break
    end
  end

  if not theme_found then
    vim.notify(
      "Theme '" .. theme_name .. "' not found. Available: " .. table.concat(themes, ", "),
      vim.log.levels.ERROR
    )
    return
  end

  -- Verify theme has nvim/theme.lua
  local theme_file = themes_dir .. "/" .. theme_name .. "/nvim/theme.lua"
  if vim.fn.filereadable(theme_file) == 0 then
    vim.notify("Theme file not found: " .. theme_name .. "/nvim/theme.lua", vim.log.levels.ERROR)
    return
  end

  -- Update themes/current/nvim directory symlink
  local nvim_link = current_dir .. "/nvim"
  vim.fn.system("rm -rf " .. vim.fn.shellescape(nvim_link))
  vim.fn.system("cd " .. vim.fn.shellescape(current_dir) .. " && ln -sf ../" .. theme_name .. "/nvim nvim")

  -- Verify symlink was created
  if vim.fn.filereadable(current_dir .. "/nvim/theme.lua") == 1 then
    vim.notify("Theme switched to: " .. theme_name .. " (restart Neovim to apply)", vim.log.levels.INFO)
  else
    vim.notify("Failed to create theme symlink", vim.log.levels.ERROR)
  end
end

-- Create user command
vim.api.nvim_create_user_command("ThemeSwitch", function(opts)
  local theme_name = opts.args
  if theme_name == "" then
    vim.notify("Theme name required. Use <Tab> for autocomplete.", vim.log.levels.ERROR)
    return
  end
  M.switch_theme(theme_name)
end, {
  nargs = 1,
  complete = function()
    return M.discover_themes()
  end,
  desc = "Switch Neovim theme",
})

return M
