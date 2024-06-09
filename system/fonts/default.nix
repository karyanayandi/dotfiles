{pkgs, ...}: {
  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono" "DroidSansMono"];})
  ];
}
