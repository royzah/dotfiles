#!/usr/bin/env bash
# PreToolUse hook - block Write/Edit on secret-bearing files (exit 2 = block)
set -euo pipefail

# Fail closed: without jq the target path is unknown
if ! command -v jq > /dev/null 2>&1; then
  echo "Blocked: jq not found, cannot check the target path." >&2
  exit 2
fi

file=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file" ]] && exit 0

case "${file##*/}" in
  .env | .env.* | *.env | *.pem | *.key | id_rsa* | id_ed25519* | credentials.json | .credentials.json)
    echo "Blocked: $file looks like a secrets file - edit it manually if intended." >&2
    exit 2
    ;;
esac
exit 0
