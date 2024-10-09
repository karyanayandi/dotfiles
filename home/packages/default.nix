{pkgs, ...}: {
  home.packages = with pkgs; [
    android-tools
    bat
    bottom
    chafa
    distrobox
    eza
    fd
    file-roller
    firefox
    fishPlugins.autopair
    fishPlugins.fzf-fish
    fishPlugins.z
    fzf
    gh-copilot
    gimp
    google-chrome
    grim
    insomnia
    inxi
    mpv
    pfetch
    nemo-with-extensions
    obsidian
    openssl
    pavucontrol
    realvnc-vnc-viewer
    ripgrep
    slurp
    stdenv.cc.cc.lib
    sway
    swaybg
    termius
    tlrc
    unzip
    unrar
    viewnior
    wf-recorder
    wlsunset
    wl-clipboard
    xclip
    yazi
    zed-editor
  ];
}
