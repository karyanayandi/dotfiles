#!/bin/bash

sudo pacman -S podman
sudo systemctl start podman.service
sudo systemctl enable podman.service
sudo usermod -aG docker $USER
newgrp docker 
