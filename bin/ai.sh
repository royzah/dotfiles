#!/usr/bin/env bash
# The terminal AI for this machine: Copilot where work policy requires it, else Claude
set -euo pipefail

# shellcheck source=bin/hw-profile.sh
source "$(dirname "$(readlink -f "$0")")/hw-profile.sh"

if is_work; then exec copilot "$@"; else exec claude "$@"; fi
