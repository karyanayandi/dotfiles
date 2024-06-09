{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    android-tools
    bat
    bottom
    bun
    chafa
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
    gnome.nautilus
    go
    google-chrome
    inxi
    luajitPackages.lua-lsp
    mpv
    pfetch
    openssl
    pavucontrol
    postman
    prettierd
    ripgrep
    stdenv.cc.cc.lib
    termius
    tlrc
    tmuxifier
    unzip
    unrar
    viewnior
    wf-recorder
    xclip
    yazi
    zed-editor
  ];
}
