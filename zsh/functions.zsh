# General shell functions

logs() { lnav "${1:?Usage: logs <file>}" }

# tmux layout: nvim left, AI + shell right
tdl() {
  [[ -n "$TMUX" ]] || { echo "Run inside tmux"; return 1 }
  tmux new-window -n dev
  tmux split-window -h -l 38%
  tmux send-keys 'ai.sh' C-m
  tmux split-window -v -l 25%
  tmux select-pane -t 1
  tmux send-keys 'nvim .' C-m
}

# Wrap ssh: a killed remote tmux leaves mouse tracking, focus reporting and
# the alt screen armed locally. Disarm on exit, then reconnect only on a
# network drop (255) from an interactive session that actually got going.
# Ghostty's own ssh wrapper is disabled in ghostty/config so this one always wins.
ssh() {
  local start=$SECONDS rc
  if [[ $TERM == xterm-ghostty ]]; then
    TERM=xterm-256color command ssh -o 'SetEnv COLORTERM=truecolor' "$@"
  else
    command ssh "$@"
  fi
  rc=$?
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'
  if ((rc == 255)) && [[ -t 0 ]] && ((SECONDS - start >= 30)); then
    echo "ssh: connection dropped, reconnecting..." >&2
    ssh "$@"
    return $?
  fi
  return $rc
}

# Colorized man pages through bat
export MANROFFOPT=-c
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
