#!/bin/bash
# ramsetup.sh - choose compressed swap: none | zram | zswap  (persistent)
#
# Usage: ramsetup.sh none|zram|zswap      (re-execs itself with sudo if needed)
#
# Supported: Debian-family Linux with systemd (uses apt/dpkg, systemd units,
# update-motd.d). Tested only on Ubuntu 26.04 (kernel 7.0); refuses elsewhere.
#
# What it does:
#  none   Disables zram and zswap; only the disk swap remains.
#  zram   Disables zswap, then enables zram swap (systemd-zram-generator).
#  zswap  Disables zram, then enables zswap in front of the disk swap.
#  Every mode resets vm.swappiness/vm.page-cluster to kernel defaults (60/3)
#  before applying the chosen mode's sysctls, installs the login banner, and
#  prints the resulting state. Changes apply immediately and survive reboot;
#  no reboot is needed. Exception: if the running kernel's modules have been
#  removed (zram/zstd can't load), it stops and says to reboot first.
#
# zram:
#  1. Installs systemd-zram-generator.
#  2. Writes /etc/systemd/zram-generator.conf for /dev/zram0:
#     zram-size = ram (uncompressed capacity; nothing is reserved up front),
#     zram-resident-limit = ram * 3 / 10 (30%; cap on real RAM zram may use; sets
#     /sys/block/zram0/mem_limit), compression zstd, swap-priority 100 so zram
#     is used before the disk swap (priority -1), which remains as overflow.
#  3. Writes /etc/sysctl.d/99-zram.conf: vm.swappiness=180 (in-RAM swap is
#     cheap, so bias reclaim towards it) and vm.page-cluster=0 (no swap
#     readahead; there is no seek cost to amortise).
#  4. Recreates zram0 without a reboot: stop swap, stop the setup unit,
#     udevadm settle, reset the device by hand, clear failed state, start
#     swap. The manual reset is needed because the unit's own reset
#     (ExecStop) can race udev right after swapoff and fail with EBUSY,
#     leaving the old device initialised ("Can't change algorithm for
#     initialized device").
#  Disabling zram: swapoff + reset zram0, purge systemd-zram-generator (it
#  ships a default /usr/lib/systemd/zram-generator.conf, so just deleting the
#  /etc config would still create zram at boot), delete the config files.
#  swapoff must page zram contents back into RAM; if it is heavily used and
#  memory is short this fails and the script stops - reboot instead.
#
# zswap:
#  1. Requires an active disk swap partition (zswap needs a backing device).
#  2. Loads the zstd compressor module (a module, not built in, here).
#  3. Persists settings via /etc/tmpfiles.d/zswap.conf, which writes the zswap
#     module parameters early at every boot: compressor=zstd,
#     max_pool_percent=30 (~1 GB of a 3.4 GB VM), shrinker_enabled=Y (cold
#     pages get written back to disk swap), enabled=Y.
#     tmpfiles.d is used instead of zswap.* kernel cmdline args because zswap
#     can initialise before the zstd module is loadable and silently fall back
#     to lzo; it also avoids update-grub.
#  4. Writes /etc/sysctl.d/99-zswap.conf: vm.swappiness=100. Lower than
#     zram's 180 because incompressible/overflow pages still hit disk.
#     vm.page-cluster stays at default 3 (readahead helps for disk swap).
#  Disabling zswap: enabled=N now, delete the config files. The kernel default
#  is off (CONFIG_ZSWAP_DEFAULT_ON is not set), so it stays off after reboot.
#  Pages already in the pool drain out naturally.
#
# Login banner: /etc/update-motd.d/01-compressed-swap shows zram/zswap status,
# usage and how to disable it (using this script's actual path). It prints nothing in 'none' mode.
set -euo pipefail

MODE=${1:-}
case "$MODE" in
  none|zram|zswap) ;;
  *) echo "Usage: $0 none|zram|zswap" >&2
     echo "  none   disk swap only (disable zram and zswap)" >&2
     echo "  zram   compressed swap device in RAM (disables zswap)" >&2
     echo "  zswap  compressed RAM cache in front of disk swap (disables zram)" >&2
     exit 1 ;;
esac

# Refuse on anything but Debian/Ubuntu with systemd as init (checked before sudo)
OS_NAME=$(uname -s) OS_IDS=
if [ -r /etc/os-release ]; then
  OS_NAME=$(. /etc/os-release && echo "${PRETTY_NAME:-${ID:-$OS_NAME}}")
  OS_IDS=$(. /etc/os-release && echo " ${ID:-} ${ID_LIKE:-} ")
fi
if [ "$(uname -s)" != Linux ] || [ ! -d /run/systemd/system ] ||
   [[ "$OS_IDS" != *" debian "* && "$OS_IDS" != *" ubuntu "* ]] ||
   ! command -v apt-get >/dev/null || ! command -v dpkg >/dev/null; then
  echo "$(basename "$0"): unsupported system ($OS_NAME): requires Debian/Ubuntu with systemd" >&2
  exit 1
fi

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

ZSWAP_COMPRESSOR=zstd
ZSWAP_MAX_POOL_PERCENT=30   # max % of RAM the compressed pool may use
ZP=/sys/module/zswap/parameters
SELF=$(readlink -f "$0")      # this script's real path, shown in the banner

# No reboot is needed to switch modes. The one case that does need one: the
# running kernel's modules were removed (e.g. apt autoremove after a kernel
# upgrade), so zram/zstd can't be loaded until booting the installed kernel.
need_modules() {
  local m
  for m in "$@"; do
    if ! modprobe -n -q "$m"; then
      echo "Kernel module '$m' is not available for the running kernel $(uname -r)." >&2
      echo "Reboot into the installed kernel, then re-run: $0 $MODE" >&2
      exit 1
    fi
  done
}
case "$MODE" in
  zram)  need_modules zram zstd ;;
  zswap) need_modules zstd ;;
esac

stop_zram_device() {
  systemctl stop dev-zram0.swap 2>/dev/null || true
  if [ -e /sys/block/zram0 ] && swapon --noheadings --show=NAME | grep -qx /dev/zram0; then
    swapoff /dev/zram0
  fi
  systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true
  udevadm settle
  if [ -e /sys/block/zram0 ]; then
    echo 1 > /sys/block/zram0/reset
  fi
  systemctl reset-failed systemd-zram-setup@zram0.service dev-zram0.swap 2>/dev/null || true
}

disable_zram() {
  echo "Disabling zram..."
  stop_zram_device
  if dpkg -s systemd-zram-generator >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get purge -y -q systemd-zram-generator >/dev/null
  fi
  rm -f /etc/systemd/zram-generator.conf /etc/sysctl.d/99-zram.conf
  systemctl daemon-reload
}

disable_zswap() {
  echo "Disabling zswap..."
  [ -w $ZP/enabled ] && echo N > $ZP/enabled
  rm -f /etc/tmpfiles.d/zswap.conf /etc/sysctl.d/99-zswap.conf
}

enable_zram() {
  echo "Enabling zram..."
  DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y -q systemd-zram-generator >/dev/null

  cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram
zram-resident-limit = ram * 3 / 10
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

  cat > /etc/sysctl.d/99-zram.conf <<'EOF'
# in-RAM swap is cheap, so bias reclaim towards it
vm.swappiness = 180
# no seek latency to amortise, so no swap readahead
vm.page-cluster = 0
EOF

  # Recreate zram0 with the new config (see header for why the manual reset)
  systemctl daemon-reload
  stop_zram_device
  systemctl start dev-zram0.swap
}

enable_zswap() {
  echo "Enabling zswap..."
  if ! swapon --noheadings --show=TYPE | grep -q partition; then
    echo "No disk swap partition active; zswap needs one." >&2
    exit 1
  fi
  modprobe "$ZSWAP_COMPRESSOR"

  # Applied at every boot by systemd-tmpfiles (no kernel cmdline / grub change)
  cat > /etc/tmpfiles.d/zswap.conf <<EOF
w- $ZP/compressor       - - - - $ZSWAP_COMPRESSOR
w- $ZP/max_pool_percent - - - - $ZSWAP_MAX_POOL_PERCENT
w- $ZP/shrinker_enabled - - - - Y
w- $ZP/enabled          - - - - Y
EOF

  cat > /etc/sysctl.d/99-zswap.conf <<'EOF'
# swap-out is mostly to compressed RAM, so swap a little more readily than default 60
vm.swappiness = 100
EOF

  # Apply now
  echo "$ZSWAP_COMPRESSOR"       > $ZP/compressor
  echo "$ZSWAP_MAX_POOL_PERCENT" > $ZP/max_pool_percent
  echo Y                         > $ZP/shrinker_enabled
  echo Y                         > $ZP/enabled
}

install_banner() {
  rm -f /etc/update-motd.d/01-zram   # older zram-only banner
  cat > /etc/update-motd.d/01-compressed-swap <<'MOTD'
#!/bin/sh
# Login banner: announce zram / zswap compressed swap and how to disable each.
# Installed by @SELF@.
Y='\033[1;33m'; N='\033[0m'
LINE='*********************************************************************'
box() {
  printf "\n${Y}%s${N}\n" "$LINE"
  for l in "$@"; do printf "${Y}*  %-65s*${N}\n" "$l"; done
  printf "${Y}%s${N}\n" "$LINE"
}

if swapon --noheadings --show=NAME 2>/dev/null | grep -q zram; then
  box "NOTICE: zram compressed swap is ENABLED on this machine" \
      "RAM may be compressed into /dev/zram* before disk swapping."
  printf "   device     algo   size   data   compressed  ram-used\n"
  zramctl --noheadings --output NAME,ALGORITHM,DISKSIZE,DATA,COMPR,TOTAL 2>/dev/null |
  while read -r name algo size data compr total; do
    printf "   %-10s %-6s %-6s %-6s %-11s %s\n" "$name" "$algo" "$size" "$data" "$compr" "$total"
  done
  printf "   swappiness=%s   (see: zramctl, swapon --show)\n" "$(cat /proc/sys/vm/swappiness)"
  printf "   To disable: sudo %s none\n" "@SELF@"
fi

P=/sys/module/zswap/parameters
if [ "$(cat $P/enabled 2>/dev/null)" = "Y" ]; then
  box "NOTICE: zswap compressed swap cache is ENABLED on this machine" \
      "Swapped pages are compressed in RAM before going to disk swap."
  pool=$(awk '/^Zswap:/ {print int($2/1024)}' /proc/meminfo)
  orig=$(awk '/^Zswapped:/ {print int($2/1024)}' /proc/meminfo)
  printf "   compressor=%s  max_pool=%s%%  pool=%sMB holding %sMB\n" \
    "$(cat $P/compressor)" "$(cat $P/max_pool_percent)" "${pool:-0}" "${orig:-0}"
  printf "   swappiness=%s   (see: grep . %s/*)\n" "$(cat /proc/sys/vm/swappiness)" "$P"
  printf "   To disable: sudo %s none\n" "@SELF@"
fi
exit 0
MOTD
  sed -i "s|@SELF@|$SELF|g" /etc/update-motd.d/01-compressed-swap
  chmod 755 /etc/update-motd.d/01-compressed-swap
}

case "$MODE" in
  none)  disable_zram; disable_zswap ;;
  zram)  disable_zswap; enable_zram ;;
  zswap) disable_zram; enable_zswap ;;
esac

# Back to kernel defaults, then apply whatever sysctl.d files remain
sysctl -q -w vm.swappiness=60 vm.page-cluster=3
sysctl --system >/dev/null

install_banner

echo
echo "Mode: $MODE"
echo "zswap enabled: $(cat $ZP/enabled 2>/dev/null || echo n/a)"
zramctl 2>/dev/null || true
swapon --show
sysctl vm.swappiness vm.page-cluster
echo "Applied now; no reboot needed for this change."
if [ -e /run/reboot-required ]; then
  echo "(Note: /run/reboot-required exists for other updates, e.g. a new kernel; unrelated to $MODE.)"
fi
