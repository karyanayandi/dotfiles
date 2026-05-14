sudo pacman -S hyprpolkitagent

systemctl --user enable --now hyprpolkitagent.service
systemctl --user start --now hyprpolkitagent.service
