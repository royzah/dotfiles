#!/usr/bin/env bash
# No-sudo bootstrap for machines you do not administer (shared build servers).
# Everything lands in $HOME and nothing calls sudo. Idempotent - rerun anytime.
#
#   ./bootstrap-user.sh          personal machine
#   ./bootstrap-user.sh --work   work machine: company Copilot, no personal Claude
#
# Behind a proxy, export https_proxy first; curl, git and mise all honor it.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
MISE="$HOME/.local/bin/mise"

have() { command -v "$1" > /dev/null 2>&1; }
# shellcheck source=bin/hw-profile.sh
source "$DOTFILES/bin/hw-profile.sh"

echo "[profile]"
if [[ ${1:-} == --work ]]; then
  mkdir -p "$HOME/.config/dotfiles"
  touch "$HOME/.config/dotfiles/work"
fi
if is_work; then echo "  work (Copilot, no Claude)"; else echo "  personal"; fi

echo "[prereqs]"
for tool in git curl tar; do
  have "$tool" || {
    echo "  missing $tool - ask IT, it cannot be installed without root"
    exit 1
  }
done
curl -fsS --max-time 15 -o /dev/null https://github.com || {
  echo "  cannot reach github.com - set https_proxy, or ask IT to allow GitHub downloads"
  exit 1
}
# mise resolves versions through the GitHub API: 60 calls/hour per IP without a
# token, and everyone behind one office IP shares that
[[ -n ${MISE_GITHUB_TOKEN:-${GITHUB_TOKEN:-}} ]] ||
  echo "  note: no MISE_GITHUB_TOKEN; if mise hits a 403 rate limit, see WINDOWS_GUIDE.md"
echo "  ok"

echo "[zsh]"
# No root means no apt and no chsh: a static zsh in ~/.local, entered from bash
if have zsh || [[ -x "$HOME/.local/bin/zsh" ]]; then
  echo "  have: zsh"
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" -- -d "$HOME/.local" -e no -q
  echo "  installed: static zsh in ~/.local"
fi
if [[ ${SHELL##*/} != zsh ]] && ! grep -qF '# dotfiles: enter zsh' "$HOME/.bashrc" 2> /dev/null; then
  cat >> "$HOME/.bashrc" << 'EOF'

# dotfiles: enter zsh for interactive shells (no chsh without root)
if [[ $- == *i* && -z ${ZSH_VERSION:-} && -z ${BASH_EXECUTION_STRING:-} ]]; then
  for z in "$HOME/.local/bin/zsh" "$(command -v zsh)"; do [[ -x $z ]] && exec "$z" -l; done
fi
EOF
  echo "  ~/.bashrc now enters zsh"
fi

echo "[oh-my-zsh]"
[[ -d "$HOME/.oh-my-zsh" ]] || git clone -q --depth=1 https://github.com/ohmyzsh/ohmyzsh "$HOME/.oh-my-zsh"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  [[ -d "$HOME/.oh-my-zsh/custom/plugins/$p" ]] ||
    git clone -q --depth=1 "https://github.com/zsh-users/$p" "$HOME/.oh-my-zsh/custom/plugins/$p"
done
echo "  ok"

echo "[mise]"
[[ -x $MISE ]] || curl -fsSL https://mise.run | sh
mkdir -p "$HOME/.config/mise/conf.d"
ln -sfn "$DOTFILES/mise.toml" "$HOME/.config/mise/config.toml"
ln -sfn "$DOTFILES/mise-cli.toml" "$HOME/.config/mise/conf.d/cli.toml"
for f in mise.toml mise-cli.toml; do "$MISE" trust -q "$DOTFILES/$f"; done
if is_work; then
  # Machine-local, so the tracked configs never name a work tool
  printf '[tools]\n"npm:@github/copilot" = "latest"\n' > "$HOME/.config/mise/conf.d/work.toml"
fi
"$MISE" install -y

echo "[claude]"
if is_work; then
  echo "  skipped: work machine"
else
  have claude || [[ -x "$HOME/.local/bin/claude" ]] || curl -fsSL https://claude.ai/install.sh | bash
fi

echo "[tmux plugins]"
[[ -d "$HOME/.tmux/plugins/tpm" ]] ||
  git clone -q --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
echo "  ok"

echo ""
echo "Done. Next:"
echo "  1. ./install.sh                 link the configs"
echo "  2. exec zsh -l                  or log in again"
if is_work; then
  echo "  3. copilot (/login), nvim (:Copilot auth), tmux (prefix+I)"
  echo "  4. ~/.gitconfig.local with your work email (see WINDOWS_GUIDE.md)"
else
  echo "  3. claude (/login), nvim (:Lazy sync), tmux (prefix+I)"
fi
