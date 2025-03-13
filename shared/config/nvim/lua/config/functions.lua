-- luacheck: globals vim

local M = {}

--- Removes an autocommand group by name if it exists
--- This is useful for cleaning up autocommands before redefining them
--- @param name string The name of the autocommand group to remove
function M.remove_augroup(name)
  if vim.fn.exists("#" .. name) == 1 then
    vim.cmd("au! " .. name)
  end
end

--- Toggles a Neovim option and displays a notification with the new state
--- This provides a convenient way to switch boolean settings on/off with feedback
--- @param option string The Neovim option name to toggle
function M.toggle_option(option)
  local value = not vim.api.nvim_get_option_value(option, {})
  vim.opt[option] = value
  vim.notify(option .. " set to " .. tostring(value))
end

--- Toggles the tabline visibility between hidden and always visible
--- Cycles the 'showtabline' option between 0 (hidden) and 2 (always visible)
--- and displays a notification with the new setting value
function M.toggle_tabline()
  local value = vim.api.nvim_get_option_value("showtabline", {})

  if value == 2 then
    value = 0
  else
    value = 2
  end

  vim.opt.showtabline = value

  vim.notify("showtabline" .. " set to " .. tostring(value))
end

--- Toggles the visibility of diagnostic messages in the editor
--- Maintains a local state variable to track whether diagnostics are currently shown
--- When toggled off, all diagnostics are hidden from display; when toggled on,
--- all diagnostics are shown according to their configured settings
local diagnostics_active = true

function M.toggle_diagnostics()
  diagnostics_active = not diagnostics_active
  if diagnostics_active then
    vim.diagnostic.show()
  else
    vim.diagnostic.hide()
  end
end

--- Smart quit function that prompts for confirmation when there are unsaved changes
--- Closes the current buffer with force (:q!) if there are no unsaved changes or
--- if the user confirms they want to discard changes
function M.smart_quit()
  local bufnr = vim.api.nvim_get_current_buf()
  ---@diagnostic disable-next-line: deprecated
  local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
  if modified then
    vim.ui.input({
      prompt = "You have unsaved changes. Quit anyway? (y/n) ",
    }, function(input)
      if input == "y" then
        vim.cmd "q!"
      end
    end)
  else
    vim.cmd "q!"
  end
end

return M
