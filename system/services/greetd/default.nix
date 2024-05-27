{
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "Hyprland";
        user = "karyana";
      };
      default_session = initial_session;
    };
  };
}
