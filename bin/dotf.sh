#!/usr/bin/env bash
# dotf - one verb for the whole toolbox (dotf update, dotf lint, ...)
# Named dotf, not dot: /usr/bin/dot belongs to graphviz
exec just -f "$HOME/Code/dotfiles/justfile" -d "$HOME/Code/dotfiles" "$@"
