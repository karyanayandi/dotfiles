#!/bin/bash
set -e # Exit on any error

# Install podman
if ! sudo pacman -S --noconfirm podman; then
  echo "Failed to install podman"
  exit 1
fi

# Start and enable podman service
sudo systemctl start podman.service
sudo systemctl enable podman.service

# Add user to docker group
sudo usermod -aG docker "$USER"
newgrp docker
systemctl --user enable --now podman.socket
