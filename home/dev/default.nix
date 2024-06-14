{
  config,
  pkgs,
  ...
}: let
  nodeJsConfig = ''
    export PATH=${pkgs.nodejs}/bin:$PATH
    npm config set prefix "${config.home.homeDirectory}/.cache/npm/global"
    mkdir -p "${config.home.homeDirectory}/.cache/npm/global"
    npm install -g ls_emmet
  '';
in {
  home.activation.configureNode = ''
    ${nodeJsConfig}
  '';

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.cache/npm/global";
  };

  home.packages = with pkgs; [
    bun
    cargo
    clippy
    corepack
    gcc
    go
    nodejs
    rustc
    # Language Servers & Linters
    alejandra
    eslint_d
    gofumpt
    goimports-reviser
    golangci-lint
    golangci-lint-langserver
    golines
    gopls
    jq
    luajitPackages.lua-lsp
    luajitPackages.luacheck
    nil
    prettierd
    pyright
    shellcheck
    stylua
    rust-analyzer
    # JetBrains IDEs, install just for trying only
    jetbrains.datagrip
    jetbrains.goland
    jetbrains.phpstorm
    jetbrains.rust-rover
    jetbrains.webstorm
  ];
}
