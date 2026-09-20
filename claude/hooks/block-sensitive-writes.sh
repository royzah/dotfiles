#!/usr/bin/env bash
# PreToolUse hook - block Write/Edit on secret-bearing files (exit 2 = block)

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[[ -z "$file" ]] && exit 0

case "${file##*/}" in
  .env | .env.* | *.env | *.pem | *.key | id_rsa* | id_ed25519* | credentials.json | .credentials.json)
    echo "Blocked: $file looks like a secrets file - edit it manually if intended." >&2
    exit 2
    ;;
esac
exit 0
