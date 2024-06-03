{
  home.username = "karyana";
  home.homeDirectory = "/home/karyana";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  imports = [
    ./alacritty
    ./fonts
    ./git
    ./gtk
    ./direnv
    ./neovim
    ./packages
    ./hyprland
    ./dunst
    ./waybar
    ./node
    ./qt
    ./foot
    ./tmux
    ./wofi
  ];
}
