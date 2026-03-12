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

function M.load_env_file(filepath)
  filepath = filepath:gsub("^~", vim.loop.os_homedir())

  local env = {}
  local file = io.open(filepath, "r")
  if not file then
    return env
  end

  for line in file:lines() do
    if not line:match "^%s*#" and line:match "%S" then
      local key, value = line:match "^%s*([%w_]+)%s*=%s*(.-)%s*$"
      if key and value then
        env[key] = value
        vim.env[key] = value
      end
    end
  end

  file:close()
  return env
end

--- Cycles to the next buffer and shows a notification with the buffer name
--- Provides visual feedback similar to cybu.nvim
function M.next_buffer()
  local current = vim.api.nvim_get_current_buf()
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  if #buffers <= 1 then
    return
  end

  local current_idx = nil
  for i, buf in ipairs(buffers) do
    if buf == current then
      current_idx = i
      break
    end
  end

  if not current_idx then
    return
  end

  local next_idx = current_idx + 1
  if next_idx > #buffers then
    next_idx = 1
  end

  local next_buf = buffers[next_idx]
  vim.api.nvim_set_current_buf(next_buf)

  local bufname = vim.api.nvim_buf_get_name(next_buf)
  if bufname == "" then
    bufname = "[No Name]"
  else
    bufname = vim.fn.fnamemodify(bufname, ":t")
  end

  vim.notify("Buffer: " .. bufname .. " (" .. next_idx .. "/" .. #buffers .. ")", vim.log.levels.INFO)
end

--- Cycles to the previous buffer and shows a notification with the buffer name
function M.prev_buffer()
  local current = vim.api.nvim_get_current_buf()
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  if #buffers <= 1 then
    return
  end

  local current_idx = nil
  for i, buf in ipairs(buffers) do
    if buf == current then
      current_idx = i
      break
    end
  end

  if not current_idx then
    return
  end

  local prev_idx = current_idx - 1
  if prev_idx < 1 then
    prev_idx = #buffers
  end

  local prev_buf = buffers[prev_idx]
  vim.api.nvim_set_current_buf(prev_buf)

  local bufname = vim.api.nvim_buf_get_name(prev_buf)
  if bufname == "" then
    bufname = "[No Name]"
  else
    bufname = vim.fn.fnamemodify(bufname, ":t")
  end

  vim.notify("Buffer: " .. bufname .. " (" .. prev_idx .. "/" .. #buffers .. ")", vim.log.levels.INFO)
end

--- Extracts sortable items from text based on delimiter
--- @param line string The line to parse
--- @param delimiter string|nil The delimiter to use (auto-detected if nil)
--- @return table items The extracted items
--- @return table positions The start/end positions of each item
local function extract_items(line, delimiter)
  local items = {}
  local positions = {}

  if delimiter and delimiter ~= "" then
    local pattern = "([^" .. delimiter .. "]+)"
    local pos = 1
    for match in line:gmatch(pattern) do
      local start_pos, end_pos = line:find(match, pos, true)
      if start_pos then
        table.insert(items, vim.trim(match))
        table.insert(positions, { start_pos, end_pos })
        pos = end_pos + 1
      end
    end
  else
    table.insert(items, vim.trim(line))
    table.insert(positions, { 1, #line })
  end

  return items, positions
end

--- Detects the most likely delimiter in a line
--- @param line string The line to analyze
--- @return string|nil delimiter The detected delimiter or nil
local function detect_delimiter(line)
  local delimiters = { ",", "|", ":", ";", "\t", "  " }
  local counts = {}

  for _, delim in ipairs(delimiters) do
    local _, count = line:gsub(delim, "")
    counts[delim] = count
  end

  local max_delim = nil
  local max_count = 0
  for delim, count in pairs(counts) do
    if count > max_count then
      max_count = count
      max_delim = delim
    end
  end

  return max_count > 0 and max_delim or nil
end

--- Natural comparison function for sorting
--- Handles numbers within strings (e.g., "item1", "item2", "item10")
--- @param a string First item
--- @param b string Second item
--- @return boolean
local function natural_compare(a, b)
  local function pad_numbers(s)
    return s:gsub("%d+", function(n)
      return string.format("%020d", tonumber(n))
    end)
  end
  return pad_numbers(a:lower()) < pad_numbers(b:lower())
end

--- Sorts lines or delimited items in the given range
--- Delimiter-aware: auto-detects commas, pipes, colons, etc.
--- Natural sorting: handles numbers correctly (item1, item2, item10)
--- @param opts table Options table
---   - delimiter: string|nil - Delimiter to use (auto-detected if nil)
---   - natural: boolean - Use natural sorting (default: true)
---   - unique: boolean - Remove duplicates (default: false)
---   - reverse: boolean - Reverse sort order (default: false)
function M.sort(opts)
  opts = opts or {}
  local delimiter = opts.delimiter
  local use_natural = opts.natural ~= false
  local unique = opts.unique or false
  local reverse = opts.reverse or false

  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"

  if start_line == 0 or end_line == 0 or start_line > end_line then
    vim.notify("No range selected", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return
  end

  local has_visual_selection = vim.fn.mode() == "v" or vim.fn.mode() == "V"
  local is_single_line = #lines == 1

  if is_single_line and has_visual_selection then
    delimiter = delimiter or detect_delimiter(lines[1])

    if not delimiter then
      vim.cmd "'<,'>sort"
      return
    end

    local items, positions = extract_items(lines[1], delimiter)

    if #items <= 1 then
      vim.cmd "'<,'>sort"
      return
    end

    local compare_fn = use_natural and natural_compare or function(a, b)
      return a:lower() < b:lower()
    end

    local sorted_indices = {}
    for i = 1, #items do
      sorted_indices[i] = i
    end

    table.sort(sorted_indices, function(a, b)
      if reverse then
        return compare_fn(items[b], items[a])
      else
        return compare_fn(items[a], items[b])
      end
    end)

    if unique then
      local seen = {}
      local unique_indices = {}
      for _, idx in ipairs(sorted_indices) do
        local item_lower = items[idx]:lower()
        if not seen[item_lower] then
          seen[item_lower] = true
          table.insert(unique_indices, idx)
        end
      end
      sorted_indices = unique_indices
    end

    local sorted_items = {}
    for _, idx in ipairs(sorted_indices) do
      table.insert(sorted_items, items[idx])
    end

    local new_line = table.concat(sorted_items, delimiter .. " ")
    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, { new_line })
  else
    local compare_fn = use_natural and natural_compare or function(a, b)
      return a:lower() < b:lower()
    end

    local sorted_lines = vim.deepcopy(lines)
    table.sort(sorted_lines, function(a, b)
      if reverse then
        return compare_fn(b, a)
      else
        return compare_fn(a, b)
      end
    end)

    if unique then
      local seen = {}
      local unique_lines = {}
      for _, line in ipairs(sorted_lines) do
        local line_lower = line:lower()
        if not seen[line_lower] then
          seen[line_lower] = true
          table.insert(unique_lines, line)
        end
      end
      sorted_lines = unique_lines
    end

    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, sorted_lines)
  end
end

return M
