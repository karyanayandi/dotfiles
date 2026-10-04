#!/bin/bash

sh ./setup/paru.sh
sh ./install.sh
sh ./setup/polkitagent.sh

sh ./setup/24-bit-color.sh
sh ./setup/chaotic-aur.sh
sh ./setup/docker.sh
sh ./setup/git.sh
sh ./setup/go.sh
sh ./setup/gtk-theme.sh
sh ./setup/js-packages.sh
sh ./setup/rust.sh
sh ./setup/tmux.sh
sh ./setup/viteplus.sh
sh ./setup/zram.sh

cd ~/.config/dotfiles/home && stow --adopt .
cd ~/.config/dotfiles/config && stow --adopt .

# Seed generated includes before apps start; future wallpaper changes regenerate them.
if [ -f "${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper" ]; then
  "$HOME/.local/bin/wallpaper-theme"
else
  "$HOME/.local/bin/wallpaper-theme" "$HOME/.config/dotfiles/wallpapers/arch-linux.png"
fi

chsh -s /usr/bin/fish
xdg-user-dirs-update
mkdir -p ~/Pictures/Screenshots/mpv
