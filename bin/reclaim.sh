#!/usr/bin/env bash
# reclaim.sh [--yes] [--aggressive] - report and reclaim developer disk junk
#
# Default is a dry run: it measures every cache and prints what it would free.
# --yes actually deletes. --aggressive also drops things that cost rebuild
# time (docker images in use by nothing, all nix generations, brew downloads).
# Project build dirs (node_modules, target, .venv, dist, ...) are only touched
# when untouched for 30 days; change with --days=N, or --days=0 for all.
set -euo pipefail

APPLY=false
AGGRESSIVE=false
DAYS=30
for a in "$@"; do
  case "$a" in
    --yes | -y) APPLY=true ;;
    --aggressive | -a) AGGRESSIVE=true ;;
    --days=*) DAYS="${a#*=}" ;;
    -h | --help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "unknown option: $a"
      exit 1
      ;;
  esac
done

total=0
have() { command -v "$1" > /dev/null 2>&1; }

# size <path...> - total bytes of the paths that exist
size() {
  local b=0 p
  for p in "$@"; do
    [[ -e $p ]] || continue
    b=$((b + $(du -sb "$p" 2> /dev/null | cut -f1)))
  done
  echo "$b"
}

human() { numfmt --to=iec --suffix=B "${1:-0}" 2> /dev/null || echo "${1}B"; }

# report <label> <bytes> <command...>
report() {
  local label=$1 bytes=$2
  shift 2
  ((bytes > 0)) || return 0
  total=$((total + bytes))
  printf '  %-22s %8s' "$label" "$(human "$bytes")"
  if $APPLY; then
    if "$@" > /dev/null 2>&1; then echo "  cleaned"; else echo "  FAILED"; fi
  else
    echo
  fi
}

echo "=== reclaim ==="
$APPLY || echo "(dry run - pass --yes to actually delete)"
echo

echo "package managers"
have apt-get && report "apt archives" "$(size /var/cache/apt/archives)" sudo apt-get clean
have brew && report "homebrew cache" "$(size "$HOME/.cache/Homebrew")" brew cleanup --prune=all
have npm && report "npm cache" "$(size "$HOME/.npm/_cacache")" npm cache clean --force
have pip && report "pip cache" "$(size "$HOME/.cache/pip")" pip cache purge
have uv && report "uv cache" "$(size "$HOME/.cache/uv")" uv cache clean

echo
echo "language toolchains"
have cargo && report "cargo registry" \
  "$(size "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src" "$HOME/.cargo/git/checkouts")" \
  rm -rf "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src" "$HOME/.cargo/git/checkouts"
have go && report "go build cache" "$(size "$(go env GOCACHE 2> /dev/null)")" go clean -cache
$AGGRESSIVE && have go &&
  report "go module cache" "$(size "$(go env GOMODCACHE 2> /dev/null)")" go clean -modcache
# shellcheck disable=SC2016  # $HOME must expand in the inner shell, not here
report "python bytecode" \
  "$(find "$HOME" -maxdepth 6 -type d -name __pycache__ -not -path '*/.cache/*' -printf '%s\n' 2> /dev/null | awk '{s+=$1} END {print s+0}')" \
  bash -c 'find "$HOME" -maxdepth 6 -type d -name __pycache__ -not -path "*/.cache/*" -exec rm -rf {} + 2>/dev/null || true'

echo
echo "project build artifacts"
# Directories that any build can recreate. Scanned under the code roots only.
ROOTS=("$HOME/Code" "$HOME/src" "$HOME/Work" "$HOME/projects")
ARTIFACTS=(node_modules target .venv venv __pycache__ .direnv dist build .next .turbo .parcel-cache .pytest_cache .mypy_cache .gradle .tox)

artifact_dirs() {
  local r a
  for r in "${ROOTS[@]}"; do
    [[ -d $r ]] || continue
    for a in "${ARTIFACTS[@]}"; do
      find "$r" -maxdepth 6 -type d -name "$a" -prune 2> /dev/null
    done
  done
}

# Drop any path nested inside another match, or du would count it twice.
# Staleness is judged on the containing project, not the artifact dir itself:
# a node_modules mtime bumps on every install even in an abandoned repo.
mapfile -t art < <(artifact_dirs | sort | awk '
  { p = $0 "/"
    if (prev != "" && index(p, prev) == 1) next
    prev = p; print }' |
  while read -r d; do
    if ((DAYS == 0)); then
      echo "$d"
    else
      proj=$(dirname "$d")
      newest=$(find "$proj" -maxdepth 1 -mindepth 1 \
        -not -name node_modules -not -name target -not -name .venv \
        -not -name dist -not -name build -not -name .next -not -name .direnv \
        -printf '%T@\n' 2> /dev/null | sort -rn | head -1)
      [[ -z $newest ]] && continue
      age=$(((EPOCHSECONDS - ${newest%.*}) / 86400))
      ((age >= DAYS)) && echo "$d"
    fi
  done)
if ((${#art[@]})); then
  abytes=$(du -sbc "${art[@]}" 2> /dev/null | tail -1 | cut -f1)
  # shellcheck disable=SC2016  # expands in the inner shell at run time
  report "build dirs >${DAYS}d (${#art[@]})" "$abytes" \
    bash -c 'printf "%s\0" "$@" | xargs -0 rm -rf' _ "${art[@]}"
  $APPLY || printf '    %s\n' "${art[@]:0:5}" | sed 's|'"$HOME"'|~|'
  ((${#art[@]} > 5)) && ! $APPLY && echo "    ... and $((${#art[@]} - 5)) more"
  # Show what ignoring the age filter would free, so the choice is visible
  if ! $APPLY && ((DAYS > 0)); then
    mapfile -t allart < <(artifact_dirs | sort | awk '
      { p = $0 "/"; if (prev != "" && index(p, prev) == 1) next; prev = p; print }')
    if ((${#allart[@]} > ${#art[@]})); then
      allb=$(du -sbc "${allart[@]}" 2> /dev/null | tail -1 | cut -f1)
      echo "    all ages: ${#allart[@]} dirs, $(human "$allb")  (--days=0)"
    fi
  fi
fi

# Nix per-project build outputs (./result symlinks keep closures alive)
mapfile -t results < <(find "${ROOTS[@]}" -maxdepth 3 -name result -type l 2> /dev/null || true)
((${#results[@]})) && echo "  note: ${#results[@]} ./result symlinks pin nix closures (rm to free)"

echo
echo "containers and nix"
if have docker && docker info > /dev/null 2>&1; then
  d=$(docker system df --format '{{.Reclaimable}}' 2> /dev/null | head -1 | grep -oE '^[0-9.]+[A-Za-z]+' || echo 0B)
  # docker prints "16.16GB"; numfmt wants "16.16G", and rejected input made
  # this silently report 0, so the docker step never ran
  db=$(numfmt --from=iec "${d%B}" 2> /dev/null || echo 0)
  if $AGGRESSIVE; then
    # No --volumes: an unused volume is usually a stopped project's database
    report "docker (unused images)" "$db" docker system prune -af
  else
    report "docker dangling" "$db" docker system prune -f
  fi
fi
if have nix; then
  nb=$(size /nix/store)
  if $AGGRESSIVE; then
    report "nix store (gc all)" "$nb" nix-collect-garbage -d
  else
    report "nix gc (>7d old)" "$nb" nix-collect-garbage --delete-older-than 7d
  fi
fi

echo
echo "system"
have journalctl && report "journald logs" \
  "$(journalctl --disk-usage 2> /dev/null | grep -oE '[0-9.]+[MG]' | head -1 | numfmt --from=iec 2> /dev/null || echo 0)" \
  sudo journalctl --vacuum-size=200M
report "user cache" "$(size "$HOME/.cache/thumbnails" "$HOME/.cache/tracker3")" \
  rm -rf "$HOME/.cache/thumbnails" "$HOME/.cache/tracker3"
report "trash" "$(size "$HOME/.local/share/Trash")" rm -rf "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info"
if have snap; then
  sb=$(snap list --all 2> /dev/null | awk '/disabled/{n++} END {printf "%d", (n+0)*150000000}')
  # shellcheck disable=SC2016  # vars expand in the inner shell
  report "old snap revisions" "$sb" bash -c 'snap list --all | awk "/disabled/{print \$1, \$3}" | while read -r n r; do sudo snap remove "$n" --revision="$r"; done'
fi

echo
if $APPLY; then
  echo "reclaimed up to $(human "$total")"
else
  echo "would free about $(human "$total")  ->  reclaim.sh --yes"
  echo "add --aggressive for go modcache, all docker images, full nix gc"
fi
df -h / | awk 'NR==2 {print "  / now: " $4 " free of " $2}'
