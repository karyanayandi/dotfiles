{
  home.username = "karyana";
  home.homeDirectory = "/home/karyana";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  programs.nix-index.enable = true;
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
    ./shell
    ./scripts
    ./starship
    ./foot
    ./tmux
    ./wofi
  ];
}
