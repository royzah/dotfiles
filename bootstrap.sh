#!/usr/bin/env bash
# Fresh-machine bootstrap: everything the install guide can automate.
# Idempotent - rerun after any failure. Logins and logout stay manual.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BREW=/home/linuxbrew/.linuxbrew/bin/brew
MISE="$HOME/.local/bin/mise"
NIX=/nix/var/nix/profiles/default/bin/nix

have() { command -v "$1" > /dev/null 2>&1; }
# WSL2 has no GNOME, no X11 and no USB by default, so desktop pieces are skipped
# shellcheck source=bin/hw-profile.sh
source "$DOTFILES/bin/hw-profile.sh"
if is_wsl; then echo "(WSL detected: skipping desktop packages and GUI apps)"; fi

echo "[apt]"
sudo apt-get update -q
# pciutils backs GPU detection in hw-profile.sh
APT_CORE=(zsh curl build-essential git unzip jq tmux shellcheck inotify-tools pciutils minicom)
# wl-clipboard is the Wayland clipboard; xclip stays for X11 sessions.
# grim+slurp replace flameshot for region capture under Wayland.
APT_DESKTOP=(wl-clipboard xclip grim slurp fontconfig
  tesseract-ocr zbar-tools gpick zenity flameshot solaar wmctrl
  diodon gnome-sushi
  # GNOME extension deps: Vitals needs GTop bindings + lm-sensors (temps)
  gir1.2-gtop-2.0 lm-sensors gir1.2-clutter-1.0)
if is_wsl; then
  sudo apt-get install -yq "${APT_CORE[@]}"
else
  sudo apt-get install -yq "${APT_CORE[@]}" "${APT_DESKTOP[@]}"
fi

echo "[shell]"
[[ "${SHELL##*/}" == zsh ]] || chsh -s "$(command -v zsh)"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  [[ -d "$HOME/.oh-my-zsh/custom/plugins/$p" ]] ||
    git clone --depth=1 "https://github.com/zsh-users/$p" "$HOME/.oh-my-zsh/custom/plugins/$p"
done

echo "[nix]"
if ! have nix && [[ ! -x $NIX ]]; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi
"$NIX" profile list 2> /dev/null | grep -q nix-direnv || "$NIX" profile install nixpkgs#nix-direnv

echo "[docker]"
# Engine, not Docker Desktop: native on Linux, no VM layer, no license terms
if ! have docker; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
fi

echo "[neovim]"
if [[ ! -x "$HOME/.local/nvim/bin/nvim" ]]; then
  curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz | tar xz -C "$HOME/.local"
  rm -rf "$HOME/.local/nvim"
  mv "$HOME/.local/nvim-linux-x86_64" "$HOME/.local/nvim"
fi

echo "[vscode]"
if is_wsl; then
  echo "  skipped on WSL: install VS Code on Windows with the WSL extension"
else
  have code || sudo snap install code --classic
fi

echo "[homebrew]"
[[ -x $BREW ]] || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew_missing() {
  local f out=()
  for f in "$@"; do
    [[ -d "/home/linuxbrew/.linuxbrew/opt/$f" ]] || out+=("$f")
  done
  ((${#out[@]} == 0)) || "$BREW" install "${out[@]}"
}
brew_missing git-delta eza zoxide fzf fd bat ripgrep lazygit direnv btop just gh starship atuin restic bitwarden-cli
brew_missing lazydocker k9s kubectx stern yq awscli tldr \
  act kustomize grpcurl tokei hyperfine \
  lnav httpie dive nmap dust jless shfmt stylua luacheck yt-dlp speedtest-cli \
  cmatrix pipes-sh cbonsai fastfetch cava ||
  echo "  some optional tools failed - install manually or rerun"

echo "[runtimes]"
[[ -x $MISE ]] || curl -fsSL https://mise.run | sh
"$MISE" trust "$DOTFILES/mise.toml"
"$MISE" install -y
"$MISE" exec node -- npm ls -g markdownlint-cli > /dev/null 2>&1 ||
  "$MISE" exec node -- npm install -g --no-fund markdownlint-cli
have rustup || [[ -x "$HOME/.cargo/bin/rustup" ]] ||
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "[claude]"
have claude || [[ -x "$HOME/.local/bin/claude" ]] || curl -fsSL https://claude.ai/install.sh | bash

echo "[migrations]"
"$DOTFILES"/bin/migrate.sh

echo "[tmux plugins]"
[[ -d "$HOME/.tmux/plugins/tpm" ]] ||
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

echo ""
echo "Done. Next:"
echo "  1. log out and back in (zsh default shell, docker group)"
echo "  2. ./install.sh && ./setup-system.sh"
echo "  3. claude (/login), nvim (:Lazy sync), tmux (prefix+I)"
echo "  4. optional: atuin login, sudo ufw enable"
