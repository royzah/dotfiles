#!/usr/bin/env bash
# gpu-setup.sh - graphics stack for whatever GPUs this machine has.
#
# Installs the right driver and Vulkan/VA-API stack per vendor, enables 32-bit
# libraries for Steam and Proton, and writes the session environment. Safe to
# run anywhere: vendors that are not present are skipped.
set -euo pipefail

# shellcheck source=bin/hw-profile.sh
source "$(dirname "$(readlink -f "$0")")/hw-profile.sh"

# 580 is the LTS/production branch on Ubuntu 26.04; 590 and 595 are newer
# feature branches. Override: NVIDIA_BRANCH=595 ./bin/gpu-setup.sh
NVIDIA_BRANCH="${NVIDIA_BRANCH:-580}"
ENVD="$HOME/.config/environment.d"

if [[ -z $(gpu_vendors) ]]; then
  if ! command -v lspci > /dev/null 2>&1; then
    echo "lspci is missing, so GPUs cannot be detected: sudo apt install pciutils"
    exit 1
  fi
  echo "No GPU detected (headless or a VM), nothing to do."
  exit 0
fi

echo "=== gpu setup ==="
echo "detected: $(gpu_vendors | paste -sd+ -)$(is_hybrid_graphics && echo " (hybrid, primary: $(primary_gpu))")"

# 32-bit userspace is what Steam and older Proton titles need
enable_i386() {
  dpkg --print-foreign-architectures | grep -qx i386 && return 0
  echo "  enabling i386 architecture"
  sudo dpkg --add-architecture i386
  sudo apt-get update -q
}

# --------------------------------------------------------------------------
setup_nvidia() {
  echo "[nvidia]"
  if command -v nvidia-smi > /dev/null 2>&1 && nvidia-smi > /dev/null 2>&1; then
    echo "  driver running: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)"
  else
    enable_i386
    apt_install_available "nvidia-driver-$NVIDIA_BRANCH" \
      "libnvidia-gl-$NVIDIA_BRANCH:i386" \
      nvidia-vaapi-driver
    echo "  installed nvidia-driver-$NVIDIA_BRANCH (reboot required)"
  fi

  # modeset is the default on recent branches; explicit keeps Wayland working
  # if a future driver flips it back. PreserveVideoMemoryAllocations stops
  # sessions coming back corrupted after suspend.
  sudo tee /etc/modprobe.d/nvidia-wayland.conf > /dev/null << 'CONF'
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
CONF
  if command -v update-initramfs > /dev/null 2>&1; then
    sudo update-initramfs -u > /dev/null 2>&1 || true
  fi

  local svc
  for svc in nvidia-suspend nvidia-resume nvidia-hibernate; do
    sudo systemctl enable "$svc.service" > /dev/null 2>&1 || true
  done

  # On a hybrid machine the iGPU drives the desktop, so forcing the NVIDIA GBM
  # backend session-wide would break it. Offload per game instead.
  if is_hybrid_graphics; then
    cat > "$ENVD/50-gpu-nvidia.conf" << 'CONF'
# Hybrid graphics: the integrated GPU drives the desktop. Run a single
# program on the NVIDIA card with: prime-run <command>
__NV_PRIME_RENDER_OFFLOAD=1
__VK_LAYER_NV_optimus=NVIDIA_only
CONF
    echo "  hybrid: use prime-run <command> for offload"
  else
    cat > "$ENVD/50-gpu-nvidia.conf" << 'CONF'
LIBVA_DRIVER_NAME=nvidia
NVD_BACKEND=direct
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
CONF
  fi
  echo "  wrote $ENVD/50-gpu-nvidia.conf"
}

# --------------------------------------------------------------------------
setup_amd() {
  echo "[amd]"
  enable_i386
  # RADV is the Mesa Vulkan driver; the :i386 halves are for 32-bit games
  apt_install_available mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
    libgl1-mesa-dri libgl1-mesa-dri:i386 \
    mesa-va-drivers mesa-vdpau-drivers libdrm-amdgpu1 vulkan-tools
  if ! is_hybrid_graphics; then
    cat > "$ENVD/50-gpu-amd.conf" << 'CONF'
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi
# RADV is faster than AMDVLK for most titles and is what Valve ships against
AMD_VULKAN_ICD=RADV
CONF
    echo "  wrote $ENVD/50-gpu-amd.conf"
  fi
  echo "  mesa/RADV installed"
}

# --------------------------------------------------------------------------
setup_intel() {
  echo "[intel]"
  enable_i386
  apt_install_available mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
    libgl1-mesa-dri libgl1-mesa-dri:i386 \
    intel-media-va-driver-non-free vulkan-tools
  if ! is_hybrid_graphics; then
    cat > "$ENVD/50-gpu-intel.conf" << 'CONF'
LIBVA_DRIVER_NAME=iHD
CONF
    echo "  wrote $ENVD/50-gpu-intel.conf"
  fi
  echo "  mesa + iHD media driver installed"
}

# --------------------------------------------------------------------------
mkdir -p "$ENVD"
# Stale per-vendor files would fight the current hardware
rm -f "$ENVD"/50-gpu-*.conf

while read -r vendor; do
  case "$vendor" in
    nvidia) setup_nvidia ;;
    amd) setup_amd ;;
    intel) setup_intel ;;
  esac
done < <(gpu_vendors)

echo
echo "Done. After a reboot, verify with:"
echo "  vulkaninfo --summary | head"
echo "  vainfo                      # hardware video decode"
has_nvidia && echo "  nvidia-smi"
is_hybrid_graphics && echo "  prime-run vulkaninfo --summary   # dGPU offload"
exit 0
