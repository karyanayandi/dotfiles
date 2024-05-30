{
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        # command = "Hyprland";
        command = "$SHELL -l";
        # user = "karyana";
      };
      default_session = initial_session;
    };
  };
}
