#!/usr/bin/env bash
# Dotfiles installer - symlinks configs to their expected locations
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Never overwrite an earlier backup: a second run gets a timestamped name
backup() {
  local dst="$1" bak="$1.bak"
  [[ -e $bak || -L $bak ]] && bak="$1.bak.$(date +%Y%m%d-%H%M%S)"
  echo "  backup: $dst -> $bak"
  mv "$dst" "$bak"
}

link() {
  local src="$DOTFILES/$1"
  local dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    backup "$dst"
  fi
  ln -sfn "$src" "$dst"
  echo "  linked: $dst -> $src"
}

# A real file that includes the repo config, not a symlink: `gh/glab auth
# setup-git` write credential blocks through a symlink into the public repo
gitconfig_stub() {
  local dst="$HOME/.gitconfig" inc="$DOTFILES/gitconfig" paths=""
  if [[ -f $dst && ! -L $dst ]]; then
    paths=$(git config -f "$dst" --get-all include.path 2> /dev/null) || paths=""
    if grep -qxF "$inc" <<< "$paths"; then
      echo "  ok: $dst includes $inc"
      return 0
    fi
    backup "$dst"
  fi
  rm -f "$dst"
  printf '# Machine-local: gh/glab write here. Shared config is included below.\n[include]\n\tpath = %s\n' "$inc" > "$dst"
  echo "  wrote: $dst (includes $inc)"
}

# Merged, not linked: Claude Code writes runtime keys into its settings file.
# Repo keys win; local-only keys (account ids, toggles) survive.
claude_settings() {
  local dst="$HOME/.claude/settings.json" base="$DOTFILES/claude/settings.json" cur='{}' tmp
  if ! command -v jq > /dev/null; then
    echo "  skipped: $dst (jq not installed)"
    return 0
  fi
  if [[ -e $dst ]]; then
    if jq empty "$dst" 2> /dev/null; then cur=$(< "$dst"); else backup "$dst"; fi
  fi
  tmp=$(mktemp "$dst.XXXXXX")
  jq -s '.[0] * .[1]' <(printf '%s\n' "$cur") "$base" > "$tmp"
  mv "$tmp" "$dst"
  echo "  merged: $dst <- $base"
}

# shellcheck source=bin/hw-profile.sh
source "$DOTFILES/bin/hw-profile.sh"

echo "=== Dotfiles Installer ==="
echo "Source: $DOTFILES"
echo ""

# Shell
echo "[shell]"
link zshrc ~/.zshrc
# Ubuntu's /etc/zsh/zshrc runs an uncached compinit before oh-my-zsh runs its own
if ! grep -qx 'skip_global_compinit=1' ~/.zshenv 2> /dev/null; then
  echo 'skip_global_compinit=1' >> ~/.zshenv
  echo "  appended: skip_global_compinit=1 to ~/.zshenv"
fi
link starship/starship.toml ~/.config/starship.toml

# Git
echo "[git]"
gitconfig_stub
# Lets `git log --show-signature` verify our own SSH-signed commits
if [[ -f ~/.ssh/id_ed25519.pub && ! -f ~/.ssh/allowed_signers ]]; then
  printf '%s namespaces="git" %s\n' "$(git config -f "$DOTFILES/gitconfig" user.email)" "$(< ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
  echo "  wrote: ~/.ssh/allowed_signers"
fi
link gitignore_global ~/.gitignore_global

# Tmux
echo "[tmux]"
link tmux.conf ~/.tmux.conf

# Ghostty (Linux desktop only; on WSL the terminal lives on Windows)
if is_wsl; then
  echo "[ghostty] skipped on WSL"
else
  echo "[ghostty]"
  mkdir -p ~/.config/ghostty
  link ghostty/config ~/.config/ghostty/config
fi

# Neovim
echo "[neovim]"
mkdir -p ~/.config/nvim/lua/config ~/.config/nvim/lua/plugins
link nvim/init.lua ~/.config/nvim/init.lua
link nvim/lazyvim.json ~/.config/nvim/lazyvim.json
link nvim/stylua.toml ~/.config/nvim/stylua.toml
link nvim/lua/config/lazy.lua ~/.config/nvim/lua/config/lazy.lua
link nvim/lua/config/options.lua ~/.config/nvim/lua/config/options.lua
link nvim/lua/config/keymaps.lua ~/.config/nvim/lua/config/keymaps.lua
link nvim/lua/config/autocmds.lua ~/.config/nvim/lua/config/autocmds.lua
link nvim/lua/plugins/user.lua ~/.config/nvim/lua/plugins/user.lua
link nvim/lua/plugins/lsp.lua ~/.config/nvim/lua/plugins/lsp.lua
link nvim/lua/plugins/dap-config.lua ~/.config/nvim/lua/plugins/dap-config.lua
link nvim/lua/plugins/snippets.lua ~/.config/nvim/lua/plugins/snippets.lua
link nvim/lua/plugins/claudecode.lua ~/.config/nvim/lua/plugins/claudecode.lua

# Mise
echo "[mise]"
mkdir -p ~/.config/mise
link mise.toml ~/.config/mise/config.toml

# GDB
echo "[gdb]"
link gdbinit ~/.gdbinit

# SSH
echo "[ssh]"
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh
link ssh_config ~/.ssh/config
chmod 600 ~/.ssh/config

# Scripts
echo "[scripts]"
mkdir -p ~/bin
for script in "$DOTFILES"/bin/*.sh; do
  base="$(basename "$script")"
  link "bin/$base" ~/bin/"$base"
done
link bin/dotf.sh ~/bin/dotf
chmod +x "$DOTFILES"/bin/*.sh

# Compose key snippets
echo "[xcompose]"
link XCompose ~/.XCompose

# Session environment (Wayland hints for Electron/Qt/Firefox)
if has_gui; then
  echo "[environment.d]"
  mkdir -p ~/.config/environment.d
  link environment.d/40-wayland.conf ~/.config/environment.d/40-wayland.conf
fi

# LazyGit
echo "[lazygit]"
mkdir -p ~/.config/lazygit
link lazygit/config.yml ~/.config/lazygit/config.yml

# Direnv
echo "[direnv]"
mkdir -p ~/.config/direnv
link direnvrc ~/.config/direnv/direnvrc

# Claude Code (global config - memory, settings/permissions, statusline, hooks)
if is_work; then
  echo "[claude] skipped on a work machine (company AI instead)"
else
  echo "[claude]"
  mkdir -p ~/.claude
  link claude/CLAUDE.md ~/.claude/CLAUDE.md
  claude_settings
  link claude/statusline.sh ~/.claude/statusline.sh
  link claude/hooks ~/.claude/hooks
  chmod +x "$DOTFILES"/claude/statusline.sh "$DOTFILES"/claude/hooks/*.sh
fi

# Systemd user services (tmux, backup, and Claude Remote Control off work machines)
echo "[systemd]"
# Copied, not symlinked: systemd 249 (Ubuntu 22.04) breaks enable on linked units
UNIT_DIR=~/.config/systemd/user
mkdir -p "$UNIT_DIR"
# Was tmux.service, a name tmux-continuum disables on every tmux server start
if grep -qs 'tmux default session' "$UNIT_DIR/tmux.service"; then
  systemctl --user disable tmux.service > /dev/null 2>&1 || true
  rm -f "$UNIT_DIR/tmux.service"
fi
rm -f "$UNIT_DIR"/{claude-remote,tmux-main,backup}.service "$UNIT_DIR"/backup.timer
cp -f "$DOTFILES"/systemd/tmux-main.service "$DOTFILES"/systemd/backup.service \
  "$DOTFILES"/systemd/backup.timer "$UNIT_DIR"/
if is_work; then
  echo "  copied: tmux, backup service+timer (claude-remote skipped on a work machine)"
else
  # systemd cannot resolve the repo path itself, so it is filled in here
  sed "s|@DOTFILES@|$DOTFILES|g" "$DOTFILES"/systemd/claude-remote.service > "$UNIT_DIR"/claude-remote.service
  echo "  copied: claude-remote, tmux, backup service+timer"
fi
systemctl --user daemon-reload 2> /dev/null || true

# VS Code (on WSL, VS Code runs on Windows via the WSL extension)
if is_wsl; then
  echo "[vscode] skipped on WSL"
else
  echo "[vscode]"
  mkdir -p ~/.config/Code/User
  link vscode/settings.json ~/.config/Code/User/settings.json
  if command -v code &> /dev/null; then
    # Only install what is missing; code --install-extension otherwise prints a
    # "already installed, use --force" line per extension and re-checks each.
    installed="$(code --list-extensions 2> /dev/null | tr '[:upper:]' '[:lower:]')"
    added=0
    while IFS= read -r ext; do
      ext="${ext%$'\r'}"
      [[ -z "$ext" || "$ext" == \#* ]] && continue
      if grep -qxF "${ext,,}" <<< "$installed"; then continue; fi
      if code --install-extension "$ext" > /dev/null 2>&1; then
        added=$((added + 1))
      fi
    done < "$DOTFILES/vscode/extensions.txt"
    echo "  extensions: $added newly installed, rest already present"
  else
    echo "  skipped: code not found (install VS Code first)"
  fi
fi

# Minicom (on WSL, serial ports arrive via usbipd-win)
echo "[minicom]"
link minirc.dfl ~/.minirc.dfl
link minirc.pico ~/.minirc.pico
link minirc.modem ~/.minirc.modem

echo ""
echo "Done!"
echo ""
echo "=== Next ==="
echo "Fresh machine:   ./bootstrap.sh first (installs all tools), then rerun this"
if is_wsl; then echo "WSL:             skip setup-system.sh, Windows owns the desktop"; fi
echo "System setup:    ./setup-system.sh  (font, Ghostty, GNOME keybindings, systemd)"
echo "Full guide:      README.md Fresh Install"
