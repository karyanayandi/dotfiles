#!/bin/bash

mkdir -p ~/Videos/Records/
time=$(date +"%y.%m.%d_%H:%M:%S")

notify-send "screen recording area started"

wf-recorder --file ~/Videos/Records/Action_"$time".mp4 --codec libx264 -g "$(slurp)"
