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
copyq \
cowsay \
cursor-bin \
dbus \
deno \
distrobox \
dive \
dunst \
eglinfo \
eza \
fd \
ffmpeg \
ffmpegthumbnailer \
fnm \
fzf \
gcc \
gimp \
github-cli \
glxinfo \
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
killport \
krita \
lazydocker \
lazygit \
lib32-vulkan-intel \
libxcrypt-compat \
local-by-flywheel-bin \
lshw \
lua \
luacheck \
luarocks \
lynx \
mkcert \
mpv \
nemo  \
nemo-fileroller \
neovim \
neovim \
networkmanager \
nilfs-utils \
noto-fonts \
noto-fonts-cjk \
noto-fonts-emoji \
noto-fonts-extra \
ntfs-3g \
ntfsprogs \
obsidian \
openssh \
p7zip \
papipurs-icon-theme \
pavucontrol \
pfetch \
podman-compose \
podman-tui \
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
swayfx \
swayidle \
swaylock-effects-git \
swayosd-git \
tela-icon-theme \
termius \
tmux \
trash-cli \
ttf-jetbrains-mono-nerd \
udevil \
udisks2 \
unrar \
unzip \
visual-studio-code-bin \
vivid \
waybar \
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
zip

sudo systemctl enable --now swayosd-libinput-backend.service
