#!/bin/sh
# Nuclear restart for xdg-desktop-portal-hyprland.
# Sourced from https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
# Needed because v1.4.0 can spin CPU after config reload / session resume.

sleep 1
killall -e xdg-desktop-portal-hyprland
killall xdg-desktop-portal
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
