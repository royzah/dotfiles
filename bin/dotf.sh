#!/usr/bin/env bash
# dotf - one verb for the whole toolbox (dotf update, dotf lint, ...)
# Named dotf, not dot: /usr/bin/dot belongs to graphviz
set -euo pipefail
# ~/bin/dotf is a symlink into the repo, so the repo is wherever it resolves to
DOTFILES="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
exec just -f "$DOTFILES/justfile" -d "$DOTFILES" "$@"
