
local icons = require "config.icons"

return {
  "MeanderingProgrammer/render-markdown.nvim",
  lazy = false,
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "markdown", "markdown_inline", "copilot-chat", "copilot-overlay", "copilot-diff", "Avante", "codecompanion" },
  opts = {
    render_modes = { "n", "c", "t", "v", "V" },
    file_types = { "markdown", "markdown_inline", "copilot-chat", "copilot-overlay", "copilot-diff", "Avante" },
    anti_conceal = {
      enabled = true,
      ignore = {
        code_background = true,
        sign = true,
      },
      above = 0,
      below = 0,
    },
    code = {
      enabled = true,
      sign = true,
      style = "full",
      position = "left",
      language_pad = 0,
      language_name = true,
      disable_background = { "diff" },
      width = "full",
      left_margin = 0,
      left_pad = 0,
      right_pad = 0,
      min_width = 0,
      border = "thin",
      above = icons.ui.CodeAbove,
      below = icons.ui.CodeBelow,
      highlight = "RenderMarkdownCode",
      highlight_inline = "RenderMarkdownCodeInline",
      highlight_language = nil,
    },
    callout = {
      note = { raw = "[!NOTE]", rendered = icons.markdown.callouts.Note .. " Note", highlight = "RenderMarkdownInfo" },
      tip = { raw = "[!TIP]", rendered = icons.markdown.callouts.Tip .. " Tip", highlight = "RenderMarkdownSuccess" },
      important = { raw = "[!IMPORTANT]", rendered = icons.markdown.callouts.Important .. " Important", highlight = "RenderMarkdownHint" },
      warning = { raw = "[!WARNING]", rendered = icons.markdown.callouts.Warning .. " Warning", highlight = "RenderMarkdownWarn" },
      caution = { raw = "[!CAUTION]", rendered = icons.markdown.callouts.Caution .. " Caution", highlight = "RenderMarkdownError" },
      abstract = { raw = "[!ABSTRACT]", rendered = icons.markdown.callouts.Abstract .. " Abstract", highlight = "RenderMarkdownInfo" },
      summary = { raw = "[!SUMMARY]", rendered = icons.markdown.callouts.Summary .. " Summary", highlight = "RenderMarkdownInfo" },
      tldr = { raw = "[!TLDR]", rendered = icons.markdown.callouts.Tldr .. " Tldr", highlight = "RenderMarkdownInfo" },
      info = { raw = "[!INFO]", rendered = icons.markdown.callouts.Info .. " Info", highlight = "RenderMarkdownInfo" },
      todo = { raw = "[!TODO]", rendered = icons.markdown.callouts.Todo .. " Todo", highlight = "RenderMarkdownInfo" },
      hint = { raw = "[!HINT]", rendered = icons.markdown.callouts.Hint .. " Hint", highlight = "RenderMarkdownSuccess" },
      success = { raw = "[!SUCCESS]", rendered = icons.markdown.callouts.Success .. " Success", highlight = "RenderMarkdownSuccess" },
      check = { raw = "[!CHECK]", rendered = icons.markdown.callouts.Check .. " Check", highlight = "RenderMarkdownSuccess" },
      done = { raw = "[!DONE]", rendered = icons.markdown.callouts.Done .. " Done", highlight = "RenderMarkdownSuccess" },
      question = { raw = "[!QUESTION]", rendered = icons.markdown.callouts.Question .. " Question", highlight = "RenderMarkdownWarn" },
      help = { raw = "[!HELP]", rendered = icons.markdown.callouts.Help .. " Help", highlight = "RenderMarkdownWarn" },
      faq = { raw = "[!FAQ]", rendered = icons.markdown.callouts.Faq .. " Faq", highlight = "RenderMarkdownWarn" },
      attention = { raw = "[!ATTENTION]", rendered = icons.markdown.callouts.Attention .. " Attention", highlight = "RenderMarkdownWarn" },
      failure = { raw = "[!FAILURE]", rendered = icons.markdown.callouts.Failure .. " Failure", highlight = "RenderMarkdownError" },
      fail = { raw = "[!FAIL]", rendered = icons.markdown.callouts.Fail .. " Fail", highlight = "RenderMarkdownError" },
      missing = { raw = "[!MISSING]", rendered = icons.markdown.callouts.Missing .. " Missing", highlight = "RenderMarkdownError" },
      danger = { raw = "[!DANGER]", rendered = icons.markdown.callouts.Danger .. " Danger", highlight = "RenderMarkdownError" },
      error = { raw = "[!ERROR]", rendered = icons.markdown.callouts.Error .. " Error", highlight = "RenderMarkdownError" },
      bug = { raw = "[!BUG]", rendered = icons.markdown.callouts.Bug .. " Bug", highlight = "RenderMarkdownError" },
      example = { raw = "[!EXAMPLE]", rendered = icons.markdown.callouts.Example .. " Example", highlight = "RenderMarkdownHint" },
      quote = { raw = "[!QUOTE]", rendered = icons.markdown.callouts.Quote .. " Quote", highlight = "RenderMarkdownQuote" },
      cite = { raw = "[!CITE]", rendered = icons.markdown.callouts.Cite .. " Cite", highlight = "RenderMarkdownQuote" },
    },
    overrides = {
      filetype = {
        codecompanion = {
          html = {
            tag = {
              buf = { icon = icons.markdown.tags.Buf, highlight = "CodeCompanionChatIcon" },
              file = { icon = icons.markdown.tags.File, highlight = "CodeCompanionChatIcon" },
              group = { icon = icons.markdown.tags.Group, highlight = "CodeCompanionChatIcon" },
              help = { icon = icons.markdown.tags.Help, highlight = "CodeCompanionChatIcon" },
              image = { icon = icons.markdown.tags.Image, highlight = "CodeCompanionChatIcon" },
              rules = { icon = icons.markdown.tags.Rules, highlight = "CodeCompanionChatIcon" },
              symbols = { icon = icons.markdown.tags.Symbols, highlight = "CodeCompanionChatIcon" },
              tool = { icon = icons.markdown.tags.Tool, highlight = "CodeCompanionChatIcon" },
              url = { icon = icons.markdown.tags.Url, highlight = "CodeCompanionChatIcon" },
            },
          },
        },
      },
    },
  },
  config = function()
    -- local colors = require("aurora.colors").load()
    -- vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = colors.highlight })
    vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#252931" })
  end,
}
