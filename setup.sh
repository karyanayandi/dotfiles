#!/bin/bash

apt install \
  eza \
  fish \
  git \
  neofetch \
  vim \

curl -sS https://starship.rs/install.sh | sh \

cp -r . ~/ \

chsh -s /usr/bin/fish
