#!/usr/bin/env bash
set -e
TMP=$(mktemp -d)
cd "$TMP"
echo "Downloading USB Pi OS Launcher..."
curl -sLO https://raw.githubusercontent.com/YOUR-USER/usb-pi-os-launcher/main/install-usb-pi-os-launcher.sh
chmod +x install-usb-pi-os-launcher.sh
sudo ./install-usb-pi-os-launcher.sh
echo "Done."
