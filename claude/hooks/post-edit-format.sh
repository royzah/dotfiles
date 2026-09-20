#!/usr/bin/env bash
# PostToolUse hook - auto-format the file Claude just wrote/edited

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[[ -f "$file" ]] || exit 0

case "$file" in
  *.lua) command -v stylua > /dev/null 2>&1 && stylua "$file" 2> /dev/null ;;
  *.nix) command -v alejandra > /dev/null 2>&1 && alejandra -q "$file" 2> /dev/null ;;
  *.sh | *.bash) command -v shfmt > /dev/null 2>&1 && shfmt -w "$file" 2> /dev/null ;;
  *.go) command -v gofmt > /dev/null 2>&1 && gofmt -w "$file" 2> /dev/null ;;
esac
exit 0
