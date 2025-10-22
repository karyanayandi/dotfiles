-- local util = require("lspconfig/util").util

return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  -- root_dir = util.root_pattern("go.work", "go.mod", ".git"),
  settings = {
    analyses = {
      unusedparams = true,
      unreachable = false,
      nilness = true,
      shadow = true,
      unusedwrite = true,
      fieldalignment = true,
      deepreturn = true,
      staticcheck = true,
    },
    completeUnimported = true,
    usePlaceholders = true,
    hints = {
      rangeVariableTypes = true,
      parameterNames = true,
      constantValues = true,
      assignVariableTypes = true,
      compositeLiteralFields = true,
      compositeLiteralTypes = true,
      functionTypeParameters = true,
    },
  },
}
