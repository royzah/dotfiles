#!/usr/bin/env bash
# shellcheck disable=SC2088 # "~/..." in messages is display text, not a path
# Report-only: does this machine still match what install.sh and
# setup-system.sh set up? Changes nothing. Exits 1 if any check FAILs.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=bin/hw-profile.sh
source "$DOTFILES/bin/hw-profile.sh"

fails=0 warns=0
ok() { printf '  ok    %s\n' "$1"; }
warn() {
  printf '  WARN  %s\n        fix: %s\n' "$1" "$2"
  warns=$((warns + 1))
}
fail() {
  printf '  FAIL  %s\n        fix: %s\n' "$1" "$2"
  fails=$((fails + 1))
}

# Links install.sh skips on this machine (mirrors its if-blocks)
link_gated() {
  case $1 in
    ghostty/* | vscode/*) is_wsl ;;
    environment.d/*) ! has_gui ;;
    claude/*) is_work ;;
    *) return 1 ;;
  esac
}

echo "[links]"
links=$(sed -nE 's/^[[:space:]]*link ([^ "$]+) (~[^ ]+)$/\1 \2/p' "$DOTFILES/install.sh")
for script in "$DOTFILES"/bin/*.sh; do
  links+=$'\n'"bin/${script##*/} ~/bin/${script##*/}"
done
bad=0
while read -r src dst; do
  [[ -n $src ]] || continue
  link_gated "$src" && continue
  dst="$HOME/${dst#\~/}"
  if [[ ! -L $dst ]]; then
    fail "$dst is not a symlink" "just install"
    bad=1
  elif [[ $(readlink -f "$dst") != "$(readlink -f "$DOTFILES/$src")" ]]; then
    fail "$dst points to $(readlink "$dst"), not $DOTFILES/$src" "just install"
    bad=1
  fi
done <<< "$links"
[[ $bad -eq 1 ]] || ok "$(grep -c . <<< "$links") symlinks point into the repo (gated ones skipped)"

echo "[git]"
if [[ -L ~/.gitconfig ]]; then
  fail "~/.gitconfig is a symlink; gh/glab would write credentials into the repo" "just install"
elif [[ ! -f ~/.gitconfig ]]; then
  fail "~/.gitconfig missing" "just install"
else
  paths=$(git config -f ~/.gitconfig --get-all include.path 2> /dev/null) || paths=""
  if grep -qxF "$DOTFILES/gitconfig" <<< "$paths"; then
    ok "~/.gitconfig is a local file including the repo gitconfig"
  else
    fail "~/.gitconfig does not include $DOTFILES/gitconfig" "just install"
  fi
fi
if [[ -f ~/.gitconfig.local ]]; then
  ok "~/.gitconfig.local exists"
else
  warn "~/.gitconfig.local missing (identity, credential helpers)" "create it; see WINDOWS_GUIDE.md"
fi
hooks=$(git -C "$DOTFILES" config --get core.hooksPath 2> /dev/null) || hooks=""
if [[ $hooks == .githooks ]]; then
  ok "repo core.hooksPath = .githooks"
else
  fail "repo core.hooksPath is '${hooks:-unset}', not .githooks (leak guard off)" "just install"
fi

echo "[claude]"
if is_work; then
  ok "skipped on a work machine"
else
  f=~/.claude/settings.json
  if [[ -L $f ]]; then
    fail "$f is a symlink; Claude would write runtime state into the repo" "just install"
  elif ! jq empty "$f" 2> /dev/null; then
    fail "$f missing or not valid JSON" "just install"
  else
    # Every leaf the repo sets must hold the repo's value locally
    drift=$(jq -rn --slurpfile base "$DOTFILES/claude/settings.json" --slurpfile cur "$f" '
      $base[0] | paths(scalars or (type == "array")) as $p
      | select(($cur[0] | getpath($p)) != ($base[0] | getpath($p)))
      | $p | map(tostring) | join(".")')
    if [[ -z $drift ]]; then
      ok "$f is a real file carrying every repo setting"
    else
      fail "$f differs from the repo at: ${drift//$'\n'/, }" "just install"
    fi
  fi
fi

echo "[systemd]"
if ! has_desktop; then
  ok "skipped: setup-system.sh only enables units on a desktop"
else
  units=(tmux-main.service)
  if [[ -f ~/.secrets.env ]] && grep -q RESTIC_REPOSITORY ~/.secrets.env; then units+=(backup.timer); fi
  is_work || units+=(claude-remote.service)
  for u in "${units[@]}"; do
    if [[ ! -f ~/.config/systemd/user/$u ]]; then
      fail "$u not installed" "just install"
    elif [[ $(systemctl --user is-enabled "$u" 2> /dev/null) != enabled ]]; then
      if [[ $u == claude-remote.service ]]; then
        warn "$u not enabled (needs claude login + repo trusted first)" "just system"
      else
        fail "$u not enabled" "just system"
      fi
    elif ! systemctl --user is-active --quiet "$u"; then
      warn "$u enabled but not active" "systemctl --user status $u"
    else
      ok "$u enabled and active"
    fi
  done
fi

echo "[mise]"
if ! command -v mise > /dev/null; then
  fail "mise not installed" "./bootstrap.sh"
else
  missing=$(mise ls --missing -C "$DOTFILES" 2> /dev/null) || missing=""
  if [[ -z $missing ]]; then
    ok "every tool in mise.toml is installed"
  else
    fail "missing: $(awk '{print $1 "@" $2}' <<< "$missing" | paste -sd ' ')" "mise -C $DOTFILES install"
  fi
fi

echo "[leftovers]"
if compgen -G "$HOME/.cache/p10k-*" > /dev/null; then
  warn "stale powerlevel10k cache (prompt is starship)" "rm -rf ~/.cache/p10k-*"
else
  ok "no stale p10k cache"
fi

echo "[repo]"
dirty=$(git -C "$DOTFILES" status --porcelain -- claude/settings.json gitconfig)
if [[ -z $dirty ]]; then
  ok "no uncommitted changes to claude/settings.json or gitconfig"
else
  warn "uncommitted changes in: $(awk '{print $2}' <<< "$dirty" | paste -sd ' ') (runtime state written through a link?)" "git -C $DOTFILES diff"
fi

echo ""
echo "$fails failed, $warns warnings"
[[ $fails -eq 0 ]]
