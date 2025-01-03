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
    source = ./nvim;
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

  home.file."./.local/share/nvim/nix/nvim-treesitter/" = {
    recursive = true;
    source = treesitterWithGrammars;
  };
}
