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

    # style = ''
    #   * {
    #     border: none;
    #     font-family: "Geist Mono NF";
    #     font-size: 15px;
    #     min-height: 30px;
    #   }
    #
    #   window#waybar {
    #     border-radius: 6px;
    #     background: #181825;
    #   }
    #
    #   #workspaces {
    #     background-color: #181825;
    #     color: #eceff4;
    #     margin-left: 15px;
    #     margin-right: 15px;
    #     padding-left: 10px;
    #     padding-right: 10px;
    #   }
    #
    #   #workspaces button {
    #     background: #181825;
    #     color: #eceff4;
    #     padding-left: 10px;
    #     padding-right: 10px;
    #   }
    #
    #   #workspaces button.active {
    #     color: #181825;
    #     background: #eceff4;
    #     border-radius: 0px;
    #   }
    #
    #   #disk,
    #   #network,
    #   #clock,
    #   #pulseaudio,
    #   #memory,
    #   #window {
    #     background: #181825;
    #     color: #eceff4;
    #     padding-left: 10px;
    #     padding-right: 10px;
    #   }
    #
    #   #clock {
    #     margin-right: 20px;
    #   }
    # '';
  };
}
