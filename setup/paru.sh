#!/bin/bash

sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git
cd paru || exit
makepkg -si
