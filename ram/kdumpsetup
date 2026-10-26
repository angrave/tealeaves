#!/bin/bash
# kdumpsetup.sh - enable/disable the kdump crash-kernel memory reservation
#
# Usage: kdumpsetup.sh [enable|disable]   (no argument: show state and usage)
#
# Background: kdump-tools adds crashkernel=... to the kernel command line
# (/etc/default/grub.d/kdump-tools.cfg). On a 4 GB VM that permanently
# reserves 512 MB for a crash-capture kernel - RAM the system can never use
# otherwise - even when kdump itself is off (USE_KDUMP=0).
#
# What it does:
#  disable  1. Writes /etc/default/grub.d/zz-no-crashkernel.cfg, sourced after
#              kdump-tools.cfg, which strips crashkernel=... from the grub
#              cmdline variables; runs update-grub (persists across reboots
#              and kdump-tools upgrades, whose conffile is left untouched).
#           2. Sets USE_KDUMP=0 and disables the kdump-tools service.
#           3. Frees the reservation now: unloads the crash kernel and writes
#              0 to /sys/kernel/kexec_crash_size, returning the RAM to the
#              system without a reboot. If that fails, it says a reboot is
#              needed.
#  enable   1. Installs kdump-tools if missing, removes the override file,
#              runs update-grub so crashkernel=... is back on the cmdline.
#           2. Sets USE_KDUMP=1 and enables the kdump-tools service.
#           3. The reservation can only be made at boot, so if none is active
#              it says a reboot is required; otherwise loads the crash kernel.
#  (none)   Prints running state, next-boot state, and usage.
#
# Supported: Debian-family Linux with systemd and GRUB (update-grub). Tested
# only on Ubuntu 26.04 (kernel 7.0); enable/disable refuse elsewhere.
# Sanity checks: before changing anything it verifies the OS, GRUB files,
# update-grub and the kexec sysfs file exist. Every file it modifies is first
# copied to <file>.bak (previous state; overwritten each run): kdump-tools
# defaults, grub.cfg, and the override file. After update-grub it verifies
# grub.cfg has (or lacks) crashkernel= and stops with restore hints if not.
set -euo pipefail

OVERRIDE=/etc/default/grub.d/zz-no-crashkernel.cfg
KDUMP_DEFAULTS=/etc/default/kdump-tools
SIZE_FILE=/sys/kernel/kexec_crash_size

usage() {
  echo "Usage: $0 enable|disable"
  echo "  disable  free the crash-kernel RAM reservation (applies now, persists)"
  echo "  enable   restore crashkernel= and kdump (needs a reboot to reserve RAM)"
}

mb() { echo $(( $1 / 1024 / 1024 )); }

status() {
  local size=0 loaded=0 cmdline=absent nextboot=absent usek=unset svc=n/a
  [ -r $SIZE_FILE ] && size=$(cat $SIZE_FILE)
  [ -r /sys/kernel/kexec_crash_loaded ] && loaded=$(cat /sys/kernel/kexec_crash_loaded)
  grep -q 'crashkernel=' /proc/cmdline && cmdline=present
  if [ -r /boot/grub/grub.cfg ] && grep -E '^\s*linux\s' /boot/grub/grub.cfg | grep -q 'crashkernel='; then
    nextboot=present
  fi
  [ -r $KDUMP_DEFAULTS ] && usek=$(sed -n 's/^USE_KDUMP=//p' $KDUMP_DEFAULTS | tail -1)
  systemctl cat kdump-tools.service >/dev/null 2>&1 && svc=$(systemctl is-enabled kdump-tools.service 2>/dev/null || true)

  echo "Crash kernel (kdump) memory reservation on $(hostname -s):"
  echo "  reserved now        : $(mb "$size") MB   (crash kernel loaded: $loaded)"
  echo "  running cmdline     : crashkernel= $cmdline"
  echo "  next boot (grub.cfg): crashkernel= $nextboot"
  echo "  override file       : $([ -e $OVERRIDE ] && echo "$OVERRIDE" || echo none)"
  echo "  kdump-tools         : USE_KDUMP=${usek:-unset}, service ${svc:-n/a}"
  echo "  MemTotal            : $(awk '/^MemTotal:/ {print int($2/1024)}' /proc/meminfo) MB"
  if [ "$nextboot" = present ] && [ "$size" -eq 0 ]; then
    echo "  => enabled for next boot; REBOOT REQUIRED to reserve the memory"
  elif [ "$nextboot" = absent ] && [ "$size" -gt 0 ]; then
    echo "  => disabled for next boot; $(mb "$size") MB still reserved until reboot or '$0 disable'"
  elif [ "$nextboot" = present ]; then
    echo "  => ENABLED"
  else
    echo "  => DISABLED"
  fi
}

MODE=${1:-}
case "$MODE" in
  "") status; echo; usage; exit 0 ;;
  enable|disable) ;;
  *) usage >&2; exit 1 ;;
esac

die() { echo "$(basename "$0"): $*" >&2; exit 1; }

# Refuse on anything but Debian/Ubuntu with systemd as init (checked before sudo)
OS_NAME=$(uname -s) OS_IDS=
if [ -r /etc/os-release ]; then
  OS_NAME=$(. /etc/os-release && echo "${PRETTY_NAME:-${ID:-$OS_NAME}}")
  OS_IDS=$(. /etc/os-release && echo " ${ID:-} ${ID_LIKE:-} ")
fi
if [ "$(uname -s)" != Linux ] || [ ! -d /run/systemd/system ] ||
   [[ "$OS_IDS" != *" debian "* && "$OS_IDS" != *" ubuntu "* ]] ||
   ! command -v apt-get >/dev/null || ! command -v dpkg >/dev/null; then
  die "unsupported system ($OS_NAME): requires Debian/Ubuntu with systemd"
fi

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

# Sanity checks: everything we read or modify must exist
GRUB_CFG=/boot/grub/grub.cfg
command -v update-grub >/dev/null || die "update-grub not found (GRUB required)"
[ -f /etc/default/grub ]  || die "/etc/default/grub not found (GRUB required)"
[ -d /etc/default/grub.d ] || die "/etc/default/grub.d not found"
[ -f $GRUB_CFG ]          || die "$GRUB_CFG not found (EFI-only/non-GRUB boot?)"
[ -e $SIZE_FILE ]         || die "$SIZE_FILE not found (kernel without kexec/kdump support)"

backup() { [ -e "$1" ] && cp -p "$1" "$1.bak" && echo "  backup: $1.bak"; return 0; }

# Regenerate grub.cfg (backed up first) and verify crashkernel= is as expected
regen_grub() {
  local want=$1 have=absent out
  backup $GRUB_CFG
  out=$(update-grub 2>&1) || { echo "$out" >&2; die "update-grub failed; previous config: $GRUB_CFG.bak"; }
  grep -E '^\s*linux\s' $GRUB_CFG | grep -q 'crashkernel=' && have=present
  [ "$have" = "$want" ] ||
    die "grub.cfg has crashkernel= $have, expected $want; check /etc/default/grub*, previous config: $GRUB_CFG.bak"
}

set_use_kdump() {
  [ -e $KDUMP_DEFAULTS ] || return 0
  backup $KDUMP_DEFAULTS
  if grep -q '^USE_KDUMP=' $KDUMP_DEFAULTS; then
    sed -i "s/^USE_KDUMP=.*/USE_KDUMP=$1/" $KDUMP_DEFAULTS
  else
    echo "USE_KDUMP=$1" >> $KDUMP_DEFAULTS
  fi
}

REBOOT=no
case "$MODE" in
  disable)
    backup $OVERRIDE
    cat > $OVERRIDE <<'EOF'
# Installed by kdumpsetup.sh: drop the kdump crashkernel= reservation.
# Sourced after kdump-tools.cfg. Remove this file (or run: kdumpsetup.sh enable)
# and run update-grub to restore it.
GRUB_CMDLINE_LINUX_DEFAULT=$(echo "$GRUB_CMDLINE_LINUX_DEFAULT" | sed -E 's/(^| )crashkernel=[^ ]*//g; s/^ +//')
GRUB_CMDLINE_LINUX=$(echo "$GRUB_CMDLINE_LINUX" | sed -E 's/(^| )crashkernel=[^ ]*//g; s/^ +//')
EOF
    regen_grub absent
    set_use_kdump 0
    if systemctl cat kdump-tools.service >/dev/null 2>&1; then
      systemctl disable --now kdump-tools.service >/dev/null 2>&1 || true
    fi
    command -v kdump-config >/dev/null && kdump-config unload >/dev/null 2>&1 || true
    if [ -w $SIZE_FILE ] && [ "$(cat $SIZE_FILE)" -gt 0 ]; then
      echo 0 > $SIZE_FILE 2>/dev/null || true
      [ "$(cat $SIZE_FILE)" -eq 0 ] || REBOOT=yes
    fi
    ;;
  enable)
    if ! dpkg -s kdump-tools >/dev/null 2>&1; then
      DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y -q kdump-tools >/dev/null
    fi
    backup $OVERRIDE
    rm -f $OVERRIDE
    regen_grub present
    set_use_kdump 1
    systemctl enable kdump-tools.service >/dev/null 2>&1
    if [ "$(cat $SIZE_FILE 2>/dev/null || echo 0)" -eq 0 ]; then
      REBOOT=yes
    else
      systemctl restart kdump-tools.service || true
    fi
    ;;
esac

status
echo
if [ $REBOOT = yes ]; then
  echo "REBOOT REQUIRED for '$MODE' to take full effect."
else
  echo "Applied now; no reboot needed."
fi
