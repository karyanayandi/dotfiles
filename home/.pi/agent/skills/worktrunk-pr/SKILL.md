---
name: worktrunk-pr
description:
  Use Worktrunk to isolate coding work in a branch and worktree, then commit,
  push, and open a GitHub pull request when the work is finished. Use when asked
  to work in a worktree, use Worktrunk, or complete a task and create a PR.
---

# Worktrunk to pull request

Use the `worktrunk` tool for Worktrunk operations and `gh` for GitHub. Follow
repository instructions. Finish with a PR URL, not a local merge.

## Start

1. Inspect `git status --short`, `git remote -v`, and Worktrunk's `list`.
   Identify the repository, intended base branch, and any existing task branch
   or PR. Preserve unrelated changes. Never reset, stash, or move them without
   permission.
2. Check `gh auth status`. If Worktrunk, GitHub CLI, or authentication is
   unavailable, report the blocker. Do not install tools or change credentials
   without permission.
3. Reuse a worktree only when it belongs to this task. Otherwise create a
   descriptive branch from the agreed base with the `worktrunk` tool:

   ```json
   {
     "command": "switch",
     "args": ["--create", "feat/task-name", "--base", "main"]
   }
   ```

   Replace the example branch and base with the actual names. Confirm the base
   is current with its remote before branching. Fetch when needed, without
   resetting local work. The tool follows directory changes. Verify `pwd` and
   `git branch --show-current` before editing. If the branch already exists,
   inspect it rather than clobbering it.

4. Review configured hooks before approving them. Never bypass approval prompts
   with blanket `--yes`. Copy ignored files only when required for the task, and
   never commit secrets.

## Implement and verify

- Read the affected code and callers, then make the smallest complete change in
  the task worktree.
- Run repository format, check, lint, and relevant tests. Scope formatting to
  changed files when supported. If a command is missing, say so and suggest
  adding it. Report failures accurately and fix task-related failures before
  declaring completion.
- Inspect `git diff --check`, the final diff, and status. Include only task
  changes. Do not publish secrets, unrelated edits, or generated artifacts that
  the repository excludes.

## Commit and open the PR

1. Stage explicit task paths with `git add -- <paths>`. Review
   `git diff --cached` before committing. Use Worktrunk without its default
   stage-all behavior:

   ```json
   { "command": "step", "args": ["commit", "--stage=none"] }
   ```

   If commit-message generation is unavailable, use
   `git commit -m "<accurate task summary>"` with the same reviewed index.
   Respect hooks.

2. Confirm the destination remote and repository. Push only the task branch with
   `git push -u <remote> <branch>`. Never force-push without explicit
   permission. Worktrunk's `step push` updates a local target branch; it does
   not publish to GitHub.
3. Check for an existing open PR for this head and base. Reuse it instead of
   creating a duplicate. Otherwise run:

   ```sh
   gh pr create --repo <owner/repo> --base <base> --head <branch> --title "<summary>" --body-file <body-path>
   ```

   Write the body to a temporary file. Follow the repository PR template.
   Summarize what changed and why, list checks actually run and their results,
   and disclose remaining limitations. For fork PRs, use the correct
   `owner:branch` head. Do not invent issue links or test results.

4. Create a ready-for-review PR only after work is complete and required checks
   pass. If blocked, report the blocker; create a draft only when requested or
   agreed. Verify the resulting URL, head, and base with `gh pr view`.
5. Return the PR URL and a short verification summary. Leave the worktree and
   branch intact for review. Do not run `worktrunk merge`, enable auto-merge,
   delete branches, or remove worktrees unless explicitly requested.
