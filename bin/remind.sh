#!/usr/bin/env bash
# remind.sh <minutes> <message> - countdown notification via systemd timer
# No args: zenity prompt. List: systemctl --user list-timers 'run-*'
set -euo pipefail

if [[ $# -eq 0 ]]; then
  input=$(zenity --entry --title=Reminder --text="<minutes> <message>" 2> /dev/null) || exit 0
  # shellcheck disable=SC2086
  set -- $input
fi

min="${1:?Usage: remind.sh <minutes> <message>}"
shift
msg="${*:-Time is up}"
systemd-run --user --quiet --on-active="${min}min" --timer-property=AccuracySec=1s \
  /usr/bin/notify-send -u critical "Reminder" "$msg"
notify-send "Reminder set" "In ${min}m: $msg"
