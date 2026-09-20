#!/usr/bin/env bash
# gaming-setup.sh - Steam, Lutris, Heroic, GameMode, MangoHud, ProtonUp-Qt.
# Desktop/GUI only. Run gpu-setup.sh first so the driver stack is in place.
set -euo pipefail

# shellcheck source=bin/hw-profile.sh
source "$(dirname "$(readlink -f "$0")")/hw-profile.sh"

if is_wsl || ! has_gui; then
  echo "No graphical session, skipping gaming stack."
  exit 0
fi

echo "=== gaming setup ==="

echo "[apt]"
# steam-installer lives in multiverse, which a fresh install may not enable
sudo add-apt-repository -y multiverse > /dev/null 2>&1 || true
dpkg --print-foreign-architectures | grep -qx i386 || sudo dpkg --add-architecture i386
sudo apt-get update -q
# gamescope gives games their own compositor: fixes scaling and lets you cap
# framerate independently of the desktop. It only exists on 24.04 and newer,
# so it is installed only where available.
apt_install_available steam-installer lutris gamemode mangohud gamescope \
  flatpak libgamemode0 libgamemode0:i386 mangohud:i386

echo "[flatpak]"
if command -v flatpak > /dev/null 2>&1; then
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install -y --noninteractive flathub \
    com.heroicgameslauncher.hgl \
    net.davidotek.pupgui2 || echo "  some flatpaks failed, rerun to retry"
  # The XDG_DATA_DIRS notice above is expected on a first install: the flatpak
  # env generator only re-runs when the systemd user instance restarts, so a
  # logout is not enough - reboot and the apps land in the app grid.
  echo "  note: reboot for Heroic/ProtonUp-Qt to appear in the app grid"
else
  echo "  flatpak unavailable on this release, skipped (Heroic, ProtonUp-Qt)"
fi

echo "[mangohud]"
mkdir -p "$HOME/.config/MangoHud"
if [[ -f "$HOME/.config/MangoHud/MangoHud.conf" ]]; then
  echo "  config: already present"
else
  cat > "$HOME/.config/MangoHud/MangoHud.conf" << 'CONF'
# Toggle with Shift_R+F12, cycle position with Shift_R+F11
fps
frametime
frame_timing=1
gpu_stats
gpu_temp
gpu_power
cpu_stats
cpu_temp
ram
vram
vulkan_driver
position=top-left
font_size=20
background_alpha=0.4
toggle_hud=Shift_R+F12
CONF
  echo "  wrote MangoHud.conf"
fi

echo "[gamemode]"
# gamemoderun needs the user in the gamemode group to renice
sudo usermod -aG gamemode "$USER" 2> /dev/null || true
systemctl --user enable --now gamemoded.service 2> /dev/null || true
echo "  gamemoded enabled"

echo
echo "Done. Usage:"
echo "  gm <command>            run with GameMode"
echo "  gmhud <command>         GameMode + MangoHud overlay"
echo "  Steam launch options:   gamemoderun mangohud %command%"
if is_hybrid_graphics && has_nvidia; then
  echo "  Hybrid laptop:          prime-run gamemoderun mangohud %command%"
fi
echo "  ProtonUp-Qt manages Proton-GE builds for Steam and Heroic"
