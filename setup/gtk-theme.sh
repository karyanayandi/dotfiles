#!/bin/bash
# Matugen supplies colors.css; gtk.css must import it instead of an old theme.
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
for version in 3 4; do
  target="$config_home/gtk-$version.0/gtk.css"
  source="$repo/config/gtk-$version.0/gtk.css"
  mkdir -p "$(dirname -- "$target")"
  if [ "$(readlink -f -- "$target")" != "$source" ]; then
    ln -s --backup=numbered -T "$source" "$target"
  fi
done

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
