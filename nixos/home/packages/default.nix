{pkgs, ...}: {
  home.packages = with pkgs; [
    android-tools
    bat
    bottom
    chafa
    code-cursor
    cowsay
    distrobox
    eza
    fd
    ffmpeg
    ffmpegthumbnailer
    file-roller
    fishPlugins.autopair
    fishPlugins.fzf-fish
    fishPlugins.z
    fzf
    gimp
    google-chrome
    grim
    insomnia
    inxi
    killport
    lynx
    nemo-with-extensions
    obsidian
    openssl
    pavucontrol
    pfetch
    poppler_utils
    realvnc-vnc-viewer
    ripgrep
    slurp
    stdenv.cc.cc.lib
    sway
    termius
    unrar
    unzip
    viewnior
    vscode
    wf-recorder
    wl-clipboard
    xclip
  ];
}
