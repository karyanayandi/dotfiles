#!/bin/bash
set -e  # Exit on any error

# Create themes directory if it doesn't exist
mkdir -p ~/.local/share/themes

# Download and install theme
if ! wget https://github.com/lonr/adwaita-one-dark/releases/download/v0.47.0/Adwaita-One-Dark.tar.xz; then
    echo "Failed to download theme"
    exit 1
fi

if ! tar -xf Adwaita-One-Dark.tar.xz; then
    echo "Failed to extract theme"
    exit 1
fi

rm -rf ~/.local/share/themes/Adwaita-One-Dark && mv Adwaita-One-Dark ~/.local/share/themes/

# Cleanup
rm Adwaita-One-Dark.tar.xz

mkdir -p ~/.config/gtk-4.0
mkdir -p ~/.config/gtk-3.0

ln -s ~/.local/share/themes/Adwaita-One-Dark/colors/gtk-dark.css ~/.config/gtk-4.0/gtk.css
ln -s ~/.local/share/themes/Adwaita-One-Dark/colors/gtk-dark.css ~/.config/gtk-3.0/gtk.css

mkdir -p ~/.themes/adw-gtk3-dark
ln -s ~/.local/share/themes/Adwaita-One-Dark/gtk-2.0 ~/.themes/adw-gtk3-dark/gtk-2.0
