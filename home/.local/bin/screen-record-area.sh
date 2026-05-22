#!/bin/bash

mkdir -p ~/Videos/Records/
time=$(date +"%y.%m.%d_%H:%M:%S")

notify-send "screen recording area started"

wf-recorder --audio=alsa_output.pci-0000_00_1f.3.analog-stereo.monitor --file ~/Videos/Records/Action_"$time".mp4 --codec libx264 -C aac -g "$(slurp)"
