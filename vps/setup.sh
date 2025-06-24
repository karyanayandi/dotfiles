#!/bin/bash

sudo apt update && sudo apt upgrade -y

sudo apt install \
  eza \
  fish \
  git \
  neofetch \
  vim

curl -sS https://starship.rs/install.sh | sh

cp -r . ~/

chsh -s /usr/bin/fish
