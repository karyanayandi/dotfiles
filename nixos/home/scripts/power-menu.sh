#!/bin/bash

entries="Logout\nSuspend\nReboot\nShutdown"
placeholder="Select an action"

selected=$(echo -e "$entries" | wofi --dmenu --cache-file /dev/null --prompt "$placeholder" | tr '[:upper:]' '[:lower:]')

case $selected in
  logout)
    hyprctl dispatch exit
    ;;
  suspend)
    systemctl suspend
    ;;
  reboot)
    systemctl reboot
    ;;
  shutdown)
    systemctl poweroff -i
    ;;
esac
