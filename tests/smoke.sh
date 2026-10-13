#!/usr/bin/env bash
# Smoke test of the no-sudo path, as on a shared build server: in a fresh Ubuntu
# container, as a non-root user, run bootstrap-user.sh twice, install.sh twice,
# then bin/doctor.sh. Reruns must succeed without redoing work, the second
# install.sh must leave HOME unchanged, and doctor must report no failures.
#   tests/smoke.sh [personal|work]
set -euo pipefail

IMAGE="${SMOKE_IMAGE:-ubuntu:24.04}"
USER_NAME=smoke

if [[ ${1:-} != --inner ]]; then
  profile="${1:-personal}"
  [[ $profile == personal || $profile == work ]] || {
    echo "usage: $0 [personal|work]" >&2
    exit 2
  }
  repo="$(cd "$(dirname "$0")/.." && pwd)"
  # mise resolves "latest" through the GitHub API; a token avoids the rate limit
  exec docker run --rm -e MISE_GITHUB_TOKEN -e SMOKE_PROFILE="$profile" \
    -v "$repo":/dotfiles:ro "$IMAGE" bash /dotfiles/tests/smoke.sh --inner
fi

# Only what bootstrap-user.sh lists as prerequisites; everything else it installs
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null
apt-get install -y -qq --no-install-recommends git curl ca-certificates xz-utils > /dev/null

useradd -m -s /bin/bash "$USER_NAME"
home="/home/$USER_NAME"
src=/src/dotfiles
# install.sh chmods files in the repo, so it needs a writable copy
mkdir -p /src
cp -a /dotfiles "$src"
chown -R "$USER_NAME:$USER_NAME" /src

as_user() { runuser -u "$USER_NAME" -- env HOME="$home" bash -c "$1"; }

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run() {
  local name="$1" cmd="$2"
  echo "--- $name"
  as_user "$cmd" > "/tmp/$name.log" 2>&1 || {
    cat "/tmp/$name.log"
    fail "$name exited non-zero"
  }
}

# Pre-existing real files exercise the backup path on the first install
as_user 'echo "# old zshrc" > ~/.zshrc; printf "[user]\n\tname = Old\n" > ~/.gitconfig'

flag=""
[[ $SMOKE_PROFILE == work ]] && flag="--work"
run bootstrap1 "$src/bootstrap-user.sh $flag"
run bootstrap2 "$src/bootstrap-user.sh"
if grep -E 'installed:|now enters zsh' /tmp/bootstrap2.log; then
  fail "second bootstrap redid work"
fi
[[ $(grep -c '# dotfiles: enter zsh' "$home/.bashrc") -eq 1 ]] || fail "HOME/.bashrc hook not added exactly once"

# Tool installs are not config: hash only what install.sh owns
manifest() {
  as_user 'cd ~ && find . \( -path ./.local/share -o -path ./.oh-my-zsh -o -path ./.tmux/plugins \
    -o -path ./.cache -o -path ./.local/state \) -prune -o -printf "%p %y %l %m\n" | sort'
}

run install1 "$src/install.sh"
before="$(manifest)"
run install2 "$src/install.sh"
after="$(manifest)"

if [[ "$before" != "$after" ]]; then
  diff <(echo "$before") <(echo "$after") || true
  fail "second install changed HOME"
fi
if grep -E '^\s*(backup|wrote|appended):' /tmp/install2.log; then
  fail "second install backed up or rewrote files"
fi
if grep -iE 'error|no such file|permission denied|command not found' /tmp/install2.log; then
  fail "second install printed errors"
fi

# The first install must have kept the user's originals and installed the stub
as_user 'grep -q "old zshrc" ~/.zshrc.bak && grep -q "name = Old" ~/.gitconfig.bak' ||
  fail "originals not backed up"
includes="$(as_user 'git config -f ~/.gitconfig --get-all include.path')"
grep -qxF "$src/gitconfig" <<< "$includes" || fail "HOME/.gitconfig does not include the repo config"
as_user '[[ -L ~/.zshrc && ! -L ~/.gitconfig && ! -L ~/.claude/settings.json ]]' ||
  fail "unexpected symlink layout"

# doctor runs with what a login shell would have on PATH
run doctor "PATH=\$HOME/.local/bin:\$HOME/.local/share/mise/shims:\$PATH $src/bin/doctor.sh"
cat /tmp/doctor.log

echo "PASS: bootstrap-user.sh + install.sh ($SMOKE_PROFILE) are idempotent; doctor is clean"
