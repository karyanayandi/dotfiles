{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    android-tools
    bat
    bun
    cinnamon.nemo
    corepack
    eslint_d
    eza
    fd
    firefox-devedition-bin-unwrapped
    fishPlugins.autopair
    fishPlugins.forgit
    fishPlugins.fzf-fish
    fishPlugins.z
    fzf
    gcc
    gh-copilot
    gimp
    google-chrome
    htop
    inxi
    luajitPackages.lua-lsp
    mpv
    nodejs
    pfetch
    openssl
    pavucontrol
    postman
    prettierd
    ripgrep
    stdenv.cc.cc.lib
    stylelint
    termius
    trash-cli
    unzip
    unrar
    viewnior
    vscode
    xclip
    yazi
  ];
}