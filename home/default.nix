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
    ./hyprland
    ./dunst
    ./waybar
    ./node
    ./scripts
    ./starship
    ./foot
    ./tmux
    ./wofi
  ];
}
