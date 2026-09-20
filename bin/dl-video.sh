#!/usr/bin/env bash
# dl-video.sh - yt-dlp the URL currently in the clipboard to ~/Videos
set -euo pipefail

# shellcheck source=bin/hw-profile.sh
source "$(dirname "$(readlink -f "$0")")/hw-profile.sh"

url=$(clip_paste)
notify-send "yt-dlp" "Downloading: $url"
if yt-dlp -P "$HOME/Videos" "$url"; then
  notify-send "yt-dlp" "Done: $url"
else
  notify-send -u critical "yt-dlp" "Failed: $url"
fi
