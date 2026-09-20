#!/usr/bin/env bash
# migrate.sh [--pending] - run each migrations/*.sh exactly once per machine
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$HOME/.local/state/dotfiles/migrations"
mkdir -p "$STATE"

shopt -s nullglob
pending=()
for m in "$DOTFILES"/migrations/*.sh; do
  [[ -f "$STATE/$(basename "$m")" ]] || pending+=("$m")
done

if [[ ${1:-} == --pending ]]; then
  ((${#pending[@]})) || exit 1
  printf '%s\n' "${pending[@]##*/}"
  exit 0
fi

for m in "${pending[@]}"; do
  id="$(basename "$m")"
  echo "migrating: $id"
  # Subshell with strict mode: one migration cannot leak state into the next
  bash -euo pipefail "$m" && touch "$STATE/$id"
done

# Migrations request restarts instead of doing them; drain the markers once
for marker in "$HOME/.local/state/dotfiles/restart-"*; do
  [[ -f "$marker" ]] || continue
  svc="$(basename "$marker")"
  svc="${svc#restart-}"
  rm -f "$marker"
  case "$svc" in
    shell) echo "  reload GNOME Shell: Alt+F2 then r" ;;
    tmux) tmux source-file ~/.tmux.conf 2> /dev/null || true ;;
    *) systemctl --user restart "$svc" 2> /dev/null || true ;;
  esac
done

# User extension point for machine-local steps kept out of the repo
hooks="$HOME/.config/dotfiles/hooks/post-migrate.d"
if [[ -d $hooks ]]; then
  for h in "$hooks"/*; do
    [[ -x "$h" ]] || continue
    echo "hook: $(basename "$h")"
    "$h" || echo "  hook failed (continuing)"
  done
fi
