#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

polybar --reload desktop &