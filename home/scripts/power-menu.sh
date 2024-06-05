#!/bin/bash

entries="Logout\nSuspend\nReboot\nShutdown"
placeholder="Select an action"

selected=$(echo -e $entries | wofi --dmenu --cache-file /dev/null --prompt "$placeholder" | awk -F '\t' '{print tolower($2)}')

case $selected in
  logout)
    hyprctl dispatch exit;;
  suspend)
    exec systemctl suspend;;
  reboot)
    exec systemctl reboot;;
  shutdown)
    exec systemctl poweroff -i;;
esac
