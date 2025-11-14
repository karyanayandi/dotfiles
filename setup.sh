#!/bin/bash

sh ./setup/yay.sh
sh ./install.sh
sh ./setup/24-bit-color.sh
sh ./setup/bun.sh
sh ./setup/corepack.sh
sh ./setup/docker.sh
sh ./setup/git.sh
sh ./setup/go.sh
sh ./setuop/gtk-theme.sh
sh ./setup/npm.sh
sh ./setup/rust.sh
sh ./setup/tmux.sh

cd ~/.config/dotfiles/home && stow .
cd ~/.config/dotfiles/config && stow .

sh ./home/.local/bin/theme-switch.sh aurora
chsh -s /usr/bin/fish
xdg-user-dirs-update
mkdr -p ~/Pictures/Screenshots/mpv

fish_config theme save "Aurora"
