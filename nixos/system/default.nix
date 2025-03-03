{
  pkgs,
  inputs,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  environment = {
    variables = {EDITOR = "vim";};
    systemPackages = with pkgs; [
      bat
      comma
      curl
      eza
      git
      lsof
      vim
      wget
      inputs.alejandra.defaultPackage.${pkgs.system}
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      inputs.hyprland-qtutils.packages.${pkgs.system}.default
      inputs.zen-browser.packages.${pkgs.system}.default
    ];
  };

  services.gnome.gnome-keyring.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  fileSystems = {
    "/home/karyana/HDD" = {
      device = "/dev/disk/by-uuid/43031C00268C75EB";
      fsType = "ntfs-3g";
      options = ["rw" "uid=1000"];
    };
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["karyana" "root"];
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  system.stateVersion = "25.05";

  imports = [
    ./boot
    ./fonts
    ./hardware
    ./hyprland
    ./init
    ./ld
    ./locale
    ./network
    ./security
    ./services
    ./shell
    ./sound
    ./stylix
    ./timezone
    ./users
    ./virtualization
  ];
}
