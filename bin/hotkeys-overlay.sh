#!/usr/bin/env bash
# hotkeys-overlay.sh - searchable list of custom hotkeys + tmux binds
set -euo pipefail

{
  dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ |
    awk -F"='" '
      /^binding/ { b=$2; sub(/.$/, "", b) }
      /^name/    { n=$2; sub(/.$/, "", n) }
      /^\[/ && b { print b "\t" n; b=""; n="" }
      END        { if (b) print b "\t" n }'
  printf '%s\t%s\n' \
    '<Super>' 'Activities / app search' \
    '<Super>l' 'Lock screen' \
    '<Primary><Alt>t' 'Terminal (Ghostty)' \
    'Print' 'Screenshot UI' \
    'Ctrl+grave' 'Ghostty quick terminal'
  tmux list-keys -N 2> /dev/null | sed 's/^/tmux prefix\t/' || true
} | column -t -s "$(printf '\t')" | fzf --prompt='hotkeys> ' --no-sort > /dev/null
