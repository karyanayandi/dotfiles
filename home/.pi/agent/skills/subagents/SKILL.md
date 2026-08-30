---
name: subagents
description: Use when user asks to use subagents.
---

# Subagents

Each subagent is headless with its own context window. It cannot see parent
conversation, ask user, or spawn subagents or workflows. Give each child a
self-contained prompt with paths, constraints, and expected report.

## Defaults

Run `/subagent-defaults` in TUI to choose default harness, model, and reasoning
effort. Pi model picker has search. Type model or provider terms, then use
arrows and Enter. It then opens reasoning-effort selector. Defaults live in
`~/.pi/agent/subagent-defaults.json`.

When `subagent_spawn` omits `harness`, `model`, or `reasoning_effort`, extension
uses configured defaults. Explicit tool values override them. New config
defaults to Pi. Pi inherits parent model and reasoning effort when Pi defaults
are unset.

## Pi Harness

**Harness.** `pi`. **Prompt nicknames.** "pi", "pi agent", "pi subagent". Use
configured default unless task needs another harness. Pi inherits parent
thinking level when `reasoning_effort` is omitted.

Do not use models from the Anthropic provider even if one appears in the model
list.

Pi can use any model shown by `pi --list-models`. Prefer `provider/model-id`.
Bare model IDs work only when unambiguous. Common picks in this environment:

| Model                            | Recommended effort |
| -------------------------------- | ------------------ |
| inherited parent model (default) | inherited          |
| `openai-codex/gpt-5.6-sol`       | `medium`           |
| `openai-codex/gpt-5.6-terra`     | `medium`           |

**Thinking budgets:** `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`.
These map directly to pi thinking levels.

## Codex Harness

**Harness.** `codex`. **Prompt nicknames.** "codex", "Codex CLI", "codex agent",
"codex subagent". **Default.** `gpt-5.6-sol` with `high` effort for coding work.
Use another model only when user asks.

| Model           | Recommended effort |
| --------------- | ------------------ |
| `gpt-5.6-sol`   | `medium`           |
| `gpt-5.6-terra` | `medium`           |
| `gpt-5.6-luna`  | `high`             |

**Extension thinking budgets.** `off`, `minimal`, `low`, `medium`, `high`,
`xhigh`, `max`. Codex maps them to nearest supported selected-model effort.
`off` and `minimal` become `minimal`. `max` becomes highest Codex effort
extension supports.

Requires the Codex CLI to be installed and authenticated.

## Spawn and Manage

Call `subagent_spawn` with complete `prompt`, short `name`, and optional
`harness`, `working_dir`, `model`, and `reasoning_effort`. Omit harness and
model for configured defaults. At most four subagents run concurrently.

- `subagent_check({ id })`: peek without blocking.
- `subagent_list()`: list all runs.
- `subagent_wait({ ids })`: block only when results are required to proceed.
- `subagent_cancel({ ids })`: stop runs while preserving partial transcripts.
- `/subagents`: inspect or take over a run interactively.

Results return automatically. After spawning, keep working instead of waiting.
