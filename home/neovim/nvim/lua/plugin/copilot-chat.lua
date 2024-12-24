-- luacheck: globals vim

local prompts = {
  -- Code related prompts
  Explain = "Please explain how the following code works.",
  Review = "Please review the following code and provide suggestions for improvement.",
  Tests = "Please explain how the selected code works, then generate unit tests for it.",
  Refactor = "Please refactor the following code to improve its clarity and readability.",
  FixCode = "Please fix the following code to make it work as intended.",
  FixError = "Please explain the error in the following text and provide a solution.",
  BetterNamings = "Please provide better names for the following variables and functions.",
  Documentation = "Please provide documentation for the following code.",
  SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
  SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
  -- Text related prompts
  Summarize = "Please summarize the following text.",
  Spelling = "Please correct any grammar and spelling errors in the following text.",
  Wording = "Please improve the grammar and wording of the following text.",
  Concise = "Please rewrite the following text to make it more concise.",
}

return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      highlight_headers = false,
      -- separator = "---",
      question_header = "[!HELP] User ",
      answer_header = "[!SUMMARY] Copilot ",
      error_header = "[!ERROR] Error",
      prompts = prompts,
      auto_follow_cursor = true,
      mappings = {
        complete = {
          detail = "Use @<Tab> or /<Tab> for options.",
          insert = "<Tab>",
        },
        close = {
          normal = "q",
          insert = "<C-c>",
        },
        reset = {
          normal = "<C-x>",
          insert = "<C-x>",
        },
        submit_prompt = {
          normal = "<CR>",
          insert = "<C-CR>",
        },
        accept_diff = {
          normal = "<C-y>",
          insert = "<C-y>",
        },
        show_help = false,
      },
    },
    config = function(_, opts)
      local chat = require "CopilotChat"
      chat.setup(opts)

      local select = require "CopilotChat.select"
      vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
        chat.ask(args.args, { selection = select.visual })
      end, { nargs = "*", range = true })

      -- Inline chat with Copilot
      vim.api.nvim_create_user_command("CopilotChatInline", function(args)
        chat.ask(args.args, {
          selection = select.visual,
          window = {
            layout = "float",
            relative = "cursor",
            width = 1,
            height = 0.4,
            row = 1,
          },
        })
      end, { nargs = "*", range = true })

      -- Restore CopilotChatBuffer
      vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
        chat.ask(args.args, { selection = select.buffer })
      end, { nargs = "*", range = true })

      -- Custom buffer for CopilotChat
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "copilot-*",
        callback = function()
          vim.opt_local.relativenumber = true
          vim.opt_local.number = true

          -- Get current filetype and set it to markdown if the current filetype is copilot-chat
          local ft = vim.bo.filetype
          if ft == "copilot-chat" then
            vim.bo.filetype = "markdown"
          end
        end,
      })
    end,
    event = "VeryLazy",
    keys = {
      -- Show prompts actions with telescope
      {
        "<leader>ap",
        function()
          local actions = require "CopilotChat.actions"
          require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
        end,
        desc = "Prompt actions",
      },
      {
        "<leader>ap",
        function()
          require("CopilotChat.integrations.telescope").pick(require("CopilotChat.actions").prompt_actions {
            selection = require("CopilotChat.select").visual,
          })
        end,
        mode = "x",
        desc = "Prompt actions",
      },
      -- Code related commands
      { "<leader>aR", "<cmd>CopilotChatRefactor<cr>", desc = "Refactor code" },
      { "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "Explain code" },
      { "<leader>an", "<cmd>CopilotChatBetterNamings<cr>", desc = "Better Naming" },
      { "<leader>ao", "<cmd>CopilotChatReview<cr>", desc = "Optimize code" },
      { "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "Review code" },
      { "<leader>at", "<cmd>CopilotChatTests<cr>", desc = "Generate tests" },
      -- Chat with Copilot in visual mode
      {
        "<leader>av",
        ":CopilotChatVisual",
        mode = "x",
        desc = "Open in vertical split Copilot Chat",
      },
      {
        "<leader>ax",
        ":CopilotChatInline<cr>",
        mode = "x",
        desc = "Inline chat",
      },
      -- Custom input for CopilotChat
      {
        "<leader>ai",
        function()
          local input = vim.fn.input "Ask Copilot: "
          if input ~= "" then
            vim.cmd("CopilotChat " .. input)
          end
        end,
        desc = "Ask input",
      },
      -- Generate commit message based on the git diff
      {
        "<leader>am",
        "<cmd>CopilotChatCommit<cr>",
        desc = "Generate commit message for all changes",
      },
      -- Quick chat with Copilot
      {
        "<leader>aq",
        function()
          local input = vim.fn.input "Quick Chat: "
          if input ~= "" then
            vim.cmd("CopilotChatBuffer " .. input)
          end
        end,
        desc = "Quick chat",
      },
      { "<leader>ad", "<cmd>CopilotChatDebugInfo<cr>", desc = "Debug Info" },
      { "<leader>af", "<cmd>CopilotChatFix<cr>", desc = "Fix Diagnostic" },
      -- Clear buffer and chat history
      { "<leader>ac", "<cmd>CopilotChatReset<cr>", desc = "Clear buffer and chat history" },
      -- Toggle Copilot Chat Vsplit
      { "<leader>av", "<cmd>CopilotChatToggle<cr>", desc = "Toggle" },
      -- Copilot Chat Models
      { "<leader>a?", "<cmd>CopilotChatModels<cr>", desc = "Select Models" },
      -- Copilot Chat Agents
      { "<leader>aa", "<cmd>CopilotChatAgents<cr>", desc = "Select Agents" },
    },
  },
}
