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
      nisomnia = {
        hostname = "62.146.236.245";
        user = "root";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
