return {
  "numToStr/Comment.nvim",
  event = "BufRead",
  config = function()
    require("Comment").setup {
      pre_hook = function(ctx)
        if
            vim.bo.filetype == "typescriptreact"
            or vim.bo.filetype == "javascriptreact"
            or vim.bo.filetype == "javascript"
            or vim.bo.filetype == "typescript"
        then
          local U = require "Comment.utils"

          local type = ctx.ctype == U.ctype.linewise and "__default" or "__multiline"

          local location = nil

          if ctx.ctype == U.ctype.blockwise then
            location = require("ts_context_commentstring.utils").get_cursor_location()
          elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
            location = require("ts_context_commentstring.utils").get_visual_start_location()
          end

          ---@diagnostic disable-next-line: return-type-mismatch
          return require("ts_context_commentstring.internal").calculate_commentstring {
            key = type,
            location = location,
          }
        end
      end,
    }
  end,
}
