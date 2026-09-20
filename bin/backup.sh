#!/usr/bin/env bash
# backup.sh [init|run|snapshots|restore|check] - restic backup of the data
# that is not in git.
#
# Set these in ~/.secrets.env (never committed). For Backblaze B2:
#   export RESTIC_REPOSITORY="b2:BUCKET:restic"
#   export RESTIC_PASSWORD="a-long-passphrase"      # or RESTIC_PASSWORD_FILE
#   export B2_ACCOUNT_ID="keyID from the application key"
#   export B2_ACCOUNT_KEY="applicationKey"
# Local or SFTP work too: /mnt/backup/restic, sftp:user@host:/path
set -euo pipefail

# systemd user services get a minimal PATH that misses brew and ~/.local/bin,
# so resolve those here rather than depending on the caller's environment.
export PATH="/home/linuxbrew/.linuxbrew/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# shellcheck source=/dev/null
[[ -f "$HOME/.secrets.env" ]] && source "$HOME/.secrets.env"

command -v restic > /dev/null 2>&1 || {
  echo "restic not found on PATH" >&2
  exit 1
}

if [[ -z ${RESTIC_REPOSITORY:-} ]]; then
  cat << 'MSG'
No RESTIC_REPOSITORY set. Add to ~/.secrets.env, for example Backblaze B2:

  export RESTIC_REPOSITORY="b2:my-bucket:restic"
  export RESTIC_PASSWORD="a-long-passphrase"
  export B2_ACCOUNT_ID="keyID"
  export B2_ACCOUNT_KEY="applicationKey"

Then: backup.sh init && backup.sh run
Other targets: /mnt/backup/restic, sftp:user@host:/path, s3:endpoint/bucket
MSG
  exit 1
fi

# What to back up: the things that exist nowhere else. ~/Code is deliberately
# absent because it is 90G of mostly build output, not because git already has
# it: an audit found unpushed commits in 36 repos and four whose remotes no
# longer answer. Use bin/code-migrate.sh for that tree.
INCLUDE=(
  "$HOME/Documents"
  "$HOME/Pictures"
  "$HOME/.ssh"
  "$HOME/.kube"
  "$HOME/.aws"
  "$HOME/.secrets.env"
  "$HOME/.zsh_history"
)

EXCLUDE=(
  --exclude "**/node_modules" --exclude "**/target" --exclude "**/.venv"
  --exclude "**/__pycache__" --exclude "**/result" --exclude "**/.direnv"
  --exclude "**/dist" --exclude "**/build" --exclude "**/.next"
  --exclude "**/*.iso" --exclude "**/*.img" --exclude-caches
  --exclude "$HOME/Pictures/wallpapers"
)

# A repo on the same disk as the data is not a backup; say so once.
if [[ $RESTIC_REPOSITORY != *:* && -e $RESTIC_REPOSITORY ]]; then
  if [[ $(stat -c %d "$RESTIC_REPOSITORY" 2> /dev/null) == $(stat -c %d "$HOME" 2> /dev/null) ]]; then
    echo "warning: the repository is on the same filesystem as \$HOME" >&2
  fi
fi

case "${1:-run}" in
  init) restic init ;;
  run)
    paths=()
    for p in "${INCLUDE[@]}"; do [[ -e $p ]] && paths+=("$p"); done
    restic backup "${paths[@]}" "${EXCLUDE[@]}" --tag auto
    restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
    ;;
  snapshots) restic snapshots ;;
  check) restic check ;;
  restore)
    target="${2:?Usage: backup.sh restore <target-dir> [snapshot]}"
    restic restore "${3:-latest}" --target "$target"
    ;;
  *)
    echo "Usage: backup.sh init|run|snapshots|check|restore <dir>"
    exit 1
    ;;
esac
