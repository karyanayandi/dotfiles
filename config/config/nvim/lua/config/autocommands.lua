-- luacheck: globals vim
-- luacheck: ignore 631

--- Creates a named autocommand group with automatic clearing
--- @param name string The name suffix for the autocommand group
--- @return number The autocommand group ID
local function augroup(name)
  return vim.api.nvim_create_augroup("lazynvim_" .. name, { clear = true })
end

--- Configures the dashboard display settings
--- Sets laststatus=0 while in the dashboard and restores to laststatus=3 when leaving
--- This removes the status line specifically when viewing the dashboard for cleaner UI
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "snacks_dashboard" },
  callback = function()
    vim.cmd [[
      set laststatus=0 | autocmd BufUnload <buffer> set laststatus=3
    ]]
  end,
})

--- Configures special buffer handling for various UI elements
--- Sets up 'q' to close the buffer and marks them as unlisted
--- This applies to help, notification windows, and various plugin UI panels
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = {
    "DressingSelect",
    "PlenaryTestPopup",
    "SnacksInputNormal",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
  },
  callback = function()
    vim.cmd [[
      nnoremap <silent> <buffer> q :close<CR>
      set nobuflisted
    ]]
  end,
})

--- Enables convenient text editing settings for specific file types
--- Automatically enables line wrapping and spell checking for
--- git commit messages and markdown files
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Auto close NvimTree when it's the last window
-- This ensures that if NvimTree is the only window left in a tab,
-- vim will automatically quit rather than leaving an isolated file explorer
vim.cmd "autocmd BufEnter * ++nested if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif"

--- Automatically equalizes window sizes when Neovim is resized
--- This ensures all splits maintain proper proportions when the terminal
--- or GUI window containing Neovim changes dimensions
vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd "tabdo wincmd ="
  end,
})

--- Automatically closes the command window as soon as it's opened
--- This prevents accidental activation of the command history window
--- that appears when typing q: or q/ in normal mode
vim.api.nvim_create_autocmd({ "CmdWinEnter" }, {
  callback = function()
    vim.cmd "quit"
  end,
})

--- Disables automatic comment insertion when creating new lines
--- Removes the 'cro' flags from formatoptions to prevent auto-commenting
--- when pressing o/O in normal mode or Enter in insert mode after a comment line
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    vim.cmd "set formatoptions-=cro"
  end,
})

--- Highlights yanked text briefly to provide visual feedback
--- Creates a temporary highlight in the "Visual" group for 200ms
--- whenever text is yanked (copied), making it clear what was selected
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  callback = function()
    vim.highlight.on_yank { higroup = "Visual", timeout = 200 }
  end,
})

--- Sets up highlighting for the illuminated word feature on Neovim startup
--- Links the illuminatedWord highlight group to LspReferenceText
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    vim.cmd "hi link illuminatedWord LspReferenceText"
  end,
})

--- Displays diagnostic information in a floating window when cursor is stationary
--- Creates a non-focusable popup with diagnostic details on CursorHold event
--- The floating window automatically closes when the cursor moves or focus changes
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local opts = {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = "rounded",
      source = "always",
      prefix = " ",
      scope = "cursor",
    }
    vim.diagnostic.open_float(nil, opts)
  end,
})

-- Restore last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup "last_loc",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

--- Creates a user command to toggle automatic formatting on save
--- @param args table Command arguments with 'bang' property
--- Usage: :AutoFormatOnSaveToggle - Toggle globally
--- Usage: :AutoFormatOnSaveToggle! - Toggle for current buffer only
vim.api.nvim_create_user_command("AutoFormatOnSaveToggle", function(args)
  local autoformat_var = args.bang and vim.b or vim.g

  if autoformat_var.disable_autoformat then
    autoformat_var.disable_autoformat = false
    vim.notify("autoformat-on-save re-enabled", "info")
  else
    autoformat_var.disable_autoformat = true
    vim.notify("autoformat-on-save disabled", "info")
  end
end, {
  desc = "Toggle autoformat-on-save",
  bang = true,
})

--- Creates a user command to toggle LSP inlay hints
--- Inlay hints show additional type/parameter information inline in the editor
--- Command will notify the user of the new state after toggling
--- Usage: :ToggleInlayHint - Switch between enabled/disabled states
vim.api.nvim_create_user_command("ToggleInlayHint", function()
  ---@diagnostic disable-next-line: missing-parameter
  local is_enabled = vim.lsp.inlay_hint.is_enabled()
  vim.lsp.inlay_hint.enable(not is_enabled)

  if not is_enabled then
    vim.notify("Inlay hint enabled", vim.log.levels.INFO)
  else
    vim.notify("Inlay hint disabled", vim.log.levels.INFO)
  end
end, {
  desc = "Toggle inlay hint",
  bang = true,
})

local codecompanion_augroup = vim.api.nvim_create_augroup("CodeCompanionFiletype", { clear = true })

vim.api.nvim_create_autocmd({
  "BufEnter",
  "BufWinEnter",
  "BufRead",
  "BufReadPost",
  "BufNewFile",
  "BufAdd",
  "BufCreate",
  "FileType",
  "WinEnter",
  "TabEnter",
  "FocusGained",
  "VimEnter",
  "SessionLoadPost",
}, {
  group = codecompanion_augroup,
  pattern = "*",
  callback = function(args)
    if not vim.api.nvim_buf_is_valid(args.buf) then
      return
    end

    -- Only process if filetype is codecompanion and not already processed
    if vim.bo[args.buf].filetype == "codecompanion" then
      -- Check if already processed to avoid redundant operations
      if not vim.b[args.buf].codecompanion_processed then
        vim.b[args.buf].codecompanion_processed = true

        vim.bo[args.buf].filetype = "markdown"
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      end
    end
  end,
})
