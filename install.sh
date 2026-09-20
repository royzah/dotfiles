#!/usr/bin/env bash
# Dotfiles installer - symlinks configs to their expected locations
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$DOTFILES/$1"
  local dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  backup: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sfn "$src" "$dst"
  echo "  linked: $dst -> $src"
}

# shellcheck source=bin/hw-profile.sh
source "$DOTFILES/bin/hw-profile.sh"

echo "=== Dotfiles Installer ==="
echo "Source: $DOTFILES"
echo ""

# Shell
echo "[shell]"
link zshrc ~/.zshrc
link starship/starship.toml ~/.config/starship.toml

# Git
echo "[git]"
link gitconfig ~/.gitconfig
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
  link claude/settings.json ~/.claude/settings.json
  link claude/statusline.sh ~/.claude/statusline.sh
  link claude/hooks ~/.claude/hooks
  chmod +x "$DOTFILES"/claude/statusline.sh "$DOTFILES"/claude/hooks/*.sh
fi

# Claude Remote Control (systemd user service)
echo "[systemd]"
# Copied, not symlinked: systemd 249 (Ubuntu 22.04) breaks enable on linked units
mkdir -p ~/.config/systemd/user
rm -f ~/.config/systemd/user/{claude-remote,tmux,backup}.service ~/.config/systemd/user/backup.timer
cp -f "$DOTFILES"/systemd/claude-remote.service "$DOTFILES"/systemd/tmux.service \
  "$DOTFILES"/systemd/backup.service "$DOTFILES"/systemd/backup.timer ~/.config/systemd/user/
echo "  copied: claude-remote, tmux, backup service+timer"
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
