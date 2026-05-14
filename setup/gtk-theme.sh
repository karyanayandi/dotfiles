#!/bin/bash

paru -S \
  gnome-theme-extra \
  gtk-engine-murrine \
  sassc

mkdir -p ~/tmp
cd ~/tmp

git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme

cd Gruvbox-GTK-Theme/themes
sh ./install.sh -c dark -t grey -l

rm -rf ~/tmp
