{pkgs, ...}: {
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jet-brains-mono
    nerd-fonts.droid-sans-mono
  ];
}
