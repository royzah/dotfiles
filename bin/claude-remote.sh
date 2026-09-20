#!/usr/bin/env bash
# Start Claude Code with Remote Control enabled
# Connect from your phone at claude.ai/code or scan the QR code

set -euo pipefail

SESSION_NAME="${1:-dev-session}"

echo "Starting Claude Code Remote Control (session: $SESSION_NAME)..."
echo "Connect from claude.ai/code or scan the QR code with the Claude app."
echo ""

exec "$HOME/.local/bin/claude" remote-control --name "$SESSION_NAME"
