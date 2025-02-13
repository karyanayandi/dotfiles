#!/bin/bash

xdg-user-dirs-update
export EDITOR=nvim
export TERM=xterm-256color
export SHELL=/usr/bin/zsh
export LANG=en_US.utf8
export LC_COLLATE=C
export LC_ADDRESS=en_US.utf8
export LC_CTYPE=en_US.utf8
export LC_IDENTIFICATION=en_US.utf8
export LC_MEASUREMENT=en_US.utf8
export LC_MESSAGES=en_US.utf8
export LC_MONETARY=en_US.utf8
export LC_NAME=en_US.utf8
export LC_NUMERIC=en_US.utf8
export LC_PAPER=en_US.utf8
export LC_TELEPHONE=en_US.utf8
export LC_TIME=en_US.utf8

cd ~/.config/dotfiles/shared/ && stow .
cd ~/.config/dotfiles/arch/home && stow .
cd ~/.config/dotfiles/arch/config && stow .
cd ~/.config/dotfiles/arch/local && stow .
