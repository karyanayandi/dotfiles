{pkgs, ...}: {
  home.packages = with pkgs; [
    android-tools
    bat
    bottom
    chafa
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
    gh-copilot
    gimp
    google-chrome
    grim
    insomnia
    inxi
    logseq
    mpv
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
    swaybg
    termius
    unrar
    unzip
    viewnior
    wf-recorder
    wl-clipboard
    wlsunset
    xclip
    yazi
    zed-editor
  ];
}
