{pkgs, ...}: {
  services.xserver = {
    enable = true;
    videoDrivers = ["intel"];
    xkb = {
      layout = "us";
      variant = "";
    };
    excludePackages = [pkgs.xterm];
  };
}
