#!/usr/bin/env bash
#
# usb-pi-os.sh
#
# Helper for running a Raspberry Pi OS install on ANY selected drive
# inside a systemd-nspawn container with three modes:
#   A) Simple shell
#   B) Forced /bin/bash shell
#   C) Full boot (systemd, services, login)
#
# Tested on: Raspberry Pi 5, Raspberry Pi OS 64-bit Bookworm
#

set -e

MOUNT_POINT="/mnt/pi-os-root"
SELECTED_DEV=""

# === FUNCTIONS ===

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must run as root. Re-running with sudo..."
    exec sudo "$0" "$@"
  fi
}

check_dependencies() {
  if ! command -v systemd-nspawn >/dev/null 2>&1; then
    echo "systemd-nspawn is not installed. Installing systemd-container..."
    apt update
    apt install -y systemd-container
  fi
}

ensure_mount_point() {
  if [[ ! -d "$MOUNT_POINT" ]]; then
    mkdir -p "$MOUNT_POINT"
  fi
}

select_device() {
  echo "Detecting available partitions..."
  echo

  # Root and boot devices (so we don't list them as options)
  local ROOT_DEV BOOT_DEV
  ROOT_DEV=$(findmnt -no SOURCE / 2>/dev/null || true)
  BOOT_DEV=$(findmnt -no SOURCE /boot 2>/dev/null || findmnt -no SOURCE /boot/firmware 2>/dev/null || true)

  local DEVICES=()
  local SIZES=()
  local MOUNTS=()

  # Read: NAME TYPE SIZE MOUNTPOINT
  while read -r name type size mnt; do
    [[ "$type" != "part" ]] && continue

    local dev="/dev/$name"

    # Skip host root and boot partitions for safety
    if [[ "$dev" == "$ROOT_DEV" || "$dev" == "$BOOT_DEV" ]]; then
      continue
    fi

    DEVICES+=("$dev")
    SIZES+=("$size")
    MOUNTS+=("$mnt")
  done < <(lsblk -rno NAME,TYPE,SIZE,MOUNTPOINT)

  if [[ ${#DEVICES[@]} -eq 0 ]]; then
    echo "No eligible partitions found (excluding host root/boot)."
    echo "Plug in a USB drive or check with 'lsblk' and try again."
    exit 1
  fi

  echo "Available partitions (excluding host root/boot):"
  echo

  local i
  for i in "${!DEVICES[@]}"; do
    local dev="${DEVICES[$i]}"
    local size="${SIZES[$i]}"
    local mnt="${MOUNTS[$i]:--}"
    printf "  %2d) %-12s  %-8s  %s
" "$((i+1))" "$dev" "$size" "$mnt"
  done

  echo
  echo "NOTE:"
  echo "  - Choose a partition that contains a Linux root filesystem"
  echo "    (it should have /bin, /etc, /usr, etc when mounted)."
  echo

  local choice
  read -r -p "Select a partition by number (or 'q' to quit): " choice

  case "$choice" in
    q|Q)
      echo "Exiting."
      exit 0
      ;;
    *[!0-9]*|"")
      echo "Invalid selection."
      exit 1
      ;;
  esac

  local idx=$((choice-1))
  if (( idx < 0 || idx >= ${#DEVICES[@]} )); then
    echo "Selection out of range."
    exit 1
  fi

  SELECTED_DEV="${DEVICES[$idx]}"
  echo
  echo "Selected root device: $SELECTED_DEV"
  echo
}

ensure_dev_mounted() {
  if [[ -z "$SELECTED_DEV" ]]; then
    echo "INTERNAL ERROR: SELECTED_DEV is empty."
    exit 1
  fi

  if [[ ! -b "$SELECTED_DEV" ]]; then
    echo "ERROR: Device $SELECTED_DEV does not exist."
    exit 1
  fi

  # Check if already mounted
  local current_mount
  current_mount=$(lsblk -no MOUNTPOINT "$SELECTED_DEV" 2>/dev/null | head -n1 || true)

  if [[ -z "$current_mount" ]]; then
    echo "Mounting $SELECTED_DEV on $MOUNT_POINT..."
    mount "$SELECTED_DEV" "$MOUNT_POINT"
  else
    if [[ "$current_mount" == "$MOUNT_POINT" ]]; then
      echo "$SELECTED_DEV is already mounted on $MOUNT_POINT"
    else
      echo "$SELECTED_DEV is currently mounted on $current_mount"
      echo "Re-mounting it on $MOUNT_POINT..."
      umount "$current_mount" || {
        echo "ERROR: Failed to unmount $SELECTED_DEV from $current_mount."
        echo "Make sure nothing is using that mount, then try again."
        exit 1
      }
      mount "$SELECTED_DEV" "$MOUNT_POINT"
      echo "Mounted $SELECTED_DEV on $MOUNT_POINT"
    fi
  fi
}

setup_dns() {
  if [[ -f /etc/resolv.conf ]]; then
    if [[ ! -d "$MOUNT_POINT/etc" ]]; then
      echo "ERROR: $MOUNT_POINT/etc does not exist. Is this a valid Linux root?"
      exit 1
    fi
    cp /etc/resolv.conf "$MOUNT_POINT/etc/resolv.conf"
  fi
}

run_mode_a() {
  echo
  echo "=== OPTION A: Simple shell inside selected OS ($SELECTED_DEV) ==="
  echo "Dropping into container. Type 'exit' to return to host."
  echo
  systemd-nspawn -D "$MOUNT_POINT"
}

run_mode_b() {
  echo
  echo "=== OPTION B: Forced /bin/bash inside selected OS ($SELECTED_DEV) ==="
  echo "Dropping into container. Type 'exit' to return to host."
  echo
  systemd-nspawn -D "$MOUNT_POINT" /bin/bash
}

run_mode_c() {
  echo
  echo "=== OPTION C: Full boot (systemd) of selected OS ($SELECTED_DEV) ==="
  echo "You will see boot logs and a login prompt."
  echo "To stop, log out and wait for container to exit,"
  echo "or press Ctrl+] three times quickly."
  echo
  systemd-nspawn -D "$MOUNT_POINT" -b
}

maybe_unmount() {
  echo
  read -r -p "Do you want to unmount $MOUNT_POINT now? [y/N]: " ans
  case "$ans" in
    y|Y|yes|YES)
      echo "Unmounting $MOUNT_POINT..."
      umount "$MOUNT_POINT" || {
        echo "WARNING: Failed to unmount $MOUNT_POINT. It may still be in use."
      }
      ;;
    *)
      echo "Leaving $MOUNT_POINT mounted."
      ;;
  esac
}

show_menu() {
  echo "============================================"
  echo "  Pi OS Container Launcher (systemd-nspawn)"
  echo "  Root device: $SELECTED_DEV"
  echo "  Mountpoint:  $MOUNT_POINT"
  echo "============================================"
  echo "Choose how to run the selected OS:"
  echo
  echo "  1) Option A - Simple shell inside OS"
  echo "  2) Option B - Forced /bin/bash inside OS"
  echo "  3) Option C - Full boot (systemd) of OS"
  echo "  q) Quit"
  echo
  read -r -p "Selection: " choice

  case "$choice" in
    1)
      run_mode_a
      ;;
    2)
      run_mode_b
      ;;
    3)
      run_mode_c
      ;;
    q|Q)
      echo "Exiting without starting container."
      exit 0
      ;;
    *)
      echo "Invalid choice."
      exit 1
      ;;
  esac
}

# === MAIN ===

require_root "$@"
check_dependencies
ensure_mount_point
select_device
ensure_dev_mounted
setup_dns
show_menu
maybe_unmount

echo "Done."
