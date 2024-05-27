{pkgs, ...}: {
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    bun
    nodejs
    corepack
    stdenv.cc.cc.lib
  ];
}
