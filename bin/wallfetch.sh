#!/usr/bin/env bash
# wallfetch.sh <query> [count] [topic] - add wallpapers from wallhaven.cc
#
#   wallfetch.sh jdm 30            -> ~/Pictures/wallpapers/jdm/
#   wallfetch.sh "night city" 20 city
#
# SFW general-category only, 16:9 and at least 1920x1080. Existing files are
# skipped, so rerunning tops a topic up rather than re-downloading it.
set -euo pipefail

query="${1:?Usage: wallfetch.sh <query> [count] [topic]}"
count="${2:-24}"
topic="${3:-$(tr '[:upper:] ' '[:lower:]-' <<< "$query")}"
dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}/$topic"
mkdir -p "$dir"

api="https://wallhaven.cc/api/v1/search"
opts="categories=100&purity=100&atleast=1920x1080&ratios=16x9&sorting=favorites"
[[ -n ${WALLHAVEN_API_KEY:-} ]] && opts="$opts&apikey=$WALLHAVEN_API_KEY"

encoded=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$query")
got=0 page=1

while ((got < count)) && ((page <= 10)); do
  urls=$(curl -fsSL --max-time 30 "$api?q=$encoded&$opts&page=$page" |
    python3 -c 'import sys,json; [print(w["path"]) for w in json.load(sys.stdin).get("data",[])]') || break
  [[ -n $urls ]] || break

  while read -r url; do
    ((got < count)) || break
    f="$dir/${url##*/}"
    [[ -f $f ]] && continue
    curl -fsSL --max-time 45 "$url" -o "$f" || continue
    [[ $(file -b --mime-type "$f") == image/* ]] || {
      rm -f "$f"
      continue
    }
    got=$((got + 1))
  done <<< "$urls"
  page=$((page + 1))
done

echo "$topic: $got new, $(find "$dir" -type f | wc -l) total in $dir"
