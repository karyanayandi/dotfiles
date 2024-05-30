{pkgs, ...}: {
  home.packages = with pkgs; [dunst];
  services.dunst = {
    enable = true;
    settings = {
      global = {
        origin = "top-right";
        geometry = "320x120-28-28";
        separator_height = 0;
        padding = 32;
        horizontal_padding = 12;
        text_icon_padding = 12;
        frame_width = 4;
        separator_color = "frame";
        idle_threshold = 120;
        show_age-threshole = 60;
        font = "Fira Code Nerd Font 12";
        line_height = 0;
        format = ''
          <b>%s</b>
          %b'';
        alignment = "left";
        icon_position = "off";
        startup_notification = "false";
        corner_radius = 12;
        frame_color = "#83a598";
        background = "#1d2021";
        foreground = "#ebdbb2";
        timeout = 2;
      };
    };
  };
}