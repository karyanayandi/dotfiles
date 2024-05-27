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
    ./neovim
    ./packages
    ./kitty
    ./hyprland
    ./dunst
    ./waybar
    ./qt
    ./foot
    ./wofi
  ];
}
