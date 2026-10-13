# ==============================================================================
# ~/.zshrc - Royyan (Full-stack + DevOps + Embedded + Nix)
# ==============================================================================

# Prompt: starship (initialized in section 7). Aliases and functions live in
# zsh/*.zsh next to the real (symlink-resolved) zshrc.

# ==============================================================================
# 2) PATH / Environment
# ==============================================================================

typeset -U path PATH  # auto-dedup

path=(
  "/home/linuxbrew/.linuxbrew/bin"
  "/home/linuxbrew/.linuxbrew/sbin"
  "$HOME/.local/bin"
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
# 6) Aliases & functions (zsh/*.zsh)
# ==============================================================================

for _f in "${${(%):-%x}:A:h}"/zsh/*.zsh(N); do
  source "$_f"
done
unset _f

# ==============================================================================
# 7) Tool init
# ==============================================================================

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# mise (manages Node, Python, Go, Rust versions). Before the tool inits below:
# on a machine without Homebrew, direnv, fzf and zoxide come from mise.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# direnv (per-project env vars)
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# fzf (Ctrl-T: file picker, Alt-C: cd). Ctrl-R belongs to atuin when present.
(( $+commands[atuin] )) && export FZF_CTRL_R_COMMAND=
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
