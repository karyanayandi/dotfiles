local lspconfig = require "lspconfig"

return {
  root_dir = lspconfig.util.root_pattern "deno.json",
  settings = {
    inlayHints = {
      parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = true },
      parameterTypes = { enabled = true },
      variableTypes = { enabled = true, suppressWhenTypeMatchesName = true },
      propertyDeclarationTypes = { enabled = true },
      functionLikeReturnTypes = { enable = true },
      enumMemberValues = { enabled = true },
    },
  },
}
