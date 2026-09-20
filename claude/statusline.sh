#!/usr/bin/env bash
# Claude Code statusline - model | dir | git branch | session cost
# Receives session JSON on stdin. Catppuccin Mocha colors.

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // empty')

branch=$(git -C "$cwd" branch --show-current 2> /dev/null)

blue=$'\033[38;2;137;180;250m'
yellow=$'\033[38;2;249;226;175m'
red=$'\033[38;2;243;139;168m'
green=$'\033[38;2;166;227;161m'
dim=$'\033[38;2;108;112;134m'
reset=$'\033[0m'

out="${blue}${model}${reset} ${dim}|${reset} ${yellow}${cwd/#$HOME/\~}${reset}"
[[ -n "$branch" ]] && out+=" ${dim}|${reset} ${red}${branch}${reset}"
[[ -n "$cost" ]] && out+=" ${dim}|${reset} ${green}\$$(printf '%.2f' "$cost")${reset}"

printf '%s' "$out"
