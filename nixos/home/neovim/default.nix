{pkgs, ...}: let
  treesitterWithGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    p.astro
    p.bash
    p.comment
    p.css
    p.dockerfile
    p.fish
    p.gitattributes
    p.gitignore
    p.go
    p.gomod
    p.gowork
    p.hcl
    p.htmldjango
    p.javascript
    p.jq
    p.json
    p.json5
    p.lua
    p.make
    p.markdown
    p.nix
    p.php
    p.prisma
    p.prisma
    p.python
    p.rust
    p.svelte
    p.toml
    p.tsx
    p.typescript
    p.vue
    p.yaml
  ]);

  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = treesitterWithGrammars.dependencies;
  };
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    package = pkgs.neovim-unwrapped;
    coc.enable = false;

    plugins = [
      treesitterWithGrammars
    ];
  };

  home.file."./.config/nvim/" = {
    source = ../../../shared/nvim;
    recursive = true;
  };

  home.file."./.config/nvim/init.lua".text = ''
    require "config.autocommands"
    require "config.options"
    require "config.keymaps"
    require "config.lazy"
    vim.cmd "colorscheme aurora"
    vim.opt.runtimepath:append("${treesitter-parsers}")
  '';

  home.file."./.config/nvim/lua/config/lazy.lua".text = ''
    -- luacheck: globals vim

    local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
      local lazyrepo = "https://github.com/folke/lazy.nvim.git"
      local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
      if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
          { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
          { out, "WarningMsg" },
          { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
      end
    end
    vim.opt.rtp:prepend(lazypath)

    vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      require("lazy").setup {
        dev = {
          path = "~/.local/share/nvim/nix",
          fallback = false,
        },
        spec = {
           import = "plugin",
        },
        install = { colorscheme = { "aurora" } },
        checker = { enabled = true, notify = false },
      }
  '';

  home.file."./.local/share/nvim/nix/nvim-treesitter/" = {
    recursive = true;
    source = treesitterWithGrammars;
  };
}
