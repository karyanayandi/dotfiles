#!/bin/bash

yay -S --needed \
adw-gtk-theme \
android-tools \
apple-fonts \
base-devel \
bat \
beekeeper-studio \
bibata-cursor-theme \
bluez \
bluez-utils \
bottom \
chafa \
cmake \
cowsay \
dbus \
delta-plugin-git \
deno \
dunst \
eza \
ffmpeg \
fnm \
fzf \
gcc \
gimp \
github-cli \
gnome-keyring \
go \
google-chrome \
gparted \
grim \
gvfs \
gzip \
imv \
insomnia \
inter-font \
inxi \
iw \
jfsutils \
jq \
krita \
lazygit \
libxcrypt-compat \
lshw \
lua \
luacheck \
luarocks \
mpv \
nemo  \
nemo-fileroller \
neovim \
neovim \
networkmanager \
nilfs-utils \
noto-fonts \
noto-fonts \
noto-fonts-cjk \
noto-fonts-emoji \
noto-fonts-extra \
ntfs-3g \
ntfsprogs \
openssh \
p7zip \
papipurs-icon-theme \
pavucontrol \
pfetch \
podman-compose \
polkit-gnome \
python-pip \
reflector \
reiserfsprogs \
ripgrep \
rofi \
rustup \
sed \
slurp \
sof-firmware \
starship \
stow \
stylua \
swaybg \
swayfx \
swayidle \
swaylock-effects-git \
swayosd-git \
tela-icon-theme \
tmux \
trash-cli \
ttf-jetbrains-mono-nerd \
ttf-ms-win11-auto \
udevil \
udisks2 \
unrar \
unzip \
visual-studio-code-bin \
wf-recorder \
wget \
wireplumber \
wl-clipboard \
xdg-user-dirs \
xfsprogs \
xorg-xhost \
yazi \
youtube-dl \
zathura \
zathura-djvu \
zathura-pdf-mupdf \
zen-browser-bin \
zip \
zoxide

sudo systemctl enable --now swayosd-libinput-backend.service
