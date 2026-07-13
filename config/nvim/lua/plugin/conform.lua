
return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"
    local util = require "conform.util"

    local biome_root_files = { "biome.json", "biome.jsonc" }
    local deno_root_files = { "deno.json", "deno.jsonc" }
    local oxfmt_root_files = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxc.json" }
    local prettier_root_files = {
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.json5",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettierrc.toml",
      ".prettierrc.js",
      ".prettierrc.cjs",
      ".prettierrc.mjs",
      ".prettierrc.ts",
      ".prettierrc.cts",
      ".prettierrc.mts",
      "prettier.config.js",
      "prettier.config.cjs",
      "prettier.config.mjs",
      "prettier.config.ts",
      "prettier.config.cts",
      "prettier.config.mts",
    }
    local prettier_root_set = {}
    for _, name in ipairs(prettier_root_files) do
      prettier_root_set[name] = true
    end

    local vite_root_files = {
      "vite.config.ts",
      "vite.config.js",
      "vite.config.mjs",
      "vite.config.cjs",
      "vite.config.mts",
    }

    local function has_root_file(dir, files)
      return vim.fs.find(files, { upward = true, path = dir, limit = 1 })[1] ~= nil
    end

    -- Project/workspace boundary: stop here so we never read an unrelated project's config.
    local project_root_markers = {
      "pnpm-workspace.yaml",
      "lerna.json",
      "turbo.json",
      "nx.json",
      "rush.json",
      "bun.lockb", -- bun workspaces hoist the lockfile to the repo root
      "yarn.lock", -- yarn workspaces hoist the lockfile to the repo root
    }
    local function package_has_workspaces(pkg)
      local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), "\n"))
      return ok and data and data.workspaces ~= nil
    end
    local function find_project_root(dir)
      local git = vim.fs.find(".git", { upward = true, path = dir, limit = 1 })[1]
      if git then
        return vim.fs.dirname(git)
      end
      local marker = vim.fs.find(project_root_markers, { upward = true, path = dir, limit = 1 })[1]
      if marker then
        return vim.fs.dirname(marker)
      end
      -- npm/yarn/bun workspaces declared via "workspaces" in a (root) package.json
      local pkgs = vim.fs.find("package.json", { upward = true, path = dir, limit = math.huge })
      for _, pkg in ipairs(pkgs) do
        if package_has_workspaces(pkg) then
          return vim.fs.dirname(pkg)
        end
      end
      return nil
    end

    -- Topmost directory INSIDE the project containing one of `files`.
    -- Monorepo -> root vite.config.ts; single project -> the only one. Bounded so it
    -- can't escape to another project's config above the workspace root.
    local function find_root_dir(dir, files)
      local boundary = find_project_root(dir)
      if not boundary then
        -- not a git repo / no workspace manifest: use the nearest config to stay safe
        local nearest = vim.fs.find(files, { upward = true, path = dir, limit = 1 })[1]
        return nearest and vim.fs.dirname(nearest) or nil
      end
      local top
      local current = dir
      while current and current ~= vim.fs.dirname(current) do
        for _, f in ipairs(files) do
          if vim.fn.filereadable(current .. "/" .. f) == 1 then
            top = current
            break
          end
        end
        if current == boundary then
          break
        end
        current = vim.fs.dirname(current)
      end
      return top
    end

    local function package_has_dep(pkg, name)
      local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), "\n"))
      if not ok or type(data) ~= "table" then
        return false
      end
      for _, section in ipairs { "dependencies", "devDependencies", "peerDependencies" } do
        if type(data[section]) == "table" and data[section][name] then
          return true
        end
      end
      return false
    end

    local function has_vite_plus(dir)
      if not find_root_dir(dir, vite_root_files) then
        return false
      end
      -- scan package.json upward, but only inside the project (never above the boundary)
      local boundary = find_project_root(dir)
      local pkgs = vim.fs.find("package.json", { upward = true, path = dir, limit = math.huge })
      for _, pkg in ipairs(pkgs) do
        if boundary and vim.fs.relpath(boundary, pkg) == nil then
          break -- crossed above the project boundary
        end
        if package_has_dep(pkg, "vite-plus") then
          return true
        end
      end
      return false
    end

    local function prettier_root(_, ctx)
      return vim.fs.root(ctx.dirname, function(name, path)
        if prettier_root_set[name] then
          return true
        end
        if name == "package.json" then
          local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(vim.fs.joinpath(path, name)), "\n"))
          return ok and data.prettier ~= nil
        end
        return false
      end)
    end

    local function javascript_formatter(bufnr)
      local cached = vim.b[bufnr].js_formatter
      if cached then
        return cached
      end

      local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
      local formatters
      if has_vite_plus(dir) then
        formatters = { "vp_fmt" }
      elseif has_root_file(dir, oxfmt_root_files) then
        formatters = { "oxfmt" }
      elseif has_root_file(dir, biome_root_files) then
        formatters = { "biome" }
      elseif has_root_file(dir, deno_root_files) then
        formatters = { "deno_fmt" }
      elseif prettier_root(nil, { dirname = dir }) then
        formatters = { "prettierd" }
      else
        formatters = { "oxfmt" }
      end

      vim.b[bufnr].js_formatter = formatters
      return formatters
    end

    local biome_root = util.root_file(biome_root_files)
    local deno_root = util.root_file(deno_root_files)
    local oxfmt_root = util.root_file(oxfmt_root_files)
    local vite_root = function(self, ctx)
      return find_root_dir(ctx.dirname, vite_root_files)
    end

    local formatters_by_ft = {
      astro = javascript_formatter,
      blade = { "blade-formatter" },
      c = { "clang_format" },
      css = javascript_formatter,
      go = { "gofumpt", "goimports-reviser", "golines" },
      graphql = { "prettierd" },
      html = javascript_formatter,
      javascript = javascript_formatter,
      javascriptreact = javascript_formatter,
      json = javascript_formatter,
      jsonc = javascript_formatter,
      json5 = javascript_formatter,
      lua = { "stylua" },
      markdown = javascript_formatter,
      nix = { "alejandra" },
      php = { "pretty-php" },
      python = { "isort", "black" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      svelte = javascript_formatter,
      typescript = javascript_formatter,
      typescriptreact = javascript_formatter,
      vue = javascript_formatter,
      yaml = javascript_formatter,
    }

    local function format_on_save(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      local formatters = conform.list_formatters_for_buffer(bufnr)
      local timeout_ms = 3000
      for _, name in ipairs(formatters) do
        if name == "vp_fmt" then
          timeout_ms = 10000
          break
        end
      end
      return { timeout_ms = timeout_ms, lsp_fallback = true, async = false }
    end

    conform.setup {
      formatters_by_ft = formatters_by_ft,
      formatters = {
        vp_fmt = {
          command = "vp",
          args = { "fmt", "--stdin-filepath", "$FILENAME" },
          stdin = true,
          cwd = vite_root,
          require_cwd = true,
        },
        oxfmt = {
          command = "oxfmt",
          args = { "--stdin-filepath", "$FILENAME" },
          stdin = true,
          cwd = oxfmt_root,
        },
        deno_fmt = {
          args = function(self, ctx)
            local extension = vim.bo[ctx.buf].filetype == "typescript" and "ts"
              or vim.bo[ctx.buf].filetype == "typescriptreact" and "tsx"
              or vim.bo[ctx.buf].filetype == "javascript" and "js"
              or vim.bo[ctx.buf].filetype == "javascriptreact" and "jsx"
              or "ts"
            local config_file = vim.fs.find({ "deno.json", "deno.jsonc" }, {
              upward = true,
              path = ctx.dirname,
              limit = 1,
            })[1]
            local args = { "fmt", "-", "--ext", extension }
            if config_file then
              table.insert(args, "--config")
              table.insert(args, config_file)
            end
            return args
          end,
          cwd = deno_root,
          require_cwd = true,
        },
        biome = {
          command = "node_modules/.bin/biome",
          args = { "format", "--stdin-file-path", "$FILENAME" },
          stdin = true,
          cwd = biome_root,
          require_cwd = true,
        },
        biome_fix = {
          command = "node_modules/.bin/biome",
          args = { "check", "--write", "--stdin-file-path", "$FILENAME" },
          stdin = true,
          cwd = biome_root,
          require_cwd = true,
        },
        prettier = {
          command = "node_modules/.bin/prettier",
          args = { "--stdin-filepath", "$FILENAME" },
          stdin = true,
          cwd = prettier_root,
          require_cwd = true,
        },
      },
      format_on_save = format_on_save,
    }
  end,
}
