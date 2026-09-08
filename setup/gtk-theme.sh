#!/bin/bash
# Matugen supplies gtk.css; use a GTK theme that accepts these color overrides.
set -e

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
