#!/usr/bin/env sh

# Wallpaper directory
WP_FOLDER=~/.config/dotfiles/wallpapers

# Time in seconds to change wallpaper
WAIT_TIME=599

while true; do
  PID=$(pidof swaybg)
  FILE=$(find "$WP_FOLDER" -type f -name '*.png' -o -name '*.jpg' | shuf -n1)
  swaybg -i "$FILE" -m fill &
  sleep 1
  kill "$PID"
  sleep "$WAIT_TIME"
done
