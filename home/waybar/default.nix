{pkgs, ...}: {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings = {
      mainBar = {
        layer = "top";
        margin = "12 12 0 12";
        "modules-left" = ["hyprland/workspaces"];
        "modules-right" = ["network" "disk" "memory" "pulseaudio" "clock"];

        "hyprland/workspaces" = {
          format = "{name}";
          "disable-scroll" = true;
        };

        clock = {
          format = "󱑎 {:%H:%M}";
          tooltip = true;
          "tooltip-format" = "{:%A, %B %d, %Y}";
        };

        disk = {
          interval = 30;
          format = " {used}";
          path = "/";
        };

        network = {
          interface = "enp1s0";
          format = "󰓅 {bandwidthUpBits}";
          on-click = "foot -e ping 8.8.8.8";
          interval = 5;
        };

        tray = {
          "icon-size" = 20;
          spacing = 5;
        };

        pulseaudio = {
          "format" = "{icon} {volume}%";
          "format-muted" = "󰸈 {volume}%";
          "tooltip" = false;
          "format-icons" = {
            "headphone" = "󰋋";
            "default" = "󰕾";
          };
          "scroll-step" = 1;
          "on-click" = "amixer set Master toggle";
        };

        memory = {
          format = "󰍛 {used}GiB";
          on-click = "foot -e btm";
          interval = 5;
        };
      };
    };

    style = ''
      * {
        border: none;
        font-family: "ZedMono NF";
        font-size: 15px;
        min-height: 30px;
      }

      window#waybar {
        border-radius: 6px;
      }

      #workspaces {
        margin-left: 15px;
        margin-right: 15px;
        padding-left: 10px;
        padding-right: 10px;
      }

      #workspaces button {
        padding-left: 10px;
        padding-right: 10px;
      }

      #workspaces button.active {
        border-radius: 0px;
      }

      #disk,
      #network,
      #clock,
      #pulseaudio,
      #memory,
      #window {
        padding-left: 10px;
        padding-right: 10px;
      }

      #clock {
        margin-right: 20px;
      }
    '';
  };
}
