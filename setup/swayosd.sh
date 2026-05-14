#!/bin/bash

paru -S --needed swayosd-git

sudo systemctl enable --now swayosd-libinput-backend.service
