#!/usr/bin/env bash
# Idempotency smoke test: install.sh run twice in a fresh Ubuntu container as a
# non-root user must leave HOME unchanged on the second run. bootstrap*.sh is not
# covered (network-heavy installers).
set -euo pipefail

IMAGE="${SMOKE_IMAGE:-ubuntu:24.04}"
USER_NAME=smoke

if [[ ${1:-} != --inner ]]; then
  repo="$(cd "$(dirname "$0")/.." && pwd)"
  exec docker run --rm -v "$repo":/dotfiles:ro "$IMAGE" bash /dotfiles/tests/smoke.sh --inner
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null
apt-get install -y -qq --no-install-recommends git jq ca-certificates > /dev/null

useradd -m -s /bin/bash "$USER_NAME"
home="/home/$USER_NAME"
src=/src/dotfiles
# install.sh chmods files in the repo, so it needs a writable copy
mkdir -p /src
cp -a /dotfiles "$src"
chown -R "$USER_NAME:$USER_NAME" /src

as_user() { runuser -u "$USER_NAME" -- env HOME="$home" bash -c "$1"; }

# Pre-existing real files exercise the backup path on the first run
as_user 'echo "# old zshrc" > ~/.zshrc; printf "[user]\n\tname = Old\n" > ~/.gitconfig'

manifest() {
  as_user 'cd ~ && find . -printf "%p %y %l %m\n" | sort
    find . -type f -print0 | sort -z | xargs -0 -r sha256sum'
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

echo "--- run 1"
as_user "$src/install.sh" > /tmp/run1.log 2>&1 || {
  cat /tmp/run1.log
  fail "first run exited non-zero"
}
before="$(manifest)"

echo "--- run 2"
as_user "$src/install.sh" > /tmp/run2.log 2>&1 || {
  cat /tmp/run2.log
  fail "second run exited non-zero"
}
after="$(manifest)"

if [[ "$before" != "$after" ]]; then
  diff <(echo "$before") <(echo "$after") || true
  fail "second run changed HOME"
fi

run2="$(< /tmp/run2.log)"
if grep -E '^\s*(backup|wrote|appended):' <<< "$run2"; then
  fail "second run backed up or rewrote files"
fi
if grep -iE 'error|no such file|permission denied|command not found' <<< "$run2"; then
  fail "second run printed errors"
fi

# The first run must have kept the user's originals and installed the stub
as_user 'grep -q "old zshrc" ~/.zshrc.bak && grep -q "name = Old" ~/.gitconfig.bak' ||
  fail "originals not backed up"
includes="$(as_user 'git config -f ~/.gitconfig --get-all include.path')"
grep -qxF "$src/gitconfig" <<< "$includes" || fail "HOME/.gitconfig does not include the repo config"
as_user '[[ -L ~/.zshrc && ! -L ~/.gitconfig && ! -L ~/.claude/settings.json ]]' ||
  fail "unexpected symlink layout"

echo "PASS: install.sh is idempotent"
