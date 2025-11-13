return {
  settings = {
    svelte = {
      plugin = {
        typescript = {
          enable = true,
          diagnostics = { enable = true },
          hover = { enable = true },
          documentSymbols = { enable = true },
          completions = { enable = true },
          findReferences = { enable = true },
          definitions = { enable = true },
          rename = { enable = true },
          codeActions = { enable = true },
        },
      },
    },
    typescript = {
      inlayHints = {
        parameterNames = { enabled = "all" },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
}
