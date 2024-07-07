{
  home.username = "karyana";
  home.homeDirectory = "/home/karyana";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  imports = [
    ./fonts
    ./git
    ./gtk
    ./index
    ./direnv
    ./lock
    ./neovim
    ./packages
    ./hyprland
    ./dunst
    ./waybar
    ./dev
    ./shell
    ./scripts
    ./starship
    ./foot
    ./tmux
    ./wofi
  ];
}
