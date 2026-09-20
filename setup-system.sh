#!/usr/bin/env bash
# Post-install system setup - requires sudo for some steps
# Run AFTER install.sh and package installation
set -euo pipefail

SCRIPT_DIR_EARLY="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/hw-profile.sh
source "$SCRIPT_DIR_EARLY/bin/hw-profile.sh"

if is_wsl; then
  cat << 'MSG'
This is WSL: there is no GNOME session to configure, so this script does
nothing. Windows owns the desktop layer (hotkeys, clipboard, screenshots,
wallpaper). The shell, editor and toolchain come from ./bootstrap.sh and
./install.sh, which do work here.
MSG
  exit 0
fi

# Headless servers and non-GNOME desktops have nothing here to configure
if ! has_gui || ! command -v gsettings > /dev/null 2>&1; then
  echo "No graphical session detected: skipping desktop configuration."
  echo "Shell, editor and toolchain come from ./bootstrap.sh and ./install.sh."
  exit 0
fi

if ! gsettings list-schemas 2> /dev/null | grep -q '^org.gnome.desktop.wm.keybindings$'; then
  echo "GNOME schemas not found (KDE, XFCE or similar): skipping GNOME settings."
  exit 0
fi

echo "=== System Setup ==="
echo ""

# --------------------------------------------------------------------------
# 0) Hack Nerd Font - required by Ghostty config and Starship prompt
# --------------------------------------------------------------------------
echo "[fonts]"

# Check the files as well as the fontconfig cache: a stale cache would
# otherwise trigger a pointless 30MB re-download on every run.
if [[ -d ~/.local/share/fonts/HackNerdFont ]] &&
  compgen -G "$HOME/.local/share/fonts/HackNerdFont/*.ttf" > /dev/null 2>&1; then
  fc-cache -f > /dev/null 2>&1 || true
  echo "  Hack Nerd Font: already installed"
else
  echo "  installing Hack Nerd Font..."
  mkdir -p ~/.local/share/fonts/HackNerdFont
  tmpdir=$(mktemp -d)
  curl -fsSL -o "$tmpdir/Hack.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
  unzip -oq "$tmpdir/Hack.zip" -d ~/.local/share/fonts/HackNerdFont
  rm -rf "$tmpdir"
  fc-cache -f > /dev/null
  echo "  Hack Nerd Font installed"
fi

# --------------------------------------------------------------------------
# 1) Ghostty - wrapper + default terminal
# --------------------------------------------------------------------------
echo "[ghostty]"

# Find the real ghostty binary, ignoring our own /usr/local/bin wrapper
# (apt installs to /usr/bin, snap to /snap/bin).
real_ghostty=""
for cand in /usr/bin/ghostty /snap/bin/ghostty; do
  [[ -x "$cand" ]] && real_ghostty="$cand" && break
done

if [[ -z "$real_ghostty" ]]; then
  echo "  installing ghostty via snap..."
  sudo snap install ghostty --classic
  real_ghostty=/snap/bin/ghostty
else
  echo "  ghostty: found at $real_ghostty"
fi

# A wrapper gives keybindings and update-alternatives a stable path that
# survives snap/alternatives symlink chains. Point it at the real binary.
if [[ -f /usr/local/bin/ghostty ]] && grep -qF "exec $real_ghostty " /usr/local/bin/ghostty 2> /dev/null; then
  echo "  wrapper: already points at $real_ghostty"
else
  echo "  creating /usr/local/bin/ghostty wrapper -> $real_ghostty"
  sudo tee /usr/local/bin/ghostty > /dev/null << WRAPPER
#!/bin/sh
exec $real_ghostty "\$@"
WRAPPER
  sudo chmod +x /usr/local/bin/ghostty
fi

# Register as default terminal (priority 60 beats gnome-terminal's 40)
if update-alternatives --query x-terminal-emulator 2> /dev/null | grep -q "/usr/local/bin/ghostty"; then
  echo "  default terminal: already set"
else
  echo "  registering as default terminal..."
  sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/ghostty 60
fi

# --------------------------------------------------------------------------
# 2) GNOME window management and workspaces
# --------------------------------------------------------------------------
echo "[gnome settings]"

gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6
gsettings set org.gnome.desktop.calendar show-weekdate true
# Ambient light sensor and battery readout exist on laptops only
if is_laptop; then
  gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false
  gsettings set org.gnome.desktop.interface show-battery-percentage true
fi
gsettings set org.gnome.desktop.interface monospace-font-name 'Hack Nerd Font 10'

gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F11']"

# Free Super+N for workspaces: the dock and input-source switcher claim them
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false 2> /dev/null || true
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "@as []"

for n in 1 2 3 4 5 6; do
  gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$n" "['<Super>$n']"
  gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$n" "['<Super><Shift>$n']"
done
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>bracketleft']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>bracketright']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Shift>bracketleft']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Shift>bracketright']"

# Top bar: weekday, date and seconds in the clock
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-show-date true
echo "  6 fixed workspaces on Super+1..6, Super+Shift+N moves window"

# --------------------------------------------------------------------------
# 3) GNOME keybindings - keyboard-first layer (name|command|binding)
# --------------------------------------------------------------------------
echo "[gnome keybindings]"

# The built-in terminal key launches xdg-terminal-exec, ignoring Ghostty;
# clear it (via gsettings so it reaches the layer GNOME reads) and bind
# Ctrl+Alt+T to Ghostty via a custom keybinding below.
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "@as []"
echo "  Ctrl+Alt+T -> Ghostty (direct custom keybinding)"

command -v diodon > /dev/null 2>&1 ||
  echo "  note: diodon not installed (run ./bootstrap.sh)"

KEYBINDS=(
  "Terminal (Ghostty)|/usr/local/bin/ghostty|<Primary><Alt>t"
  "Diodon clipboard|/usr/bin/diodon|<Super>v"
  "Hotkeys overlay|/usr/local/bin/ghostty --title=hotkeys -e $HOME/bin/hotkeys-overlay.sh|<Super>k"
  "Reminder|$HOME/bin/remind.sh|<Super><Control>r"
  "Capture OCR|$HOME/bin/capture.sh ocr|<Super><Control>Print"
  "Capture color|$HOME/bin/capture.sh color|<Super>Print"
  "Capture QR|$HOME/bin/capture.sh qr|<Super><Shift>Print"
  "Toggle night light|$HOME/bin/toggle.sh nightlight|<Super><Control>n"
  "Toggle do not disturb|$HOME/bin/toggle.sh dnd|<Super><Control>comma"
  "Toggle stay awake|$HOME/bin/toggle.sh awake|<Super><Control>i"
  "Download video|$HOME/bin/dl-video.sh|<Super><Control>d"
  "Emoji picker|gnome-characters|<Super><Control>e"
  "WhatsApp|gtk-launch webapp-WhatsApp|<Super><Shift>w"
  "YouTube|gtk-launch webapp-YouTube|<Super><Shift>y"
  "Claude|gtk-launch webapp-Claude|<Super><Shift>c"
  "Maps|gtk-launch webapp-Maps|<Super><Shift>m"
  "X|gtk-launch webapp-X|<Super><Shift>x"
  "Spotify|spotify|<Super><Shift>s"
  "Next wallpaper|$HOME/bin/bg.sh|<Super><Control>space"
  "Claude Code window|/usr/local/bin/ghostty --class=claude --title=Claude -e claude|<Super><Control>a"
  "Solaar (Logitech)|solaar|<Super><Control>l"
)

KB_BASE=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
paths=""
i=0
for entry in "${KEYBINDS[@]}"; do
  IFS='|' read -r kb_name kb_cmd kb_bind <<< "$entry"
  p="$KB_BASE/custom$i/"
  dconf write "${p}name" "'$kb_name'"
  dconf write "${p}command" "'$kb_cmd'"
  dconf write "${p}binding" "'$kb_bind'"
  paths="$paths'$p', "
  i=$((i + 1))
done
dconf write "$KB_BASE" "[${paths%, }]"
echo "  $i custom keybindings set (Super+K lists them all)"

# --------------------------------------------------------------------------
# 4) GNOME extensions - tiling, workspace pills, shell tuning
# --------------------------------------------------------------------------
echo "[gnome extensions]"
"$SCRIPT_DIR_EARLY/bin/gnome-extensions-setup.sh"

# --------------------------------------------------------------------------
# 5) Web apps - chrome --app windows with launchers
# --------------------------------------------------------------------------
echo "[web apps]"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBAPPS=(
  "WhatsApp|https://web.whatsapp.com"
  "YouTube|https://youtube.com"
  "Claude|https://claude.ai"
  "Maps|https://maps.google.com"
  "Photos|https://photos.google.com"
  "X|https://x.com"
)
for entry in "${WEBAPPS[@]}"; do
  IFS='|' read -r wa_name wa_url <<< "$entry"
  if [[ -f "$HOME/.local/share/applications/webapp-$wa_name.desktop" ]]; then
    echo "  $wa_name: already installed"
  else
    "$SCRIPT_DIR/bin/webapp-install.sh" "$wa_name" "$wa_url"
  fi
done

# --------------------------------------------------------------------------
# 6) Wallpapers - Catppuccin Mocha collection for bg.sh cycling
# --------------------------------------------------------------------------
echo "[wallpapers]"
WALLS="$HOME/Pictures/wallpapers"
if compgen -G "$WALLS/*" > /dev/null 2>&1; then
  echo "  wallpapers: $(find "$WALLS" -type f | wc -l) already present"
else
  # Topics land in their own subdirectory; bg.sh cycles all of them
  for spec in "jdm|30" "car night city|20|jdm-night" "retrowave|15" "japan street night|20|japan" "minimal dark|15|minimal"; do
    IFS='|' read -r wq wn wt <<< "$spec"
    "$SCRIPT_DIR_EARLY/bin/wallfetch.sh" "$wq" "$wn" "${wt:-}" || true
  done
fi

# --------------------------------------------------------------------------
# 7) Chrome theme via managed policy - retints a running Chrome, no restart
# --------------------------------------------------------------------------
# Chrome only reloads managed policy live if it is already running; when it is
# not, --refresh-platform-policy starts a process that never returns, so this
# is bounded and its failure is not interesting.
chrome_refresh_policy() {
  if pgrep -x chrome > /dev/null 2>&1; then
    timeout 10 google-chrome --refresh-platform-policy --no-startup-window > /dev/null 2>&1 || true
  fi
}

echo "[chrome theme]"
CHROME_POLICY=/etc/opt/chrome/policies/managed/color.json
CHROME_JSON='{"BrowserThemeColor":"#1e1e2e","BrowserColorScheme":"device"}'
if [[ -f $CHROME_POLICY ]] && grep -q '1e1e2e' "$CHROME_POLICY" 2> /dev/null; then
  echo "  chrome theme: already set"
elif ! command -v google-chrome > /dev/null 2>&1; then
  echo "  skipped: google-chrome not installed"
elif ! sudo -n true 2> /dev/null && [[ ! -t 0 ]]; then
  echo "  skipped: needs sudo, rerun from a terminal"
else
  sudo mkdir -p "$(dirname "$CHROME_POLICY")"
  printf '%s\n' "$CHROME_JSON" | sudo tee "$CHROME_POLICY" > /dev/null
  chrome_refresh_policy
  echo "  Catppuccin Mocha frame applied to Chrome and web apps"
fi

# Force-install the extensions listed in chrome/extensions.txt. Same managed
# policy mechanism as the theme, so a fresh machine gets the browser too.
if command -v google-chrome > /dev/null 2>&1 && [[ -f "$SCRIPT_DIR_EARLY/chrome/extensions.txt" ]]; then
  ext_json=$(grep -oE '^[a-p]{32}' "$SCRIPT_DIR_EARLY/chrome/extensions.txt" |
    sed 's|.*|"&;https://clients2.google.com/service/update2/crx"|' | paste -sd, -)
  if [[ -n $ext_json ]]; then
    if sudo -n true 2> /dev/null || [[ -t 0 ]]; then
      printf '{"ExtensionInstallForcelist":[%s]}\n' "$ext_json" |
        sudo tee /etc/opt/chrome/policies/managed/extensions.json > /dev/null
      chrome_refresh_policy
      echo "  $(grep -c '^[a-p]\{32\}' "$SCRIPT_DIR_EARLY/chrome/extensions.txt") extensions force-installed"
    else
      echo "  extensions: needs sudo, rerun from a terminal"
    fi
  fi
fi

# --------------------------------------------------------------------------
# 8) TUI launchers - btop/lazygit/lazydocker/k9s in the app grid
# --------------------------------------------------------------------------
echo "[tui launchers]"
for entry in "btop|System Monitor|btop" "lazygit|LazyGit|lazygit" \
  "lazydocker|LazyDocker|lazydocker" "k9s|K9s|k9s"; do
  IFS='|' read -r tui_id tui_name tui_cmd <<< "$entry"
  command -v "$tui_cmd" > /dev/null 2>&1 || continue
  cat > "$HOME/.local/share/applications/tui-$tui_id.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=$tui_name
Exec=/usr/local/bin/ghostty --class=tui-$tui_id --title=$tui_name -e $tui_cmd
Icon=utilities-terminal
StartupWMClass=tui-$tui_id
Terminal=false
Categories=System;
DESKTOP
done
update-desktop-database "$HOME/.local/share/applications" 2> /dev/null || true
echo "  launchers written for installed TUIs"

# --------------------------------------------------------------------------
# 9) App grid + cursor theme
# --------------------------------------------------------------------------
echo "[app grid]"
APPS_BASE=/org/gnome/desktop/app-folders
webapp_ids=""
for f in "$HOME"/.local/share/applications/webapp-*.desktop; do
  [[ -e "$f" ]] || continue
  webapp_ids="$webapp_ids'$(basename "$f")', "
done
if [[ -n $webapp_ids ]]; then
  dconf write "$APPS_BASE/folders/WebApps/name" "'Web Apps'"
  dconf write "$APPS_BASE/folders/WebApps/apps" "[${webapp_ids%, }]"
  dconf write "$APPS_BASE/folder-children" "['WebApps', 'Utilities', 'YaST']"
  echo "  Web Apps folder groups $(($(grep -o "', '" <<< "$webapp_ids" | wc -l) + 1)) launchers"
fi

# Qt/Java apps read Xcursor directly and ignore XSETTINGS; this is the X11 fix
# for the pointer reverting to the default theme over some windows.
mkdir -p "$HOME/.icons/default"
cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme | tr -d "'")
cat > "$HOME/.icons/default/index.theme" << CURSOR
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=$cursor_theme
CURSOR
# Xcursor fallback for Qt/Java apps; meaningless under Wayland
if is_x11 && command -v xsetroot > /dev/null 2>&1; then
  xsetroot -cursor_name left_ptr 2> /dev/null || true
fi
echo "  cursor theme pinned to $cursor_theme"

# --------------------------------------------------------------------------
# 10) Compose key - CapsLock for emoji and snippets (~/.XCompose)
# --------------------------------------------------------------------------
echo "[compose key]"
gsettings set org.gnome.desktop.input-sources xkb-options "['compose:caps']"
echo "  CapsLock = Compose (see XCompose: caps m s -> emoji, caps space e -> email)"

# --------------------------------------------------------------------------
# 11) Systemd user services
# --------------------------------------------------------------------------
echo "[systemd]"
systemctl --user daemon-reload
echo "  daemon-reload done"

echo ""
echo "Done!"
echo ""
echo "=== Remaining manual steps ==="
echo "1. Tailscale: curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --ssh"
