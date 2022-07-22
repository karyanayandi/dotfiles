#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

export PATH="${PATH}:/sbin"
export PATH="${PATH}:$HOME/.local/bin"
export PATH="${PATH}:$HOME/.config/i3"
export RANGER_LOAD_DEFAULT_RC=FALSE
export EDITOR=nvim
export TERM=xterm-256color
export SHELL=/usr/bin/fish
export LANG=en_US.utf8
export LC_COLLATE=C
export LC_ADDRESS=en_US.utf8
export LC_CTYPE=en_US.utf8
export LC_IDENTIFICATION=en_US.utf8
export LC_MEASUREMENT=en_US.utf8
export LC_MESSAGES=en_US.utf8
export LC_MONETARY=en_US.utf8
export LC_NAME=en_US.utf8
export LC_NUMERIC=en_US.utf8
export LC_PAPER=en_US.utf8
export LC_TELEPHONE=en_US.utf8
export LC_TIME=en_US.utf8

eval $(/usr/bin/gnome-keyring-daemon --start)
export SSH_AUTH_SOCK
mkdir -p "$HOME"/.local/share/keyrings

xsetroot -cursor_name left_ptr
xset b off
xset r rate 250 25
xrdb -merge ~/.Xresources
xrandr --output HDMI-0 --primary --mode 1920x1080 --rate 74.97 --rotate normal
setxkbmap -option caps:swapescape

/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
devmon &
xsettingsd &
dunst &
betterlockscreen -u ~/.wallpaper.png
betterlockscreen -w dim

# start i3 and keep it running
if [ -f /usr/bin/i3 ]; then
    exec i3
fi
