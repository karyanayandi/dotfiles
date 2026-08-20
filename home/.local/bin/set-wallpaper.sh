#!/usr/bin/env sh

WP_FOLDER="${HOME}/.config/dotfiles/wallpapers"
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

set_wallpaper() {
  FILE="$1"
  [ -z "$FILE" ] && return 1

  MONITORS=$(hyprctl monitors | sed -n 's/^[[:space:]]*Monitor \([^[:space:]]*\).*/\1/p')
  echo "$MONITORS" | while read -r monitor; do
    hyprctl hyprpaper wallpaper "$monitor,$FILE" > /dev/null 2>&1
  done
}

# If a filename is given, use that specific file (not random) and exit.
if [ -n "$1" ]; then
  if [ -f "$1" ]; then
    FILE="$1"
  elif [ -f "${WP_FOLDER}/$1" ]; then
    FILE="${WP_FOLDER}/$1"
  else
    echo "Wallpaper not found: $1" >&2
    exit 1
  fi
  set_wallpaper "$FILE"
  exit 0
fi

# Otherwise, pick a random wallpaper every WAIT_TIME.
while true; do
  FILE=$(find "$WP_FOLDER" -type f \( -name '*.png' -o -name '*.jpg' \) | shuf -n1)
  set_wallpaper "$FILE"

  sleep "$WAIT_TIME"
done
