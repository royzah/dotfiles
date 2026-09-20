#!/usr/bin/env bash
# toggle.sh dnd|nightlight|awake - GNOME state flips
set -euo pipefail

flip() {
  local cur
  cur=$(gsettings get "$1" "$2")
  if [[ "$cur" == "true" ]]; then gsettings set "$1" "$2" false; else gsettings set "$1" "$2" true; fi
  gsettings get "$1" "$2"
}

case "${1:-}" in
  dnd)
    v=$(flip org.gnome.desktop.notifications show-banners)
    [[ "$v" == "false" ]] && msg="on" || msg="off"
    notify-send "Do Not Disturb" "$msg"
    ;;
  nightlight)
    v=$(flip org.gnome.settings-daemon.plugins.color night-light-enabled)
    notify-send "Night light" "$v"
    ;;
  awake)
    state="$HOME/.local/state/dotfiles/awake"
    if [[ -f "$state" ]]; then
      gsettings set org.gnome.desktop.session idle-delay "$(cat "$state")"
      rm -f "$state"
      notify-send "Stay awake" "off - idle timeout restored"
    else
      mkdir -p "${state%/*}"
      gsettings get org.gnome.desktop.session idle-delay | awk '{print $2}' > "$state"
      gsettings set org.gnome.desktop.session idle-delay 0
      notify-send "Stay awake" "on - screen will not blank"
    fi
    ;;
  *)
    echo "Usage: toggle.sh dnd|nightlight|awake"
    exit 1
    ;;
esac
