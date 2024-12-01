{pkgs, ...}: {
  stylix.targets.neovim = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    enable = true;
    plugin = "mini.base16";
  };
}
