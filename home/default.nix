{
  home.username = "karyana";
  home.homeDirectory = "/home/karyana";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  imports = [
    ./fonts
    ./git
    ./gtk
    ./direnv
    ./lock
    ./neovim
    ./packages
    ./hyprland
    ./dunst
    ./waybar
    ./dev
    ./scripts
    ./shell
    ./foot
    ./tmux
    ./wofi
  ];
}
