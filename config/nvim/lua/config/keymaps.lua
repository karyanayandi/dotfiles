-- luacheck: globals vim
-- luacheck: ignore 631

local M = {}

local opts = { noremap = true, silent = true }

local keymap = vim.api.nvim_set_keymap

keymap("n", "<Space>", "", opts)

-- "n" normal
-- "i" insert
-- "v" visual
-- "x" visual block

-- Navigation
-- keymap("n", "<C-h>", "<C-w>h", opts)
-- keymap("n", "<C-j>", "<C-w>j", opts)
-- keymap("n", "<C-k>", "<C-w>k", opts)
-- keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Naviagate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Native buffer cycling with notification (replaces cybu.nvim)
keymap("n", "L", "<cmd>lua require('config.functions').next_buffer()<CR>", opts)
keymap("n", "H", "<cmd>lua require('config.functions').prev_buffer()<CR>", opts)

--  Select All
keymap("n", "<C-a>", "gg<S-v>G", opts)

-- Save
keymap("n", "<C-s>", ":w!<CR>", opts)
keymap("i", "<C-s>", "<ESC>:w!<CR>", opts)
keymap("v", "<C-s>", "<ESC>:w!<CR>", opts)
keymap("x", "<C-s>", "<ESC>:w!<CR>", opts)

-- Fast exit from insert mode
keymap("i", "jk", "<ESC>", opts)
keymap("i", "<C-]>", "<ESC>", opts)
keymap("v", "jk", "<ESC>", opts)
keymap("v", "<C-]>", "<ESC>", opts)

-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "p", '"_dP', opts)
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)

-- Split Windows
keymap("n", ";v", "<cmd>vsplit<cr>", opts)
keymap("n", ";s", "<cmd>split<cr>", opts)

-- AI
keymap(
  "n",
  ";a",
  "<cmd>CodeCompanionChat Toggle<cr>",
  { desc = "Open Code Companion Chat", noremap = true, silent = true }
)

-- Find
keymap("n", ";f", "<cmd>FzfLua git_files<cr>", { desc = "Find git files", noremap = true, silent = true })
keymap("n", ";d", "<cmd>FzfLua files<cr>", { desc = "Find files", noremap = true, silent = true })

-- Find texts
keymap("n", ";t", "<cmd>FzfLua live_grep<cr>", { desc = "Find text", noremap = true, silent = true })

-- Find buffers
keymap("n", ";b", "<cmd>FzfLua buffers<cr>", { desc = "Find buffers", noremap = true, silent = true })

-- Find git branches
keymap("n", ";g", "<cmd>FzfLua git_branches<cr>", { desc = "Find git branches", noremap = true, silent = true })

-- Find help tags
keymap("n", ";h", "<cmd>FzfLua help_tags<cr>", { desc = "Find help tags", noremap = true, silent = true })

-- Tree
keymap("n", ";e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle NvimTree", noremap = true, silent = true })

-- Find monorepo
-- keymap(
--   "n",
--   ";m",
--   "<cmd>lua require('telescope').extensions.monorepo.monorepo()<cr>",
--   { desc = "Find monorepo", noremap = true, silent = true }
-- )

-- Search and replace
keymap(
  "n",
  ";r",
  "<cmd>lua require('spectre').open_file_search()<cr>",
  { desc = "Search and replace", noremap = true, silent = true }
)

-- Undo history
keymap("n", ";u", "<cmd>FzfLua undotree<cr>", { desc = "Undo history", noremap = true, silent = true })

-- Bufdelete
keymap("n", "Q", ":lua require('snacks').bufdelete()<cr>", opts)
keymap("n", ";q", ":%bd<cr>", { desc = "Close all buffers", noremap = true, silent = true })

-- Show document symbol
keymap("n", "<m-t>", "<cmd>lua vim.lsp.buf.document_symbol()<cr>", opts)

-- No HL
keymap("n", ";z", "<cmd>nohlsearch<cr>", { desc = "No highlight", noremap = true, silent = true })

-- Resume last picker
keymap("n", "<F3>", "<cmd>FzfLua resume<cr>", opts)

-- Find commands
keymap("n", "<F4>", "<cmd>FzfLua commands<CR>", opts)

-- Show references
keymap("n", "<F7>", "<cmd>lua vim.lsp.buf.references()<CR>", opts)

-- Show definition
keymap("n", "<F8>", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)

-- Show tags
keymap(
  "v",
  "//",
  [[y/\v<c-r>=escape(@",'/\')<cr><cr>]],
  { desc = "Search for selected text", noremap = true, silent = true }
)

-- Show in Browser
keymap("n", "gx", [[:silent execute '!$BROWSER ' . shellescape(expand('<cfile>'), 1)<CR>]], opts)

M.show_documentation = function()
  local filetype = vim.bo.filetype
  if vim.tbl_contains({ "vim", "help" }, filetype) then
    vim.cmd("h " .. vim.fn.expand "<cword>")
  elseif vim.tbl_contains({ "man" }, filetype) then
    vim.cmd("Man " .. vim.fn.expand "<cword>")
  else
    vim.lsp.buf.hover()
  end
end

vim.api.nvim_set_keymap("n", "J", ":lua require('config.keymaps').show_documentation()<CR>", opts)

return M
