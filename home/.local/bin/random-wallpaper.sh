#!/usr/bin/env sh

# Wallpaper directory
WP_FOLDER="${HOME}/.config/dotfiles/wallpapers"

# Time in seconds to change wallpaper
WAIT_TIME=10800

# Start hyprpaper if not running
if ! pgrep -x hyprpaper > /dev/null 2>&1; then
  hyprpaper &
fi

# Wait for hyprpaper socket to be ready
HYPRPAPER_SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.hyprpaper.sock"
while [ ! -S "$HYPRPAPER_SOCK" ]; do
  sleep 0.3
done

while true; do
  FILE=$(find "$WP_FOLDER" -type f \( -name '*.png' -o -name '*.jpg' \) | shuf -n1)
  [ -z "$FILE" ] && continue

  MONITORS=$(hyprctl monitors | sed -n 's/^[[:space:]]*Monitor \([^[:space:]]*\).*/\1/p')
  echo "$MONITORS" | while read -r monitor; do
    [ -n "$monitor" ] && hyprctl hyprpaper wallpaper "$monitor,$FILE" > /dev/null 2>&1
  done

  sleep "$WAIT_TIME"
done
