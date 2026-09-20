#!/usr/bin/env bash
# Install and configure the GNOME extensions this setup relies on.
# Idempotent: installed extensions are only re-enabled and re-configured.
set -euo pipefail

command -v gnome-extensions > /dev/null 2>&1 || {
  echo "  gnome-extensions not found, skipping"
  exit 0
}

SHELL_VER=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"

# Tactile: keyboard window tiling. Space Bar: numbered workspace pills.
# Just Perfection: shell tuning. Others: blur, resource meters, app grid.
EXTENSIONS=(
  tactile@lundal.io
  space-bar@luchrioh
  just-perfection-desktop@just-perfection
  blur-my-shell@aunetx
  Vitals@CoreCoding.com
  undecorate@sun.wxg@gmail.com
  AlphabeticalAppGrid@stuarthayhurst
)

install_ext() {
  local uuid=$1 url tmp
  # Check the directory, not `gnome-extensions list`: the running shell does
  # not report a new extension until it reloads.
  if [[ -d "$EXT_DIR/$uuid" ]]; then
    echo "  $uuid: already installed"
    return 0
  fi
  url=$(curl -fsSL --max-time 20 \
    "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$SHELL_VER" |
    python3 -c 'import sys,json; print(json.load(sys.stdin)["download_url"])' 2> /dev/null) || {
    echo "  $uuid: no build for GNOME $SHELL_VER, skipped"
    return 0
  }
  tmp=$(mktemp -d)
  curl -fsSL --max-time 60 "https://extensions.gnome.org$url" -o "$tmp/e.zip" &&
    gnome-extensions install --force "$tmp/e.zip" &&
    echo "  $uuid: installed"
  rm -rf "$tmp"
}

for uuid in "${EXTENSIONS[@]}"; do
  install_ext "$uuid" || true
done

# Write enabled-extensions directly: `gnome-extensions enable` is a no-op for
# extensions the running shell has not loaded yet (they appear after a reload).
enabled=""
for uuid in "${EXTENSIONS[@]}"; do
  [[ -d "$EXT_DIR/$uuid" ]] || continue
  enabled="$enabled'$uuid', "
  gnome-extensions enable "$uuid" 2> /dev/null || true
done
[[ -n $enabled ]] && gsettings set org.gnome.shell enabled-extensions "[${enabled%, }]"

# Set extension settings against their own schemas (no sudo, no /usr pollution)
ext_set() {
  local uuid=$1 schema=$2
  shift 2
  local dir="$EXT_DIR/$uuid/schemas"
  [[ -d $dir ]] || return 0
  gsettings --schemadir "$dir" set "$schema" "$@" 2> /dev/null || true
}

ext_set tactile@lundal.io org.gnome.shell.extensions.tactile col-0 1
ext_set tactile@lundal.io org.gnome.shell.extensions.tactile col-1 2
ext_set tactile@lundal.io org.gnome.shell.extensions.tactile col-2 1
ext_set tactile@lundal.io org.gnome.shell.extensions.tactile col-3 0
ext_set tactile@lundal.io org.gnome.shell.extensions.tactile row-0 1
ext_set tactile@lundal.io org.gnome.shell.extensions.tactile row-1 1
ext_set tactile@lundal.io org.gnome.shell.extensions.tactile gap-size 32

ext_set just-perfection-desktop@just-perfection org.gnome.shell.extensions.just-perfection animation 2
ext_set just-perfection-desktop@just-perfection org.gnome.shell.extensions.just-perfection dash-app-running true
ext_set just-perfection-desktop@just-perfection org.gnome.shell.extensions.just-perfection workspace true
ext_set just-perfection-desktop@just-perfection org.gnome.shell.extensions.just-perfection workspace-popup false

ext_set space-bar@luchrioh org.gnome.shell.extensions.space-bar.behavior smart-workspace-names false
ext_set space-bar@luchrioh org.gnome.shell.extensions.space-bar.shortcuts enable-activate-workspace-shortcuts false
ext_set space-bar@luchrioh org.gnome.shell.extensions.space-bar.shortcuts enable-move-to-workspace-shortcuts true

ext_set blur-my-shell@aunetx org.gnome.shell.extensions.blur-my-shell.panel blur false
ext_set blur-my-shell@aunetx org.gnome.shell.extensions.blur-my-shell.overview blur true
ext_set blur-my-shell@aunetx org.gnome.shell.extensions.blur-my-shell.lockscreen blur false
ext_set blur-my-shell@aunetx org.gnome.shell.extensions.blur-my-shell.window-list blur false
ext_set blur-my-shell@aunetx org.gnome.shell.extensions.blur-my-shell.appfolder blur false

# Vitals: CPU, memory, and network up/down in the panel (TopHat was dropped -
# it has no GNOME 50 support, upstream issue #204). Pin sensors via hot-sensors;
# temperature ids are hardware-specific, pin them from the Vitals dropdown.
ext_set Vitals@CoreCoding.com org.gnome.shell.extensions.vitals position-in-panel 1
ext_set Vitals@CoreCoding.com org.gnome.shell.extensions.vitals hot-sensors \
  "['_processor_usage_', '_memory_usage_', '__temperature_max__', '__network-rx_max__', '__network-tx_max__']"

ext_set AlphabeticalAppGrid@stuarthayhurst org.gnome.shell.extensions.alphabetical-app-grid folder-order-position end

# Vitals needs GTop for CPU/memory and lm-sensors for temperatures
if [[ -d "$EXT_DIR/Vitals@CoreCoding.com" ]]; then
  dpkg -s gir1.2-gtop-2.0 > /dev/null 2>&1 ||
    echo "  vitals needs GTop: sudo apt install -y gir1.2-gtop-2.0"
  command -v sensors > /dev/null 2>&1 ||
    echo "  vitals temps need lm-sensors: sudo apt install -y lm-sensors"
fi

if [[ ${XDG_SESSION_TYPE:-} == wayland ]]; then
  echo "  configured; log out and back in to load them (Wayland cannot restart the shell)"
else
  echo "  configured; press Alt+F2 then r to reload the shell"
fi
