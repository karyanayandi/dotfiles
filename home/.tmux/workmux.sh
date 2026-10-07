#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == menu ]]; then
    cd -- "$(tmux display-message -p '#{pane_current_path}')"
fi

function merge_in_progress() {
    local directory=$1 state
    for state in MERGE_HEAD rebase-merge rebase-apply; do
        if [[ -e $(git -C "$directory" rev-parse --path-format=absolute --git-path "$state") ]]; then
            return 0
        fi
    done
    return 1
}

function resolve_merge() {
    local directory candidate directories
    if ! command -v lazygit >/dev/null; then
        printf '%s\n' 'Merge resolution requires lazygit.' >&2
        return 1
    fi
    directory=$(workmux path "$1")
    if ! merge_in_progress "$directory"; then
        directories=$(workmux list --json < /dev/null | jq -r '.[].path')
        while IFS= read -r candidate; do
            if merge_in_progress "$candidate"; then
                directory=$candidate
                break
            fi
        done <<< "$directories"
    fi
    lazygit -p "$directory"
}

if [[ ${1:-} == run ]]; then
    shift
    if [[ $1 == resolve ]]; then
        resolve_merge "$2"
        exit 0
    fi
    log=$(mktemp)
    trap 'rm -f -- "$log"' EXIT
    if workmux "$@" 2>&1 | tee "$log"; then
        exit 0
    else
        status=$?
        if [[ $1 == merge ]] && {
            grep -Fq 'Merge failed due to conflicts' "$log" ||
                merge_in_progress "$(workmux path "$2")"
        }; then
            resolve_merge "$2"
            printf '%s\n' 'Resolve and commit in LazyGit, then retry Workmux Merge.'
        fi
        read -r -p 'Workmux failed. Press Enter to close.' || true
        exit "$status"
    fi
fi

for dependency in workmux fzf-tmux jq; do
    if ! command -v "$dependency" >/dev/null; then
        tmux display-message "Workmux menu requires $dependency"
        exit 1
    fi
done

function input() {
    local value status=0
    value=$(fzf-tmux -p 80%,20% -- --prompt="$1> " --print-query --no-multi < /dev/null) || status=$?
    [[ $status -le 1 && -n $value ]] || return 1
    printf '%s' "$value"
}

function run_workmux() {
    local command removed_path= windows= window height=25%
    if [[ $1 == merge || $1 == resolve ]]; then
        height=85%
    fi
    if [[ $1 == merge ]]; then
        set -- "$@" --cleanup
    fi
    if [[ $1 == remove || $1 == merge ]]; then
        removed_path=$(workmux path "$2")
        windows=$(tmux list-panes -a -F $'#{window_id}\t#{pane_current_path}' |
            jq -Rrs --arg path "$removed_path" '
                split("\n")[:-1] | map(split("\t")) | group_by(.[0])[] |
                select(all(.[]; length == 2 and
                    (.[1] == $path or (.[1] | startswith($path + "/"))))) | .[0][0]')
    fi
    printf -v command '%q ' bash "$0" run "$@"
    tmux display-popup -E -w 80% -h "$height" "$command"
    if [[ -n $removed_path && ! -d $removed_path ]]; then
        while IFS= read -r window; do
            if [[ -n $window ]] && tmux display-message -p -t "$window" '#{window_id}' >/dev/null 2>&1; then
                tmux kill-window -t "$window"
            fi
        done <<< "$windows"
    fi
}

action=$(printf '%s\n' 'add' 'add w/branch' 'add w/prompt' 'open' 'merge' 'resolve merge' 'remove' 'close' 'dashboard' 'sidebar' 'quit' |
    fzf-tmux -p 80%,40% -- --prompt='workmux> ' --no-multi) || exit 0

case "$action" in
    add)
        branch=$(input 'New branch') || exit 0
        run_workmux add "$branch"
        ;;
    'add w/branch')
        branch=$(git for-each-ref --format='%(refname:short)' --exclude='refs/remotes/*/HEAD' refs/heads refs/remotes |
            fzf-tmux -p 80%,40% -- --prompt='Branch> ' --no-multi) || exit 0
        run_workmux add "$branch"
        ;;
    'add w/prompt')
        branch=$(input 'New branch') || exit 0
        prompt=$(input 'Prompt') || exit 0
        run_workmux add "$branch" --prompt "$prompt"
        ;;
    open|merge|'resolve merge'|remove|close)
        worktrees=$(workmux list --json | jq -r --arg action "$action" \
            '.[] | select($action == "open" or $action == "resolve merge" or (.is_main | not)) | .handle')
        if [[ -z $worktrees ]]; then
            tmux display-message 'No worktrees available'
            exit 0
        fi
        target=$(printf '%s\n' "$worktrees" |
            fzf-tmux -p 80%,40% -- --prompt="$action> " --no-multi) || exit 0
        if [[ $action == 'resolve merge' ]]; then
            run_workmux resolve "$target"
        else
            run_workmux "$action" "$target"
        fi
        ;;
    dashboard)
        tmux display-popup -E -w 90% -h 90% 'workmux dashboard'
        ;;
    sidebar)
        workmux sidebar
        ;;
    quit)
        exit 0
        ;;
esac
