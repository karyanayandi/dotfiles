{pkgs, ...}: let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
in {
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        # command = "Hyprland";
        # user = "karyana";
        command = "${tuigreet} --time --remember --cmd Hyprland";
        user = "greeter";
      };
      default_session = initial_session;
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
