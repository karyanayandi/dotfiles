#!/bin/bash

sh ./setup/paru.sh
sh ./install.sh
sh ./setup/polkitagent.sh

sh ./setup/24-bit-color.sh
sh ./setup/chaotic-aur.sh
sh ./setup/corepack.sh
sh ./setup/docker.sh
sh ./setup/git.sh
sh ./setup/go.sh
sh ./setup/gtk-theme.sh
sh ./setup/js-packages.sh
sh ./setup/rust.sh
sh ./setup/swayosd.sh
sh ./setup/tmux.sh
sh ./setup/viteplus.sh
sh ./setup/zram.sh

cd ~/.config/dotfiles/home && stow .
cd ~/.config/dotfiles/config && stow .

chsh -s /usr/bin/fish
xdg-user-dirs-update
mkdr -p ~/Pictures/Screenshots/mpv
