#!/usr/bin/env bash
# bg.sh [next|random] - cycle GNOME wallpaper from ~/Pictures/wallpapers
set -euo pipefail

dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
state="$HOME/.local/state/dotfiles/wallpaper"
mkdir -p "${state%/*}"

mapfile -t imgs < <(find "$dir" -maxdepth 2 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2> /dev/null | sort)
((${#imgs[@]})) || {
  notify-send "Wallpaper" "No images in $dir"
  exit 1
}

case "${1:-next}" in
  random) pick=$((RANDOM % ${#imgs[@]})) ;;
  *)
    cur=$(cat "$state" 2> /dev/null || echo -1)
    pick=$(((cur + 1) % ${#imgs[@]}))
    ;;
esac

img="${imgs[$pick]}"
echo "$pick" > "$state"
gsettings set org.gnome.desktop.background picture-uri "file://$img"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$img"
notify-send "Wallpaper" "$(basename "$img")"
