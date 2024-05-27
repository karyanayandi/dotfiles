{pkgs, ...}: {
  home.packages = with pkgs; [swaybg wlsunset wl-clipboard sway slurp grim waybar];
  home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
}
