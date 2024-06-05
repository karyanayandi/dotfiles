#!/bin/bash

pkill -f wf-recorder

dunstify -h string:x-dunst-stack-tag:default 'Screen Recording Stopped'
