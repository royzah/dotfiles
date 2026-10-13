# General shell functions

# Create directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1" }

# Find and kill process by port
killport() {
  [[ -z "$1" ]] && { echo "Usage: killport <port>"; return 1 }
  local pids
  pids=$(lsof -ti:"$1" 2>/dev/null)
  [[ -z "$pids" ]] && { echo "No process on port $1"; return 0 }
  echo "$pids" | xargs kill -9 && echo "Killed processes on port $1"
}

# Quick backup of a file
backup() { cp "$1" "$1.bak-$(date +%Y%m%d-%H%M%S)" }

# Extract any archive
extract() {
  [[ ! -f "$1" ]] && { echo "'$1' is not a valid file"; return 1 }
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.tar.zst) tar --zstd -xf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.Z)       uncompress "$1" ;;
    *.7z)      7z x "$1" ;;
    *.xz)      xz -d "$1" ;;
    *.zst)     zstd -d "$1" ;;
    *)         echo "'$1' unknown archive type" ;;
  esac
}

# Find file/directory by name (fd if available, else find)
if command -v fd >/dev/null 2>&1; then
  ff()   { fd -t f -i "$1" }
  fdir() { fd -t d -i "$1" }
else
  ff()   { find . -type f -iname "*$1*" 2>/dev/null }
  fdir() { find . -type d -iname "*$1*" 2>/dev/null }
fi

# Search in files (ripgrep if available, else grep)
findin() {
  if command -v rg >/dev/null 2>&1; then
    rg "$1"
  else
    grep -rnw . -e "$1" 2>/dev/null
  fi
}

# Serve current directory over HTTP
serve() { python3 -m http.server "${1:-8000}" }

# Quick json formatting
json() { python3 -m json.tool "$@" }

# --- SSH ---
ssht() { ssh -t "$@" 'tmux new-session -A -s main' }

listening() { ss -tulnp | grep -E "${1:-.}" }

logs() { lnav "${1:?Usage: logs <file>}" }

dns() {
  if command -v dog >/dev/null 2>&1; then
    dog "$@"
  else
    dig +short "$@"
  fi
}

remind() { "$HOME/bin/remind.sh" "$@" }

# Date-stamped experiment dir
try() {
  local d="$HOME/Work/tries/$(date +%F)-${1:?Usage: try <name>}"
  mkdir -p "$d" && cd "$d"
}

compress() { tar czf "${1:?Usage: compress <dir>}.tar.gz" "$1" }

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

# tmux swarm: n tiled panes all running the same command
tsl() {
  [[ -n "$TMUX" ]] || { echo "Run inside tmux"; return 1 }
  local n="${1:?Usage: tsl <panes> <command...>}"
  shift
  tmux new-window
  local i
  for ((i = 1; i < n; i++)); do
    tmux split-window
    tmux select-layout tiled >/dev/null
  done
  for i in $(tmux list-panes -F '#P'); do
    tmux send-keys -t "$i" "$*" C-m
  done
}

# Git worktree add/drop (sibling dir named repo-branch)
gwa() {
  local b="${1:?Usage: gwa <branch>}" root
  root=$(git rev-parse --show-toplevel) || return 1
  local dir="${root}-${b//\//-}"
  git worktree add "$dir" -b "$b" 2>/dev/null || git worktree add "$dir" "$b"
  cd "$dir"
}

gwd() {
  local wt main
  wt=$(git rev-parse --show-toplevel) || return 1
  main=$(git worktree list | head -1 | awk '{print $1}')
  [[ "$wt" == "$main" ]] && { echo "Refusing to remove main worktree"; return 1 }
  cd "$main" && git worktree remove "$wt"
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

alias weather='curl -s "wttr.in/?format=3"'

# Media conversion
webm2mp4() {
  local f="${1:?Usage: webm2mp4 <file.webm>}"
  ffmpeg -i "$f" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "${f%.webm}.mp4"
}

# --- VPN (openconnect; set VPN_HOST, VPN_USER, VPN_PROTO in ~/.secrets.env) ---
vpn() {
  [[ -z "${VPN_HOST:-}" || -z "${VPN_USER:-}" ]] && { echo "Set VPN_HOST and VPN_USER in ~/.secrets.env"; return 1 }
  sudo openconnect --protocol="${VPN_PROTO:-gp}" "$VPN_HOST" --user "$VPN_USER" -b
}
# SIGINT lets openconnect restore routes and DNS on the way out
alias vpnoff='sudo pkill -INT openconnect'
alias vpnstatus='pgrep -a openconnect || echo "VPN not connected"'
