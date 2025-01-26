{pkgs, ...}: {
  users.users.karyana = {
    isNormalUser = true;
    description = "Karyana Yandi";
    extraGroups = ["networkmanager" "wheel" "docker"];
    createHome = true;
    shell = pkgs.fish;
  };
}
