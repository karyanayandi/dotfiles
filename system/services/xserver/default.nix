{pkgs, ...}: {
  services.xserver = {
    enable = true;
    videoDrivers = ["intel"];
    xkb = {
      layout = "us";
      variant = "";
    };
    xkbOptions = ["altwin:swap_alt_win"];
    excludePackages = [pkgs.xterm];
  };
}
