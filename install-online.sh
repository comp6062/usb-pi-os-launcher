#!/usr/bin/env bash
#
# install-online.sh
#
# Homebrew-style one-line installer for USB Pi OS Launcher
#

set -e

REPO_USER="comp6062"
REPO_NAME="usb-pi-os-launcher"
RAW_BASE="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main"

TMP_DIR="$(mktemp -d)"
cd "${TMP_DIR}"

echo "Downloading USB Pi OS Launcher installer from ${RAW_BASE}..."
curl -fsSL "${RAW_BASE}/install-usb-pi-os-launcher.sh" -o install-usb-pi-os-launcher.sh

if [[ ! -s install-usb-pi-os-launcher.sh ]] || grep -qi "404: Not Found" install-usb-pi-os-launcher.sh; then
  echo "ERROR: Failed to download install-usb-pi-os-launcher.sh from:"
  echo "  ${RAW_BASE}/install-usb-pi-os-launcher.sh"
  exit 1
fi

chmod +x install-usb-pi-os-launcher.sh
sudo ./install-usb-pi-os-launcher.sh

echo "USB Pi OS Launcher installation finished."
