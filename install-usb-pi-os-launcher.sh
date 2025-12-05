#!/usr/bin/env bash
#
# install-usb-pi-os-launcher.sh
#
# Installer for the USB Pi OS Launcher:
#   - Installs the main script to /usr/local/bin/usb-pi-os
#   - Installs a launcher wrapper /usr/local/bin/usb-pi-os-launch
#   - Installs the icon to /usr/share/icons/usb-pi-os.png
#   - Creates a .desktop entry for the Raspberry Pi menu
#

set -e

APP_NAME="USB Pi OS Launcher"
BIN_NAME="usb-pi-os"
WRAPPER_NAME="usb-pi-os-launch"
ICON_NAME="usb-pi-os.png"
ICON_TARGET="/usr/share/icons/${ICON_NAME}"
DESKTOP_FILE="/usr/share/applications/usb-pi-os.desktop"
MOUNT_POINT="/mnt/pi-os-root"

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This installer must run as root. Re-running with sudo..."
    exec sudo "$0" "$@"
  fi
}

main() {
  require_root "$@"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  echo "Installing ${APP_NAME}..."

  # Install main script
  if [[ ! -f "${SCRIPT_DIR}/usb-pi-os.sh" ]]; then
    echo "ERROR: usb-pi-os.sh not found in ${SCRIPT_DIR}"
    exit 1
  fi

  install -m 0755 "${SCRIPT_DIR}/usb-pi-os.sh" "/usr/local/bin/${BIN_NAME}"

  # Install icon
  if [[ -f "${SCRIPT_DIR}/icon/${ICON_NAME}" ]]; then
    install -m 0644 "${SCRIPT_DIR}/icon/${ICON_NAME}" "${ICON_TARGET}"
  else
    echo "WARNING: Icon ${SCRIPT_DIR}/icon/${ICON_NAME} not found. Skipping icon install."
  fi

  # Create wrapper launcher
  cat << 'EOF' > "/usr/local/bin/${WRAPPER_NAME}"
#!/bin/bash
# Wrapper to launch USB Pi OS Launcher in a terminal with sudo

TARGET_BIN="/usr/local/bin/usb-pi-os"

if ! command -v lxterminal >/dev/null 2>&1; then
  TERM_CMD="x-terminal-emulator"
else
  TERM_CMD="lxterminal"
fi

exec "${TERM_CMD}" -e "sudo ${TARGET_BIN}"
EOF

  chmod 0755 "/usr/local/bin/${WRAPPER_NAME}"

  # Create .desktop file
  cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Name=${APP_NAME}
Comment=Boot any connected OS partition in a systemd-nspawn container
Exec=/usr/local/bin/${WRAPPER_NAME}
Icon=${ICON_TARGET}
Terminal=false
Type=Application
Categories=System;Utility;
StartupNotify=true
EOF

  chmod 0644 "${DESKTOP_FILE}"

  # Optionally place a shortcut on the current user's Desktop
  if command -v getent >/dev/null 2>&1; then
    USER_NAME="${SUDO_USER:-$USER}"
    USER_HOME="$(getent passwd "${USER_NAME}" | cut -d: -f6 || echo "/home/${USER_NAME}")"
    if [[ -d "${USER_HOME}/Desktop" ]]; then
      cp "${DESKTOP_FILE}" "${USER_HOME}/Desktop/"
      chown "${USER_NAME}":"${USER_NAME}" "${USER_HOME}/Desktop/usb-pi-os.desktop" || true
      chmod +x "${USER_HOME}/Desktop/usb-pi-os.desktop"
    fi
  fi

  # Update desktop database if available
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database >/dev/null 2>&1 || true
  fi

  echo "Installation complete."
  echo
  echo "You can now launch "${APP_NAME}" from the Raspberry Pi menu (System/Utilities),"
  echo "or by running: ${WRAPPER_NAME}"
}

main "$@"
