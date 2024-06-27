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
    # Formatters and Linters
    alejandra
    eslint_d
    gofumpt
    goimports-reviser
    golangci-lint
    golines
    jq
    luajitPackages.luacheck
    prettierd
    shellcheck
    stylua
    # JetBrains IDEs, install just for trying only
    jetbrains.datagrip
    jetbrains.goland
    jetbrains.phpstorm
    jetbrains.rust-rover
    jetbrains.webstorm
  ];
}
