---
name: background-terminals
description:
  Run long-lived shell commands in background terminals. Use for dev servers,
  watchers, streaming builds, and commands that must continue while agent works.
---

# Background terminals

Use `bg_start` for long-running commands. Use `bash` for quick commands.

## Start

Call `bg_start` with:

- `command`: shell command to run
- `title`: short recognizable label
- `working_dir`: project directory when different from the current directory

Background commands receive no stdin. Never use them for interactive prompts.

After starting, keep working instead of polling. Terminal sends one completion
message when it exits.

## Inspect and stop

- Use `bg_status` only when current output or status is needed.
- Use `bg_list` to list tracked terminals.
- Use `bg_kill` for unneeded or stuck processes. Termination continues if tool
  wait is aborted.
- Tell user to open `/ps` for live output or interactive termination.

Use distinct titles. Do not start duplicate servers or watchers. Full output
lands in spill files. Tool and completion output show a short tail. Terminals
belong to session and stop on shutdown or reload.
