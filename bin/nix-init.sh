#!/usr/bin/env bash
# Scaffold a project with flake.nix + .envrc + optional compose.yaml
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES="$DOTFILES/templates"

dir="${1:-.}"

if [[ ! -f "$dir/flake.nix" ]]; then
  cp "$TEMPLATES/flake.nix" "$dir/flake.nix"
  echo "created: $dir/flake.nix"
else
  echo "exists:  $dir/flake.nix"
fi

if [[ ! -f "$dir/.envrc" ]]; then
  cp "$TEMPLATES/envrc" "$dir/.envrc"
  echo "created: $dir/.envrc"
else
  echo "exists:  $dir/.envrc"
fi

echo ""
echo "Next steps:"
echo "  1. Edit flake.nix — uncomment the packages you need"
echo "  2. direnv allow"
echo "  3. Optionally copy compose.yaml: cp $TEMPLATES/compose.yaml $dir/"
