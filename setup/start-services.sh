#!/usr/bin/env bash

pgrep -x ollama >/dev/null || nohup ollama serve >/tmp/ollama.log 2>&1 &
pgrep -x 9router >/dev/null || nohup 9router >/tmp/9router.log 2>&1 &

exit 0
