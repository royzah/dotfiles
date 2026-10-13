# Embedded: serial consoles, device copy/sync, debugging, flashing

# --- Serial Communication (minicom) ---
# Needs the dialout group, not sudo, so minicom reads ~/.minirc.dfl
alias mcom='minicom -c on -b 115200 -D'
mcomusb() { minicom -c on -D "/dev/ttyUSB${1:-0}" -b 115200 }
mcomacm() { minicom -c on -D "/dev/ttyACM${1:-0}" -b 115200 }
alias lsserial='ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "No serial devices"'

# fzf serial picker
serial() {
  local port
  port=$(ls /dev/ttyUSB* /dev/ttyACM* /dev/ttyS* 2>/dev/null | fzf --prompt="Serial port> " --height=10)
  [[ -z "$port" ]] && return
  local baud="${1:-115200}"
  echo "Connecting to $port @ ${baud}baud (Ctrl-A X to quit)"
  minicom -c on -D "$port" -b "$baud"
}

# Copy file to/from device over SSH
todev()   { scp "$2" "$1" }
fromdev() { scp "$1" "$2" }

# --- Debugging ---
strace-pid() {
  [[ -z "$1" ]] && { echo "Usage: strace-pid <pid>"; return 1 }
  strace -f -e trace=network,write,read -p "$1" 2>&1 | bat --language=strace --style=plain
}

# Continuous rsync to a device on file change
watchsync() {
  local src="${1:?Usage: watchsync <dir> <user@host:path>}" dst="${2:?Usage: watchsync <dir> <user@host:path>}"
  command -v inotifywait >/dev/null 2>&1 || { echo "Missing inotify-tools"; return 1 }
  while inotifywait -r -e modify,create,delete,move "$src" >/dev/null 2>&1; do
    rsync -az --delete "$src"/ "$dst" && echo "synced $(date +%T)"
  done
}

# Write an iso to a block device: iso2sd file.iso /dev/sdX
iso2sd() {
  local src="${1:?Usage: iso2sd <file.iso> <device>}" dev="${2:?Usage: iso2sd <file.iso> <device>}"
  [[ -b "$dev" ]] || { echo "$dev is not a block device"; return 1 }
  lsblk -o NAME,SIZE,MODEL "$dev" || return 1
  read -q "REPLY?Write $src to $dev, erasing it? [y/N] " || { echo; return 1 }
  echo
  sudo dd bs=4M status=progress oflag=sync if="$src" of="$dev" && sudo eject "$dev"
}
