{pkgs, ...}: {
  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["FiraCode" "Jetbrains Mono" "DroidSansMono"];})
  ];
}
