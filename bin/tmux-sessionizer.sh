#!/usr/bin/env bash
# tmux-sessionizer — quickly switch to a project in a tmux session
# Uses zoxide for frecency-ranked directories + fd for discovery
set -euo pipefail

if [[ -n "${1:-}" ]]; then
  selected="$1"
else
  selected=$(
    {
      zoxide query -l 2> /dev/null | head -20
      fd . ~/Code --type d --max-depth 1 2> /dev/null
    } | sort -u | fzf --reverse --prompt="Project> " --height=40%
  ) || exit 0
fi

[[ -z "$selected" ]] && exit 0

session_name=$(basename "$selected" | tr '.' '_')

if ! tmux has-session -t="$session_name" 2> /dev/null; then
  tmux new-session -ds "$session_name" -c "$selected"
fi

if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session_name"
else
  tmux attach-session -t "$session_name"
fi
