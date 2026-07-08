local function generate_commit()
  vim.notify("⏳ Generating commit message…", vim.log.levels.INFO, { title = "pi.nvim" })

  -- capture visual selection range before async job
  local visual_range = nil
  local buf = vim.api.nvim_get_current_buf()
  local mode = vim.fn.mode()
  if mode:match("[vV\22]") then
    local _, sl, sc = unpack(vim.fn.getpos("'<"))
    local _, el, ec = unpack(vim.fn.getpos("'>"))
    -- exit visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    visual_range = { buf = buf, sl = sl, sc = sc, el = el, ec = ec, mode = mode }
  end

  local diff = vim.fn.system("git diff --no-ext-diff --staged")
  if vim.v.shell_error ~= 0 or vim.trim(diff) == "" then
    -- fallback: try --cached
    diff = vim.fn.system("git diff --no-ext-diff --cached")
    if vim.v.shell_error ~= 0 or vim.trim(diff) == "" then
      vim.notify("No staged changes", vim.log.levels.WARN, { title = "pi.nvim" })
      return
    end
  end
  diff = vim.trim(diff)

  local prompt = string.format(
    [[You are an expert at following the commitizen convention and conventional commit specification.
Keep the title under 50 characters and wrap message at maximum 72 characters.
Given the git diff below, generate ONLY the commit message, nothing else:

```diff
%s
```]],
    diff
  )

  -- run pi via jobstart with stdin for large prompts
  local stdout = {}
  local stderr = {}
  local job_id = vim.fn.jobstart({
    "pi", "-p",
    "--provider", "openrouter",
    "--model", "openai/gpt-oss-20b:free",
  }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          stdout[#stdout + 1] = line
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          stderr[#stderr + 1] = line
        end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        local err = table.concat(stderr, "\n")
        vim.notify(
          "✗ Failed: " .. (err ~= "" and err or "exit code " .. code),
          vim.log.levels.ERROR,
          { title = "pi.nvim" }
        )
        return
      end
      local text = table.concat(stdout, "\n")
      if text == "" then
        vim.notify("✗ Empty response from pi", vim.log.levels.WARN, { title = "pi.nvim" })
        return
      end
      vim.notify("✓ Commit message generated", vim.log.levels.INFO, { title = "pi.nvim" })
      if visual_range then
        local lines = vim.split(text, "\n")
        if visual_range.mode == "V" then
          -- line-wise: replace full lines including newlines
          vim.api.nvim_buf_set_text(buf, visual_range.sl - 1, 0, visual_range.el, 0, lines)
        else
          -- char/block-wise: replace exact selection
          vim.api.nvim_buf_set_text(buf, visual_range.sl - 1, visual_range.sc - 1, visual_range.el - 1, visual_range.ec, lines)
        end
      else
        vim.api.nvim_put(vim.split(text, "\n"), "c", true, true)
      end
    end,
  })
  if job_id <= 0 then
    vim.notify("✗ Failed to start pi", vim.log.levels.ERROR, { title = "pi.nvim" })
    return
  end
  -- send prompt via stdin
  vim.fn.chansend(job_id, prompt)
  vim.fn.chanclose(job_id, "stdin")
end

return {
  "pablopunk/pi.nvim",

  event = "VeryLazy",

  opts = {
    provider = "ollama",
    thinking = "off",
    context = {
      max_bytes = 24000,
      ask = { surrounding_lines = 80 },
      selection = { surrounding_lines = 40 },
      diagnostics = { enabled = false },
    },
    skills = true,
    extensions = true,
  },

  config = function(_, opts)
    require("pi").setup(opts)
    vim.keymap.set({ "n", "i", "v" }, "<leader>ag", generate_commit, { desc = "Generate commit message" })
    vim.keymap.set("n", "<leader>aa", ":PiAsk<CR>", { desc = "Ask pi (buffer context)" })
    vim.keymap.set("v", "<leader>aa", ":PiAskSelection<CR>", { desc = "Ask pi (selection context)" })
    vim.api.nvim_create_user_command("GenerateCommit", generate_commit, { desc = "Generate commit message from staged diff" })
  end,
}
