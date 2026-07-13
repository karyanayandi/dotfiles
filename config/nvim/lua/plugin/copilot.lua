-- luacheck: globals vim

local icons = require "config.icons"

local function find_auth_db()
  local candidates = {
    vim.fn.expand "$XDG_CONFIG_HOME/github-copilot/auth.db",
    vim.fn.expand "~/.config/github-copilot/auth.db",
    vim.fn.expand "~/Library/Application Support/github-copilot/auth.db",
  }
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 then
      return p
    end
  end
  return nil
end

local function clean_commit_message(text)
  text = vim.trim(text or "")
  if text:match "^```" then
    local lines = vim.split(text, "\n")
    if #lines >= 2 then
      table.remove(lines, 1)
      if lines[#lines]:match "^```" then
        lines[#lines] = nil
      end
      text = vim.trim(table.concat(lines, "\n"))
    end
  end
  return text
end

local function exit_visual()
  if vim.fn.mode():match "[vV\22]" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  end
end

local function capture_visual_range()
  local mode = vim.fn.mode()
  if not mode:match "[vV\22]" then
    return nil
  end
  local buf = vim.api.nvim_get_current_buf()
  local _, sl, sc = unpack(vim.fn.getpos ".")
  local _, el, ec = unpack(vim.fn.getpos "v")
  if sl > el or (sl == el and sc > ec) then
    sl, sc, el, ec = el, ec, sl, sc
  end
  if mode == "V" then
    return { buf = buf, mode = mode, sl = sl, el = el }
  end
  return { buf = buf, mode = mode, sl = sl, sc = sc, el = el, ec = ec }
end

local function insert_commit_text(text, r)
  local lines = vim.split(text, "\n")
  if r then
    local buf = r.buf
    if r.mode == "V" then
      vim.api.nvim_buf_set_lines(buf, r.sl - 1, r.el, false, lines)
    else
      vim.api.nvim_buf_set_text(buf, r.sl - 1, r.sc - 1, r.el - 1, r.ec, lines)
    end
  else
    vim.api.nvim_put(lines, "c", true, true)
  end
end

local function generate_commit()
  vim.notify(icons.misc.Hourglass .. " Generating commit message...", vim.log.levels.INFO, { title = "Copilot" })

  -- capture visual selection while still in visual mode; use '.' and 'v' marks because '< and '> are only set after leaving visual mode.
  local visual_range = capture_visual_range()

  local diff = vim.fn.system "git diff --no-ext-diff --staged"
  if vim.v.shell_error ~= 0 or vim.trim(diff) == "" then
    diff = vim.fn.system "git diff --no-ext-diff --cached"
    if vim.v.shell_error ~= 0 or vim.trim(diff) == "" then
      exit_visual()
      vim.notify("No staged changes", vim.log.levels.WARN, { title = "Copilot" })
      return
    end
  end
  diff = vim.trim(diff)

  local auth_db = find_auth_db()
  if not auth_db then
    exit_visual()
    vim.notify("Copilot auth.db not found; run :Copilot auth", vim.log.levels.ERROR, { title = "Copilot" })
    return
  end

  vim.system(
    { "sqlite3", auth_db, "SELECT token_ciphertext FROM oauth_tokens ORDER BY updated_at DESC LIMIT 1;" },
    {},
    function(out)
      if out.code ~= 0 then
        vim.schedule(function()
          exit_visual()
          vim.notify(
            "Failed to read Copilot token: " .. (out.stderr or ""),
            vim.log.levels.ERROR,
            { title = "Copilot" }
          )
        end)
        return
      end

      local oauth = vim.trim(out.stdout)
      if oauth == "" then
        vim.schedule(function()
          exit_visual()
          vim.notify("No Copilot OAuth token found; run :Copilot auth", vim.log.levels.ERROR, { title = "Copilot" })
        end)
        return
      end

      vim.system({
        "curl",
        "-sS",
        "https://api.github.com/copilot_internal/v2/token",
        "-H",
        "authorization: token " .. oauth,
        "-H",
        "editor-version: Neovim/0.11.0",
        "-H",
        "editor-plugin-version: copilot.lua/1.0.0",
      }, {}, function(token_out)
        if token_out.code ~= 0 or token_out.stdout == "" then
          vim.schedule(function()
            exit_visual()
            vim.notify("Failed to fetch Copilot session token", vim.log.levels.ERROR, { title = "Copilot" })
          end)
          return
        end

        local ok, token_data = pcall(vim.json.decode, token_out.stdout)
        if not ok or not token_data.token then
          vim.schedule(function()
            exit_visual()
            vim.notify("Invalid Copilot session response", vim.log.levels.ERROR, { title = "Copilot" })
          end)
          return
        end

        local api = token_data.endpoints and token_data.endpoints.api or "https://api.githubcopilot.com"
        local prompt = string.format(
          [[Generate a concise conventional commit message for this diff.
Title under 50 characters, body wrapped at 72 characters.
Output only the commit message, no explanation.
```diff
%s
```]],
          diff
        )
        local body = vim.json.encode {
          model = "gpt-4o",
          messages = {
            {
              role = "system",
              content = "You generate concise conventional commit messages. Title under 50 chars, body wrapped at 72. Only output the commit message.",
            },
            { role = "user", content = prompt },
          },
          temperature = 0.1,
          max_tokens = 300,
          stream = false,
        }

        vim.system({
          "curl",
          "-sS",
          "-X",
          "POST",
          api .. "/chat/completions",
          "-H",
          "authorization: Bearer " .. token_data.token,
          "-H",
          "content-type: application/json",
          "-H",
          "copilot-integration-id: vscode-chat",
          "-H",
          "editor-version: Neovim/0.11.0",
          "-H",
          "editor-plugin-version: copilot.lua/1.0.0",
          "-d",
          "@-",
        }, { stdin = body }, function(chat_out)
          vim.schedule(function()
            if chat_out.code ~= 0 then
              exit_visual()
              vim.notify(
                "Commit generation failed: " .. (chat_out.stderr or ""),
                vim.log.levels.ERROR,
                { title = "Copilot" }
              )
              return
            end

            local ok2, resp = pcall(vim.json.decode, chat_out.stdout)
            if not ok2 then
              exit_visual()
              vim.notify("Invalid Copilot chat response", vim.log.levels.ERROR, { title = "Copilot" })
              return
            end

            local content = resp.choices
              and resp.choices[1]
              and resp.choices[1].message
              and resp.choices[1].message.content
            if not content or vim.trim(content) == "" then
              exit_visual()
              vim.notify("Empty Copilot response", vim.log.levels.WARN, { title = "Copilot" })
              return
            end

            content = clean_commit_message(content)
            vim.notify(icons.ui.Installed .. " Commit message generated", vim.log.levels.INFO, { title = "Copilot" })
            exit_visual()
            insert_commit_text(content, visual_range)
          end)
        end)
      end)
    end
  )
end

return {
  "zbirenbaum/copilot.lua",
  event = { "InsertEnter", "LspAttach" },
  cmd = "Copilot",
  build = ":Copilot auth",
  config = function()
    require("copilot").setup {
      panel = {
        enabled = false,
        keymap = {
          jump_next = "<c-j>",
          jump_prev = "<c-k>",
          accept = "<c-l>",
          refresh = "r",
          open = "<M-CR>",
        },
      },
      suggestion = {
        enabled = false,
        auto_trigger = true,
        keymap = {
          accept = "<M-l>",
          next = "<M-j>",
          prev = "<M-k>",
          dismiss = "<M-h>",
        },
      },
      filetypes = {
        yaml = true,
        markdown = true,
        help = true,
        gitcommit = false,
        gitrebase = false,
        cvs = false,
      },
      copilot_node_command = "node",
      server_opts_overrides = {},
    }

    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap("n", "<C-space>", ":lua require('copilot.suggestion').toggle_auto_trigger()<CR>", opts)

    vim.keymap.set({ "n", "i", "v" }, "<leader>ag", generate_commit, { desc = "Generate commit message" })
    vim.api.nvim_create_user_command(
      "GenerateCommit",
      generate_commit,
      { desc = "Generate commit message from staged diff" }
    )
  end,
}
