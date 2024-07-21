{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
  systemd.services.fix-generic-usb-bluetooth-dongle = {
    description = "Fixes for generic USB bluetooth dongle.";
    wantedBy = ["post-resume.target"];
    after = ["post-resume.target"];
    script = builtins.readFile ./reset-bluetooth-dongle.sh;
    scriptArgs = "1131:1004";
    serviceConfig.Type = "oneshot";
  };
}
