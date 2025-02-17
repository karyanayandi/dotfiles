#!/bin/bash

sh ./yay.sh
sh ./install.sh
sh ./setup/git.sh
sh ./setup/24-bit-color.sh
sh ./setup/bun.sh
sh ./setup/docker.sh
sh ./setup/corepack.sh
sh ./setup/npm.sh
sh ./tmux.sh

cd ~/.config/dotfiles/shared/ && stow .
cd ~/.config/dotfiles/arch/home && stow .
cd ~/.config/dotfiles/arch/config && stow .
cd ~/.config/dotfiles/arch/local && stow .

xdg-user-dirs-update
