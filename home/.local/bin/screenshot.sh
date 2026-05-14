#!/bin/bash

mkdir -p ~/Pictures/Screenshots ~/.config/swappy

cat > ~/.config/swappy/config << 'SWAPPYCONF'
[Default]
save_dir=$HOME/Pictures/Screenshots
save_filename_format=screenshot-%Y%m%d-%H%M%S.png
early_exit=true
auto_save=true
SWAPPYCONF

TMP=$(mktemp /tmp/screenshot-XXXXXX.png)
grim -g "$(slurp -d)" "$TMP"

CLIP_OLD=$(mktemp /tmp/clip-old-XXXXXX.png)
OLD_HASH=""
if timeout 3 wl-paste -t image/png 2>/dev/null > "$CLIP_OLD" && [ -s "$CLIP_OLD" ]; then
    OLD_HASH=$(sha256sum "$CLIP_OLD" | cut -d' ' -f1)
fi

swappy -f "$TMP"

NEW_HASH=""
CLIP_NEW=$(mktemp /tmp/clip-new-XXXXXX.png)
if timeout 3 wl-paste -t image/png 2>/dev/null > "$CLIP_NEW" && [ -s "$CLIP_NEW" ]; then
    NEW_HASH=$(sha256sum "$CLIP_NEW" | cut -d' ' -f1)
fi

if [ -n "$NEW_HASH" ] && [ "$OLD_HASH" != "$NEW_HASH" ]; then
    notify-send "Screenshot copied" "Copied to clipboard"
fi

rm -f "$TMP" "$CLIP_OLD" "$CLIP_NEW"
