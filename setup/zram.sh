#!/bin/bash

sudo swapoff /dev/zram0

modprobe zram

sudo zramctl /dev/zram0 --algorithm zstd --size "$(grep -Po 'MemTotal:\s*\K\d+' /proc/meminfo)KiB"

sudo mkswap -U clear /dev/zram0

sudo swapon --discard --priority 100 /dev/zram0
