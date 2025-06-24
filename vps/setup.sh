#!/bin/bash

sudo apt update && sudo apt upgrade -y

sudo apt install \
  eza \
  fail2ban \
  fish \
  git \
  neofetch \
  ufw \
  vim

curl -sS https://starship.rs/install.sh | sh

cp -r . ~/

chsh -s /usr/bin/fish

ufw allow OpenSSH
ufw allow ssh
ufw allow http
ufw allow https
ufw enable

systemctl enable --now fail2ban
