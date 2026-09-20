# ==============================================================================
# ~/.zshrc - Royyan (Full-stack + DevOps + Embedded + Nix)
# ==============================================================================

# Prompt: starship (initialized in section 9)

# ==============================================================================
# 2) PATH / Environment
# ==============================================================================

typeset -U path PATH  # auto-dedup

path=(
  "/home/linuxbrew/.linuxbrew/bin"
  "/home/linuxbrew/.linuxbrew/sbin"
  "$HOME/.local/bin"
  "$HOME/.local/nvim/bin"
  "$HOME/bin"
  "$HOME/.bun/bin"
  "$HOME/.npm-global/bin"
  "$HOME/go/bin"
  "$HOME/Android/Sdk/emulator"
  "$HOME/Android/Sdk/platform-tools"
  "$HOME/Android/Sdk/cmdline-tools/latest/bin"
  "/nix/var/nix/profiles/default/bin"
  $path
)

# Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Linuxbrew (hardcoded for speed - avoids slow `brew shellenv`)
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
export MANPATH="/home/linuxbrew/.linuxbrew/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"

# Defaults
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R --mouse --wheel-lines=3"

# SDK / Runtime
export ANDROID_HOME="$HOME/Android/Sdk"
export KUBECONFIG="$HOME/.kube/config"
# Work-specific exports (GOPRIVATE, AWS_PROFILE, ...) go in ~/.secrets.env

# Go
export GOPATH="${GOPATH:-$HOME/go}"

# Secrets (NEVER commit ~/.secrets.env)
[[ -f "$HOME/.secrets.env" ]] && source "$HOME/.secrets.env"

# ==============================================================================
# 3) Oh My Zsh
# ==============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""    # prompt comes from starship

plugins=(
  git
  docker
  kubectl
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# 4) History (enhanced)
# ==============================================================================

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt HIST_EXPIRE_DUPS_FIRST   # Expire dups first when trimming
setopt HIST_IGNORE_ALL_DUPS     # Remove older dups from history
setopt HIST_IGNORE_SPACE        # Skip commands starting with space
setopt HIST_FIND_NO_DUPS        # Don't display dups when searching
setopt HIST_SAVE_NO_DUPS        # Don't write dups to file
setopt SHARE_HISTORY            # Share history across terminals
setopt EXTENDED_HISTORY         # Record timestamp
setopt HIST_VERIFY              # Show expanded history command before executing
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks from history

# ==============================================================================
# 5) Shell Options
# ==============================================================================

setopt AUTO_CD              # cd by typing directory name
setopt CORRECT              # Suggest corrections for typos
setopt GLOB_DOTS            # Include dotfiles in glob
setopt EXTENDED_GLOB        # Advanced globbing (#, ~, ^)
setopt NO_CASE_GLOB         # Case-insensitive globbing
setopt INTERACTIVE_COMMENTS # Allow # comments in interactive shell

# ==============================================================================
# 6) Aliases
# ==============================================================================

# --- Files & Viewing ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --git --group-directories-first'
  alias ll='eza --icons --git -l --group-directories-first'
  alias la='eza --icons --git -la --group-directories-first'
  alias lt='eza --icons --git -l --tree --level=2'
  alias ltt='eza --icons --git -l --tree --level=3'
  alias l='eza -F --icons --group-directories-first'
fi
alias b='bat --style=plain --paging=never'
alias duu='dust'
alias jl='jless'
alias v='nvim'
alias gt='nohup ghostty >/dev/null 2>&1 & disown'

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dev='cd ~/Code'
alias src='cd ~/src'
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'
alias tmp='cd /tmp'

# --- Basic ---
alias c='clear'
alias h='history'
please() { sudo zsh -c "$(fc -ln -1)" }
alias apt-update='sudo apt update && sudo apt upgrade -y'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
localip() { hostname -I | awk '{print $1}' }
alias df='df -h'
alias free='free -h'
alias wget='wget -c'
alias headers='curl -sI'

# --- Git (extras beyond OMZ git plugin) ---
# OMZ provides: ga, gaa, gc, gcm, gco, gcb, gd, gf, gm, gp, gpf, gst (status), etc.
alias lg='lazygit'
alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit -20'

# --- Kubernetes ---
alias k='kubectl'
alias kk='k9s'
alias kctx='kubectl config get-contexts'
alias kns='kubectl get ns'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgd='kubectl get deployments'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kgn='kubectl get nodes -o wide'
alias kgcm='kubectl get configmap'
alias kgsec='kubectl get secrets'
alias kga='kubectl get all'
alias kgaa='kubectl get all -A'
alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kds='kubectl describe svc'
alias kdn='kubectl describe node'
alias kapply='kubectl apply -f'
alias kdel='kubectl delete -f'
alias kdelp='kubectl delete pod'
alias klog='kubectl logs -f'
alias klogp='kubectl logs -f --previous'
alias kexec='kubectl exec -it'
alias kpf='kubectl port-forward'
alias krollout='kubectl rollout status'
alias krestart='kubectl rollout restart'
alias ktop='kubectl top pods'
alias ktopn='kubectl top nodes'
alias kw='kubectl get events -A --field-selector type=Warning --sort-by=.metadata.creationTimestamp | tail -n 50'
alias ke='kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -n 50'
alias kdrain='kubectl drain --ignore-daemonsets --delete-emptydir-data'
alias kcordon='kubectl cordon'
alias kuncordon='kubectl uncordon'

# --- Terraform ---
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'

# --- Docker ---
alias ld='lazydocker'
alias d='docker'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a'
alias di='docker images'
alias dia='docker images -a'
alias drm='docker rm'
alias drmi='docker rmi'
alias drmf='docker rm -f'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dlogt='docker logs --tail 100 -f'
alias dinsp='docker inspect'
alias dstop='docker stop'
alias dstart='docker start'
alias drestart='docker restart'
alias dstats='docker stats --no-stream'
alias dnet='docker network ls'
alias dvol='docker volume ls'
alias dprune='docker system prune -af --volumes'
alias dimprune='docker image prune -af'
alias dvolprune='docker volume prune -f'
alias dbuild='docker build -t'
alias drun='docker run --rm -it'
alias dpull='docker pull'
alias dsave='docker save -o'
alias dload='docker load -i'
alias dtag='docker tag'
alias dpush='docker push'

# --- Docker Compose ---
alias dc='docker compose'
alias dcup='docker compose up -d'
alias dcupb='docker compose up -d --build'
alias dcdown='docker compose down'
alias dcdownv='docker compose down -v'
alias dclog='docker compose logs -f'
alias dclogt='docker compose logs --tail 100 -f'
alias dcps='docker compose ps'
alias dcpsa='docker compose ps -a'
alias dcbuild='docker compose build --no-cache'
alias dcpull='docker compose pull'
alias dcrestart='docker compose restart'
alias dcexec='docker compose exec'
alias dcrun='docker compose run --rm'
alias dcstop='docker compose stop'
alias dcstart='docker compose start'
alias dcconfig='docker compose config'
alias dctop='docker compose top'

# --- Rust / Cargo ---
alias cb='cargo build'
alias cbr='cargo build --release'
alias cr='cargo run'
alias crr='cargo run --release'
alias ct='cargo test'
alias cta='cargo test -- --nocapture'
alias cck='cargo check'
alias cclean='cargo clean'
alias cf='cargo fmt'
alias cfc='cargo fmt --check'
alias ccl='cargo clippy'
alias ccla='cargo clippy --all-targets --all-features -- -D warnings'
alias cu='cargo update'
alias cw='cargo watch -x check'
alias cwt='cargo watch -x test'
alias cwr='cargo watch -x run'
alias cdoc='cargo doc --open'
alias ctree='cargo tree'
alias cbench='cargo bench'
alias cbin='cargo install --path .'

# --- Go ---
alias gob='go build'
alias gor='go run .'
alias got='go test'
alias gotv='go test -v'
alias gota='go test ./...'
alias gomt='go mod tidy'
alias gomv='go mod vendor'
alias gof='gofmt -w .'
alias goi='go install'
alias gogu='go get -u ./...'
alias govet='go vet ./...'
alias gobench='go test -bench=.'

# --- Python ---
alias py='python3'
alias pip='pip3'
alias pipi='pip3 install'
alias pipu='pip3 install --upgrade'
alias pipr='pip3 install -r requirements.txt'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'
alias pyclean='find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null; find . -type f -name "*.pyc" -delete 2>/dev/null'

# --- Debugging / Network ---
alias http='http --style=monokai'
alias sniff='tcpdump -i any -n -c 100'

# --- System ---
alias top='btop'
alias fetch='fastfetch'

# --- Apps ---
# claude is installed via mise/node, no alias needed
alias headlamp="$HOME/Apps/headlamp/headlamp.AppImage"

# --- Claude Code (Copilot on a work machine, via ai.sh) ---
alias cc='ai.sh'
alias ccc='ai.sh --continue'
alias ccr='claude remote-control --name "dev-session"'

# Copy CLAUDE.md template into current repo, exclude it from the project's git
# via .git/info/exclude (local-only, does not touch the shared .gitignore)
ccinit() {
  local root gitdir
  root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1 }
  gitdir=$(git rev-parse --path-format=absolute --git-common-dir)
  if [[ -f "$root/CLAUDE.md" ]]; then
    echo "CLAUDE.md already exists"
  else
    cp ~/Code/dotfiles/templates/CLAUDE.md "$root/CLAUDE.md" && echo "Created $root/CLAUDE.md"
  fi
  mkdir -p "$gitdir/info"
  grep -qx 'CLAUDE.md' "$gitdir/info/exclude" 2>/dev/null || echo 'CLAUDE.md' >> "$gitdir/info/exclude"
  echo "CLAUDE.md excluded via $gitdir/info/exclude"
}

# --- Fun ---
alias matrix='cmatrix -ab -C cyan'
alias pipes='pipes.sh -p 5 -R -t 1'
alias bonsai='cbonsai -l -i -t 0.02'
alias visualizer='cava'

# --- VPN (openconnect; set VPN_HOST, VPN_USER, VPN_PROTO in ~/.secrets.env) ---
vpn() {
  [[ -z "${VPN_HOST:-}" || -z "${VPN_USER:-}" ]] && { echo "Set VPN_HOST and VPN_USER in ~/.secrets.env"; return 1 }
  sudo openconnect --protocol="${VPN_PROTO:-gp}" "$VPN_HOST" --user "$VPN_USER" -b
}
alias vpnoff='sudo pkill -9 openconnect'
alias vpnstatus='pgrep -a openconnect || echo "VPN not connected"'

# ==============================================================================
# 7) NIX - Aliases & Functions
# ==============================================================================

# --- Cleanup ---
cleansrc() { nix-store --query --referrers-closure /nix/store/*-source 2>/dev/null | xargs sudo "$(which nix-store)" --delete --ignore-liveness 2>/dev/null }
alias cleanall='cleansrc; nixgc'

# --- Nix Build Functions ---
# nbuild <attr>       build flake attr, verbose (nbuild pkg -> .#pkg)
# nbuild_a64 <pkg>    cross/native build for aarch64-linux
nbuild() {
  local name="${1:?Usage: nbuild <attr> [extra-args...]}"
  shift
  nix build ".#$name" -vL "$@"
}

nbuild_a64() {
  local name="${1:?Usage: nbuild_a64 <pkg> [extra-args...]}"
  shift
  nix build ".#packages.aarch64-linux.$name" -vL "$@"
}

# --- Serial Communication (minicom) ---
# sudo -E preserves HOME so minicom reads ~/.minirc.dfl (our colors)
alias mcom='sudo -E minicom -c on -b 115200 -D'
mcomusb() { sudo -E minicom -c on -D "/dev/ttyUSB${1:-0}" -b 115200 }
mcomacm() { sudo -E minicom -c on -D "/dev/ttyACM${1:-0}" -b 115200 }
alias lsserial='ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "No serial devices"'

# fzf serial picker (from original zshrc)
serial() {
  local port
  port=$(ls /dev/ttyUSB* /dev/ttyACM* /dev/ttyS* 2>/dev/null | fzf --prompt="Serial port> " --height=10)
  [[ -z "$port" ]] && return
  local baud="${1:-115200}"
  echo "Connecting to $port @ ${baud}baud (Ctrl-A X to quit)"
  sudo -E minicom -c on -D "$port" -b "$baud"
}

# --- Nix Formatting ---
nixfmt()      { alejandra "${1:-.}" }
nixfmttree()  { nix run nixpkgs#nixfmt-tree -- "${1:-.}" }
nixfmtall()   { alejandra "${1:-.}" && nix run nixpkgs#nixfmt-tree -- "${1:-.}" }
nixfmtcheck() { alejandra --check "${1:-.}" }
nixlint()     { nix run nixpkgs#statix -- check "${1:-.}" }
nixlintfix()  { nix run nixpkgs#statix -- fix "${1:-.}" }
nixdead()     { nix run nixpkgs#deadnix -- "${1:-.}" }
nixdeadfix()  { nix run nixpkgs#deadnix -- -e "${1:-.}" }
nixclean()    { nixfmtall "${1:-.}" && nixlint "${1:-.}" && nixdead "${1:-.}" }

# --- Nix Flake ---
upinput() { nix flake update "$@" }
alias flakeshow='nix flake show'
alias flakecheck='nix flake check'
alias flakemeta='nix flake metadata'
alias flakelock='nix flake lock'

# --- Nix Store ---
alias qreferrers='sudo $(which nix-store) --query --referrers'
alias qreferences='sudo $(which nix-store) --query --references'
alias qrequisites='nix-store --query --requisites'
alias qtree='nix-store --query --tree'
alias qsize='nix path-info -Sh'
alias qclosure='nix path-info -rSh'
alias nixgc='nix-collect-garbage -d'
alias nixgcold='nix-collect-garbage --delete-older-than 7d'
alias nixopt='nix-store --optimise'
alias nixrepair='nix-store --verify --check-contents --repair'
alias nixroots='nix-store --gc --print-roots | grep -v censored'
alias nixstoredu='df -h /nix/store && echo "---" && nix path-info --all -Sh 2>/dev/null | sort -hk2 | tail -20'

# --- Nix Dev ---
alias nixshell='nix-shell --run zsh'
alias nixdev='nix develop'
alias nixdevsh='nix develop --command zsh'
alias nixsearch='nix search nixpkgs'
alias nixrepl='nix repl'
alias nixlog='nix log'
alias nixwhy='nix why-depends'

# --- Nix Build Helpers ---
alias nixb='nix build'
alias nixbv='nix build -vL'
alias nixbimp='nix build --impure'
alias nixbvimp='nix build -vL --impure'
alias nixbdry='nix build --dry-run'
alias nixbtrace='nix build --show-trace -vL'

# --- Result Inspection ---
alias lsresult='ls -la ./result/ 2>/dev/null || echo "No result link"'
alias treeresult='tree -L 2 ./result/ 2>/dev/null || ls -laR ./result/ 2>/dev/null'
alias sizeresult='du -sh ./result/* 2>/dev/null'

# ==============================================================================
# 8) General Functions
# ==============================================================================

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

# Diff two nix derivations
nixdiff() {
  [[ $# -ne 2 ]] && { echo "Usage: nixdiff <drv1> <drv2>"; return 1 }
  nix-diff "$1" "$2" 2>/dev/null || diff <(nix path-info -r "$1" | sort) <(nix path-info -r "$2" | sort)
}

# Copy file to/from device over SSH
todev()   { scp "$2" "$1" }
fromdev() { scp "$1" "$2" }

# --- Kubernetes ---
kc() {
  [[ -z "$1" ]] && { echo "Usage: kc <context>"; return 1 }
  kubectl config use-context "$1" >/dev/null && kubectl config current-context
}

ksetns() {
  [[ -z "$1" ]] && { echo "Usage: ksetns <namespace>"; return 1 }
  kubectl config set-context --current --namespace="$1" >/dev/null && kubectl config view --minify | grep namespace:
}

kcur() {
  local ctx ns
  ctx="$(kubectl config current-context 2>/dev/null)"
  ns="$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)"
  echo "${ctx:-no-context} / ${ns:-default}"
}

klogs() { stern "${1:?Usage: klogs <pod-pattern>}" --tail=50 --since=5m }

# --- SSH ---
ssht() { ssh -t "$@" 'tmux new-session -A -s main' }

# --- Debugging ---
strace-pid() {
  [[ -z "$1" ]] && { echo "Usage: strace-pid <pid>"; return 1 }
  strace -f -e trace=network,write,read -p "$1" 2>&1 | bat --language=strace --style=plain
}

listening() { ss -tulnp | grep -E "${1:-.}" }

logs() { lnav "${1:?Usage: logs <file>}" }

dns() {
  if command -v dog >/dev/null 2>&1; then
    dog "$@"
  else
    dig +short "$@"
  fi
}

# --- WSL: bridge clipboard and browser to Windows ---
if [[ -n ${WSL_DISTRO_NAME:-} ]]; then
  # xclip/xsel do not exist without an X server; clip.exe and powershell do
  alias pbcopy='clip.exe'
  pbpaste() { powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r' }
  alias xclip='clip.exe'
  alias open='explorer.exe'
  export BROWSER='wslview'
  # Windows drives are slow: warn if a repo lives on /mnt/c
  [[ $PWD == /mnt/* ]] && echo "note: /mnt is the Windows filesystem - builds here are much slower"
fi

# --- Omarchy-inspired ---
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

# Continuous rsync to a device on file change
watchsync() {
  local src="${1:?Usage: watchsync <dir> <user@host:path>}" dst="${2:?Usage: watchsync <dir> <user@host:path>}"
  command -v inotifywait >/dev/null 2>&1 || { echo "Missing inotify-tools"; return 1 }
  while inotifywait -r -e modify,create,delete,move "$src" >/dev/null 2>&1; do
    rsync -az --delete "$src"/ "$dst" && echo "synced $(date +%T)"
  done
}

# Wrap ssh: a killed remote tmux leaves mouse tracking, focus reporting and
# the alt screen armed locally. Disarm on exit, then reconnect only on a
# network drop (255) from an interactive session that actually got going.
ssh() {
  local start=$SECONDS rc
  command ssh "$@"
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

# Media conversion
webm2mp4() {
  local f="${1:?Usage: webm2mp4 <file.webm>}"
  ffmpeg -i "$f" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "${f%.webm}.mp4"
}

# Write an iso to a block device: iso2sd file.iso /dev/sdX
iso2sd() {
  local src="${1:?Usage: iso2sd <file.iso> <device>}" dev="${2:?Usage: iso2sd <file.iso> <device>}"
  [[ -b "$dev" ]] || { echo "$dev is not a block device"; return 1 }
  lsblk -o NAME,SIZE,MODEL "$dev" || return 1
  read -q "REPLY?Write $src to $dev, erasing it? [y/N] " || { echo; return 1 }
  echo
  sudo dd bs=4M status=progress oflag=sync if="$src" of="$dev" && sudo eject "$dev"
}

# Apple keyboards: F-keys act as function keys, not media keys
alias fix_fkeys='echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode'

# Focus an existing window matching a WM class, or launch it. wmctrl only
# works on X11; under Wayland GNOME owns window activation, so we launch and
# let the shell raise the existing window (gtk-launch/.desktop does this).
focus_or_launch() {
  local pattern="${1:?Usage: focus_or_launch <wm-class> <command...>}"
  shift
  if [[ ${XDG_SESSION_TYPE:-} == x11 ]] && command -v wmctrl >/dev/null 2>&1; then
    wmctrl -x -a "$pattern" 2>/dev/null && return 0
  fi
  nohup "$@" >/dev/null 2>&1 & disown
}

# NordVPN (install: curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh | sh)
alias nvon='nordvpn connect'
alias nvoff='nordvpn disconnect'
alias nvstatus='nordvpn status'

# Run a command with GameMode (CPU governor + IO priority) and an FPS overlay
alias gm='gamemoderun'
alias gmhud='MANGOHUD=1 gamemoderun'

alias weather='curl -s "wttr.in/?format=3"'

wifipass() {
  nmcli -s -g 802-11-wireless-security.psk connection show \
    "$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 ~ /wireless/ {print $1; exit}')"
}

# ==============================================================================
# 9) Tool init
# ==============================================================================

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# mise (manages Node, Python, Go, Rust versions). Before the tool inits below:
# on a machine without Homebrew, direnv, fzf and zoxide come from mise.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# direnv (per-project env vars)
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# fzf (Ctrl-R: history, Ctrl-T: file picker, Alt-C: cd)
if [[ -f /home/linuxbrew/.linuxbrew/opt/fzf/shell/completion.zsh ]]; then
  source /home/linuxbrew/.linuxbrew/opt/fzf/shell/completion.zsh
  source /home/linuxbrew/.linuxbrew/opt/fzf/shell/key-bindings.zsh
elif [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
elif command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#b4befe,spinner:#f5e0dc,header:#f38ba8"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"

# zoxide (z to jump, zi for interactive)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd z)"


# atuin (shell history: Ctrl-R search, encrypted sync via `atuin login`)
# --disable-ai: Claude is the only AI here
command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh --disable-up-arrow --disable-ai)"

# Bitwarden ssh-agent (active only when the desktop app's agent is enabled)
[[ -S "$HOME/.bitwarden-ssh-agent.sock" ]] && export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

# starship prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Machine-local overrides - never committed (thoughtbot pattern)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
