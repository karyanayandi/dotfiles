{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      maripush = {
        hostname = "62.146.236.230";
        user = "root";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
      };
      yopem = {
        hostname = "62.146.236.245";
        user = "root";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
      };
      haloweb = {
        hostname = "154.26.136.27";
        user = "root";
        port = 22;
      };
    };
  };
}
