---
name: subagents
description: invoke this skill when the user asks you to use subagents
---

# Subagents

Each subagent is headless, has its own context window, cannot see the parent
conversation, cannot ask the user, and cannot spawn subagents or workflows. Give
every child a self-contained prompt with paths, constraints, and the expected
report.

## Defaults

Run `/subagent-defaults` in TUI to choose default harness, model, and reasoning
effort. Pi model picker has search input: type model or provider terms, then use
arrows + Enter. Model picker then opens reasoning-effort selector. Defaults
persist in `~/.pi/agent/subagent-defaults.json`.

When `subagent_spawn` omits `harness`, `model`, or `reasoning_effort`, extension
uses configured default. Explicit tool values override it. Fresh config defaults
to Pi; Pi inherits parent model and reasoning effort when no Pi defaults are
set.

## Pi Harness

**Harness:** `pi` **Prompt nicknames:** "pi", "pi agent", "pi subagent". Use
configured default unless task requires another harness. Pi inherits parent
thinking level when `reasoning_effort` is omitted.

Do not use models from the Anthropic provider even if one appears in the model
list.

Pi can use any model shown by `pi --list-models`. Prefer `provider/model-id`; a
bare model id only works when unambiguous. Common picks in this environment:

| Model                            | Recommended effort |
| -------------------------------- | ------------------ |
| inherited parent model (default) | inherited          |
| `openai-codex/gpt-5.6-sol`       | `medium`           |
| `openai-codex/gpt-5.6-terra`     | `medium`           |

**Thinking budgets:** `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`.
These map directly to pi thinking levels.

## Codex Harness

**Harness:** `codex` **Prompt nicknames:** "codex", "Codex CLI", "codex agent",
"codex subagent" **Best default:** `gpt-5.6-sol` with `high` effort for coding
work. Do not use anything other than sol unless the user specifically asks for
it.

| Model           | Recommended effort |
| --------------- | ------------------ |
| `gpt-5.6-sol`   | `medium`           |
| `gpt-5.6-terra` | `medium`           |
| `gpt-5.6-luna`  | `high`             |

**Thinking budgets accepted by the extension:** `off`, `minimal`, `low`,
`medium`, `high`, `xhigh`, `max`. Codex maps these to the nearest effort
supported by the selected model; `off`/`minimal` become `minimal`, while `max`
becomes the highest extension-supported Codex effort.

Requires the Codex CLI to be installed and authenticated.

## Spawn and Manage

Call `subagent_spawn` with complete `prompt`, short `name`, optional `harness`,
`working_dir`, `model`, and `reasoning_effort`. Omit harness/model for
configured defaults. At most four subagents run concurrently.

- `subagent_check({ id })`: peek without blocking.
- `subagent_list()`: list all runs.
- `subagent_wait({ ids })`: block only when results are required to proceed.
- `subagent_cancel({ ids })`: stop runs while preserving partial transcripts.
- `/subagents`: inspect or take over a run interactively.

Results return automatically. After spawning, continue useful parent work
instead of immediately waiting.
