#!/bin/bash

mkdir -p ~/Videos/Records/
time=$(date +"%y.%m.%d_%H:%M:%S")

dunstify -h string:x-dunst-stack-tag:default 'Screen Recording Started'

wf-recorder \
--file ~/Videos/Records/Action_"$time".mp4 \
--codec libx264
