{pkgs, ...}: {
  virtualisation = {
    libvirtd.enable = true;
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };
  environment.systemPackages = with pkgs; [
    dive
    podman-tui
    docker-compose
  ];
}
