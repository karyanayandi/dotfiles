{
  home.username = "karyana";
  home.homeDirectory = "/home/karyana";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
  imports = [
    ./dev
    ./direnv
    ./dunst
    ./foot
    ./git
    ./gtk
    ./hyprland
    ./lock
    ./mpv
    ./neovim
    ./packages
    ./qt
    ./scripts
    ./shell
    ./starship
    ./tmux
    ./waybar
    ./wofi
  ];
}
