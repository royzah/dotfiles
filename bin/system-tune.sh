#!/usr/bin/env bash
# system-tune.sh - one-time system tuning that needs root. Idempotent.
#
#   zram swap, journald size cap, writeback limits, cgroup delegation.
# Every change is a single file you can delete to revert.
set -euo pipefail

# shellcheck source=bin/hw-profile.sh
source "$(dirname "$(readlink -f "$0")")/hw-profile.sh"

# WSL runs Microsoft's kernel: no grub, and memory/swap are set in .wslconfig
if is_wsl; then
  echo "WSL detected: nothing to tune here, see WINDOWS_GUIDE.md (.wslconfig)"
  exit 0
fi

echo "=== system tune ==="

# --------------------------------------------------------------------------
# zram: compressed RAM swap. Far faster than the disk swapfile and, at ~3x
# compression, gives more usable swap than the 2G file it replaces.
# --------------------------------------------------------------------------
echo "[zram]"
if [[ -e /dev/zram0 ]]; then
  echo "  zram: already active"
else
  sudo apt-get install -yq systemd-zram-generator
  sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'CONF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
CONF
  sudo systemctl daemon-reload 2> /dev/null || true
  sudo systemctl start systemd-zram-setup@zram0.service 2> /dev/null || true
  echo "  zram configured (zstd, up to 8G)"
fi

# zram wants a high swappiness: swapping to RAM is cheap, unlike swapping to disk
echo "[sysctl]"
sudo tee /etc/sysctl.d/99-dotfiles.conf > /dev/null << 'CONF'
# Swapping to zram is cheap, so let the kernel prefer it
vm.swappiness = 150
vm.vfs_cache_pressure = 50
# Cap dirty page writeback. The 20% ratio default is ~6GB on 31GB of RAM,
# which stalls hard when it finally flushes.
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
CONF
# /etc/sysctl.conf is applied after /etc/sysctl.d/*, so an old swappiness
# there would win. Low swappiness suits a disk swapfile but starves zram.
if grep -qE '^\s*vm\.swappiness' /etc/sysctl.conf 2> /dev/null; then
  sudo cp -n /etc/sysctl.conf /etc/sysctl.conf.bak
  sudo sed -i -E 's/^(\s*vm\.swappiness)/# superseded by 99-dotfiles.conf (zram)\n#\1/' /etc/sysctl.conf
  echo "  commented old vm.swappiness in /etc/sysctl.conf (backup: .bak)"
fi
sudo sysctl -q --system 2> /dev/null || true
echo "  writeback and swap tuning applied (swappiness now $(sysctl -n vm.swappiness))"

# --------------------------------------------------------------------------
# journald: uncapped by default. Cap it so logs cannot eat the disk again.
# --------------------------------------------------------------------------
echo "[journald]"
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/99-size.conf > /dev/null << 'CONF'
[Journal]
SystemMaxUse=200M
SystemMaxFileSize=50M
CONF
sudo systemctl restart systemd-journald 2> /dev/null || true
sudo journalctl --vacuum-size=200M > /dev/null 2>&1 || true
echo "  capped at 200M (was $(journalctl --disk-usage 2> /dev/null | grep -oE '[0-9.]+[MG]' | head -1))"

# --------------------------------------------------------------------------
# CPU scaling. Both amd-pstate-epp and intel_pstate expose the same
# energy_performance_preference knob, so the tuning below is vendor-neutral;
# only getting the right driver loaded differs.
# --------------------------------------------------------------------------
echo "[cpu]"
driver=$(cpu_scaling_driver)
echo "  vendor $(cpu_vendor), driver $driver"

if has_amd_cpu && [[ $driver != amd-pstate-epp ]]; then
  # Without amd_pstate=active the kernel falls back to acpi-cpufreq and loses
  # both boost responsiveness and idle efficiency.
  if [[ ! -f /etc/default/grub ]]; then
    # systemd-boot, rEFInd or a cloud image: no grub to edit
    echo "  no /etc/default/grub; add amd_pstate=active to your bootloader cmdline"
  elif grep -q 'amd_pstate=' /etc/default/grub; then
    echo "  amd_pstate already on the kernel cmdline (reboot pending)"
  else
    sudo cp -n /etc/default/grub /etc/default/grub.bak
    # Handle both quote styles; a single-quoted line is common on some spins
    sudo sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT=)"(.*)"/\1"\2 amd_pstate=active"/; s/^(GRUB_CMDLINE_LINUX_DEFAULT=)'"'"'(.*)'"'"'/\1'"'"'\2 amd_pstate=active'"'"'/' /etc/default/grub
    if grep -q 'amd_pstate=active' /etc/default/grub; then
      sudo update-grub > /dev/null 2>&1 || echo "  warning: update-grub failed"
      echo "  added amd_pstate=active (reboot required)"
    else
      echo "  could not edit GRUB_CMDLINE_LINUX_DEFAULT; add amd_pstate=active by hand"
    fi
  fi
elif has_intel_cpu && [[ $driver == intel_pstate || $driver == intel_cpufreq ]]; then
  echo "  intel_pstate already active"
fi

# Desktops can afford to keep boost primed; laptops trade a little latency for
# battery. Override with EPP=performance ./bin/system-tune.sh
if has_epp; then
  if is_desktop; then EPP="${EPP:-balance_performance}"; else EPP="${EPP:-balance_power}"; fi
  for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
    if [[ -w $f ]]; then echo "$EPP" | sudo tee "$f" > /dev/null 2>&1 || true; fi
  done
  sudo tee /etc/systemd/system/cpu-epp.service > /dev/null << CONF
[Unit]
Description=Set CPU energy performance preference
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do echo $EPP > \$f; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
CONF
  sudo systemctl enable cpu-epp.service > /dev/null 2>&1 || true
  echo "  EPP $EPP, persisted via cpu-epp.service"
else
  echo "  no EPP support on this driver, skipping"
fi

# --------------------------------------------------------------------------
# cgroup delegation: without this, `systemd-run --user -p CPUWeight=...`
# silently does nothing, so build throttling never takes effect.
# --------------------------------------------------------------------------
echo "[cgroups]"
sudo mkdir -p /etc/systemd/system/user@.service.d
sudo tee /etc/systemd/system/user@.service.d/delegate.conf > /dev/null << 'CONF'
[Service]
Delegate=cpu cpuset io memory pids
CONF
sudo systemctl daemon-reexec 2> /dev/null || true
echo "  cpu/io delegation enabled (takes effect next login)"

echo
echo "Done. Reboot to pick up zram, cgroup delegation and any cmdline change."
