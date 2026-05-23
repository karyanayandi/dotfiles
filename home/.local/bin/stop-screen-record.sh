#!/bin/bash

if pgrep -f wf-recorder > /dev/null; then
    pkill -f wf-recorder
    notify-send 'Screen Recording Stopped'
fi
