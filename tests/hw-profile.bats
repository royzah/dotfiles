#!/usr/bin/env bats
# Variables set here are read by the sourced hw-profile.sh functions
# shellcheck source-path=SCRIPTDIR disable=SC2034
# Detection predicates in bin/hw-profile.sh, with lspci/systemctl stubbed

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIXTURES="$BATS_TEST_DIRNAME/fixtures"
  SHIM="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$SHIM"
  PATH="$SHIM:$PATH"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  unset WSL_DISTRO_NAME XDG_SESSION_TYPE
  stub_systemctl multi-user.target
  # shellcheck source=../bin/hw-profile.sh
  source "$REPO/bin/hw-profile.sh"
}

# lspci -n prints the given fixture
stub_lspci() {
  printf '#!/usr/bin/env bash\ncat %q\n' "$FIXTURES/lspci/$1.txt" > "$SHIM/lspci"
  chmod +x "$SHIM/lspci"
}

# systemctl get-default prints the given target
stub_systemctl() {
  printf '#!/usr/bin/env bash\necho %q\n' "$1" > "$SHIM/systemctl"
  chmod +x "$SHIM/systemctl"
}

vendors() { gpu_vendors | paste -sd+ -; }

# `! cmd` never fails a bats test mid-body (errexit ignores it); this does
refute() {
  if "$@"; then
    echo "expected failure: $*" >&2
    return 1
  fi
}

@test "intel only: not amd (no 'ati' match in 'Corporation')" {
  stub_lspci intel
  has_intel_gpu
  refute has_nvidia
  refute has_amd_gpu
  [[ $(vendors) == intel ]]
  refute is_hybrid_graphics
}

@test "nvidia 3D controller + intel: hybrid" {
  stub_lspci nvidia-intel
  has_nvidia
  has_intel_gpu
  refute has_amd_gpu
  [[ $(vendors) == nvidia+intel ]]
  is_hybrid_graphics
}

@test "amd display controller + nvidia: hybrid" {
  stub_lspci amd-nvidia
  has_nvidia
  has_amd_gpu
  refute has_intel_gpu
  [[ $(vendors) == nvidia+amd ]]
  is_hybrid_graphics
}

@test "amd only, audio function ignored" {
  stub_lspci amd
  has_amd_gpu
  refute has_nvidia
  refute has_intel_gpu
  [[ $(vendors) == amd ]]
  refute is_hybrid_graphics
}

@test "gpu vendors in non-display classes are ignored" {
  stub_lspci intel-plus-nongpu
  refute has_amd_gpu
  refute has_nvidia
  [[ $(vendors) == intel ]]
}

@test "no lspci output: no gpu, gpu_vendors still succeeds" {
  printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/lspci"
  chmod +x "$SHIM/lspci"
  run gpu_vendors
  [[ $status -eq 0 && -z $output ]]
  refute is_hybrid_graphics
}

@test "predicates stay correct under set -euo pipefail" {
  stub_lspci nvidia-intel
  run bash -c 'set -euo pipefail; source "$1"; has_nvidia; has_intel_gpu; if has_amd_gpu; then exit 1; fi; echo ok' _ "$REPO/bin/hw-profile.sh"
  [[ $status -eq 0 && $output == ok ]]
}

@test "is_work follows the marker file" {
  refute is_work
  mkdir -p "$HOME/.config/dotfiles"
  touch "$HOME/.config/dotfiles/work"
  is_work
}

@test "session type: wayland, x11, none" {
  XDG_SESSION_TYPE=wayland
  is_wayland
  has_gui
  refute is_x11
  XDG_SESSION_TYPE=x11
  is_x11
  has_gui
  refute is_wayland
  unset XDG_SESSION_TYPE
  refute has_gui
}

@test "has_desktop: gui session, or graphical.target over ssh" {
  XDG_SESSION_TYPE=wayland
  has_desktop
  unset XDG_SESSION_TYPE
  refute has_desktop
  stub_systemctl graphical.target
  has_desktop
}

@test "is_wsl from WSL_DISTRO_NAME, and WSL is never a desktop" {
  if grep -qi microsoft /proc/version 2> /dev/null; then
    skip "running on WSL"
  fi
  refute is_wsl
  WSL_DISTRO_NAME=Ubuntu
  is_wsl
  XDG_SESSION_TYPE=wayland
  refute has_desktop
  refute is_desktop
}
