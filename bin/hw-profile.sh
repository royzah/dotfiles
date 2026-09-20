#!/usr/bin/env bash
# hw-profile.sh - hardware and session detection, shared by the setup scripts.
#
#   source bin/hw-profile.sh   -> gives you is_laptop, has_nvidia, is_wayland, ...
#   ./bin/hw-profile.sh        -> prints the detected profile
#
# These dotfiles are shared across laptops, desktops and WSL, so nothing
# hardware-specific runs unconditionally.

is_wsl() { [[ -n ${WSL_DISTRO_NAME:-} ]] || grep -qi microsoft /proc/version 2> /dev/null; }

# A battery is the reliable laptop signal; chassis type is the fallback because
# some desks report "Notebook" for SFF cases and vice versa.
is_laptop() {
  compgen -G '/sys/class/power_supply/BAT*' > /dev/null 2>&1 && return 0
  case "$(cat /sys/devices/virtual/dmi/id/chassis_type 2> /dev/null)" in
    8 | 9 | 10 | 11 | 14) return 0 ;;
    *) return 1 ;;
  esac
}

is_desktop() { ! is_laptop && ! is_wsl; }

# A work machine (marker written by bootstrap-user.sh --work): company AI, no personal Claude
is_work() { [[ -f "$HOME/.config/dotfiles/work" ]]; }

# --------------------------------------------------------------------------
# GPU. A machine can have several (laptops usually pair an iGPU with a dGPU),
# so these are independent predicates rather than one exclusive vendor.
# --------------------------------------------------------------------------
_gpu_lines() { lspci 2> /dev/null | grep -iE 'vga compatible controller|3d controller|display controller'; }

has_nvidia() { _gpu_lines | grep -qi nvidia; }
has_amd_gpu() { _gpu_lines | grep -qiE 'amd|ati|radeon'; }
has_intel_gpu() { _gpu_lines | grep -qi intel; }

# Every GPU vendor present, one per line: nvidia, amd, intel
gpu_vendors() {
  has_nvidia && echo nvidia
  has_amd_gpu && echo amd
  has_intel_gpu && echo intel
  return 0
}

# More than one GPU: needs render offload rather than a single driver stack
is_hybrid_graphics() { [[ $(gpu_vendors | wc -l) -gt 1 ]]; }

# The GPU actually driving the display, which on a hybrid laptop is usually
# the integrated one unless the dGPU is set as primary.
primary_gpu() {
  local drv
  for drv in /sys/class/drm/card*/device/driver; do
    [[ -e $drv ]] || continue
    case "$(basename "$(readlink -f "$drv")")" in
      nvidia)
        echo nvidia
        return 0
        ;;
      amdgpu | radeon)
        echo amd
        return 0
        ;;
      i915 | xe)
        echo intel
        return 0
        ;;
    esac
  done
  gpu_vendors | head -1
}

# --------------------------------------------------------------------------
# CPU
# --------------------------------------------------------------------------
has_amd_cpu() { grep -qi 'AuthenticAMD' /proc/cpuinfo 2> /dev/null; }
has_intel_cpu() { grep -qi 'GenuineIntel' /proc/cpuinfo 2> /dev/null; }

cpu_vendor() {
  if has_amd_cpu; then
    echo amd
  elif has_intel_cpu; then
    echo intel
  else
    echo other
  fi
}

cpu_scaling_driver() { cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2> /dev/null || echo none; }

# Does this CPU expose the energy-performance preference knob?
has_epp() { [[ -e /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; }

is_wayland() { [[ ${XDG_SESSION_TYPE:-} == wayland ]]; }
is_x11() { [[ ${XDG_SESSION_TYPE:-} == x11 ]]; }
has_gui() { is_wayland || is_x11; }

# Serial hardware only matters where it is actually plugged in
has_serial() { compgen -G '/dev/ttyUSB*' > /dev/null 2>&1 || compgen -G '/dev/ttyACM*' > /dev/null 2>&1; }

# --------------------------------------------------------------------------
# Clipboard and screen capture, Wayland-first with an X11 fallback.
# --------------------------------------------------------------------------

clip_copy() {
  if is_wsl && command -v clip.exe > /dev/null 2>&1; then
    clip.exe
  elif command -v wl-copy > /dev/null 2>&1 && is_wayland; then
    wl-copy
  elif command -v xclip > /dev/null 2>&1; then
    xclip -selection clipboard
  elif command -v wl-copy > /dev/null 2>&1; then
    wl-copy
  elif [[ -n ${TMUX:-} ]]; then
    # Headless over SSH: tmux forwards it to the local terminal's clipboard (OSC 52)
    tmux load-buffer -w -
  else
    echo "no clipboard tool (install wl-clipboard)" >&2
    return 1
  fi
}

clip_paste() {
  if is_wsl && command -v powershell.exe > /dev/null 2>&1; then
    powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r'
  elif command -v wl-paste > /dev/null 2>&1 && is_wayland; then
    wl-paste -n
  elif command -v xclip > /dev/null 2>&1; then
    xclip -o -selection clipboard
  elif command -v wl-paste > /dev/null 2>&1; then
    wl-paste -n
  else
    echo "no clipboard tool (install wl-clipboard)" >&2
    return 1
  fi
}

# Open a URL or file in the desktop's handler; on WSL that is Windows
open_url() {
  if is_wsl; then
    if command -v wslview > /dev/null 2>&1; then
      wslview "$1"
    else
      # explorer.exe exits 1 even when it opened the URL
      explorer.exe "$1" || true
    fi
  else
    xdg-open "$1"
  fi
}

# Interactive region grab to stdout as PNG. grim+slurp on Wayland, the GNOME
# portal as a fallback there, flameshot on X11.
screenshot_region() {
  if is_wayland; then
    if command -v grim > /dev/null 2>&1 && command -v slurp > /dev/null 2>&1; then
      grim -g "$(slurp)" - 2> /dev/null
      return
    fi
    # GNOME's own screenshot API works under Wayland without a portal prompt
    local tmp area
    tmp=$(mktemp --suffix=.png) || return 1
    area=$(mktemp) || return 1
    if gdbus call --session --dest org.gnome.Shell.Screenshot \
      --object-path /org/gnome/Shell/Screenshot \
      --method org.gnome.Shell.Screenshot.SelectArea > "$area" 2> /dev/null; then
      # Reply looks like: (100, 200, 640, 480)
      read -r x y w h < <(tr -cd '0-9\n ' < "$area" | tr -s ' ')
      if [[ -n ${h:-} ]]; then
        gdbus call --session --dest org.gnome.Shell.Screenshot \
          --object-path /org/gnome/Shell/Screenshot \
          --method org.gnome.Shell.Screenshot.ScreenshotArea \
          "$x" "$y" "$w" "$h" false "$tmp" > /dev/null 2>&1 && cat "$tmp"
      fi
    fi
    rm -f "$tmp" "$area"
  elif command -v flameshot > /dev/null 2>&1; then
    flameshot gui --raw 2> /dev/null
  else
    echo "no screenshot tool (install grim slurp)" >&2
    return 1
  fi
}

# --------------------------------------------------------------------------
# Package helpers. Release-to-release the archive renames and drops packages,
# so install what exists and say what was skipped rather than aborting.
# --------------------------------------------------------------------------
# grep the output from a variable, not a pipe: under `set -o pipefail`, grep -q
# closes the pipe on first match and apt-cache dies with SIGPIPE (141), which
# pipefail would surface as failure - making every package look unavailable.
apt_available() {
  local policy
  policy=$(apt-cache policy "$1" 2> /dev/null) || return 1
  grep -q 'Candidate: [^(]' <<< "$policy"
}

apt_install_available() {
  local p want=() skip=()
  for p in "$@"; do
    if apt_available "$p"; then want+=("$p"); else skip+=("$p"); fi
  done
  ((${#skip[@]} == 0)) || echo "  unavailable on this release, skipped: ${skip[*]}"
  ((${#want[@]} == 0)) && return 0
  sudo apt-get install -yq "${want[@]}"
}

hw_summary() {
  local chassis cpu gpu serial
  if is_wsl; then
    chassis=wsl
  elif is_laptop; then
    chassis=laptop
  else
    chassis=desktop
  fi
  if has_amd_cpu; then
    cpu=amd
  elif has_intel_cpu; then
    cpu=intel
  else
    cpu=other
  fi
  gpu=$(gpu_vendors | paste -sd+ -)
  [[ -z $gpu ]] && gpu=none
  is_hybrid_graphics && gpu="$gpu (hybrid, primary: $(primary_gpu))"
  if has_serial; then serial=present; else serial=none; fi
  echo "chassis:  $chassis"
  echo "cpu:      $cpu ($(cpu_scaling_driver))"
  echo "gpu:      $gpu"
  echo "session:  ${XDG_SESSION_TYPE:-none}"
  echo "serial:   $serial"
  if is_work; then echo "profile:  work"; else echo "profile:  personal"; fi
}

# Only print when executed, not when sourced
if ! (return 0 2> /dev/null); then
  hw_summary
fi
