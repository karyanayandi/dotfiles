#!/bin/bash

sh ./yay.sh
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
sh ./setup/elephant.sh

cd ~/.config/dotfiles/shared/config && stow .
cd ~/.config/dotfiles/shared/local && stow .
cd ~/.config/dotfiles/arch/home && stow .
cd ~/.config/dotfiles/arch/config && stow .

vivid generate ~/.config/vivid/aurora.yaml
chsh -s /usr/bin/fish
xdg-user-dirs-update
mkdr -p ~/Pictures/Screenshots/mpv

fish_config theme save "Aurora"
