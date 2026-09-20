#!/usr/bin/env bash
# webapp-install.sh <Name> <URL> [icon-url] - web app as a first-class window
set -euo pipefail

name="${1:?Usage: webapp-install.sh <Name> <URL> [icon-url]}"
url="${2:?Usage: webapp-install.sh <Name> <URL> [icon-url]}"
origin=$(sed -E 's|(https?://[^/]+).*|\1|' <<< "$url")
domain=${origin#*//}
slug=$(tr '[:upper:]' '[:lower:]' <<< "$name" | sed 's/[^[:alnum:]]\+/-/g; s/^-//; s/-$//')

icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
app_dir="$HOME/.local/share/applications"
mkdir -p "$icon_dir" "$app_dir"
icon="$icon_dir/webapp-$slug.png"

# Best icon first: page apple-touch-icon, then origin default, then favicon service
# Accept only real images; normalize anything that is not PNG (webp, ico, jpeg)
fetch_icon() {
  local u=$1 mime
  curl -fsSL --max-time 15 "$u" -o "$icon" 2> /dev/null || return 1
  mime=$(file -b --mime-type "$icon")
  [[ $mime == image/* ]] || return 1
  if [[ $mime != image/png ]]; then
    command -v convert > /dev/null 2>&1 || return 1
    convert "$icon" "png:$icon" 2> /dev/null || return 1
  fi
}

if [[ -n ${3:-} ]]; then
  fetch_icon "$3" || true
else
  touch_icon=$(curl -fsSL --max-time 15 "$url" 2> /dev/null | head -c 100000 |
    grep -oiE '<link[^>]+apple-touch-icon[^>]*>' | grep -oiE 'href="[^"]+"' |
    head -1 | cut -d'"' -f2) || true
  case "$touch_icon" in
    http*) : ;;
    //*) touch_icon="https:$touch_icon" ;;
    /*) touch_icon="$origin$touch_icon" ;;
    *) touch_icon="" ;;
  esac
  { [[ -n $touch_icon ]] && fetch_icon "$touch_icon"; } ||
    fetch_icon "$origin/apple-touch-icon.png" ||
    fetch_icon "https://www.google.com/s2/favicons?domain=$domain&sz=256" ||
    true
fi
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2> /dev/null || true

cat > "$app_dir/webapp-$name.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=$name
Exec=google-chrome --app=$url --class=webapp-$name
Icon=webapp-$slug
StartupWMClass=webapp-$name
Categories=Network;
DESKTOP

update-desktop-database "$app_dir" 2> /dev/null || true
echo "installed: $name -> $url"
