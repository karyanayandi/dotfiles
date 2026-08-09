#!/usr/bin/env bash
# Start ollama + opencodex if not already running. Idempotent, safe to rerun.
# Boot auto-start is handled by services (ollama systemd, opencodex linger).
# This script is for manual / post-reinstall use.

pgrep -x ollama >/dev/null || nohup ollama serve >/tmp/ollama.log 2>&1 &
opencodex ensure >/dev/null 2>&1 || opencodex start >/tmp/opencodex.log 2>&1

exit 0