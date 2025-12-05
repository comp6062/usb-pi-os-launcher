# USB Pi OS Launcher

**Run any Raspberry Pi OS (or other Linux) installed on a USB/SD partition inside your running Raspberry Pi OS, using systemd-nspawn.**

This tool lets you treat another Pi OS installation as a lightweight "VM" (container) with three modes:

- **Option A** – Simple shell inside the selected OS
- **Option B** – Forced `/bin/bash` inside the selected OS
- **Option C** – Full boot of the selected OS (`systemd`, services, login prompt)

Tested on:

- **Raspberry Pi 5**
- **Raspberry Pi OS 64-bit (Bookworm)**

---

## 📦 One-Line Installer (curl or wget)

Install USB Pi OS Launcher without cloning the repo:

### **curl**
```bash
bash <(curl -s https://raw.githubusercontent.com/comp6062/usb-pi-os-launcher/main/install-online.sh)
```

### **wget**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/comp6062/usb-pi-os-launcher/main/install-online.sh)
```

---

## Features

- ✅ Interactive partition picker using `lsblk`  
- ✅ Excludes your live root and boot partitions for safety  
- ✅ Automatically (re)mounts the selected partition at `/mnt/pi-os-root`  
- ✅ Runs the OS with `systemd-nspawn` in three modes (A/B/C)  
- ✅ Desktop launcher with a 3D dark neon "USB Pi OS" icon  
- ✅ Works great for testing OS images, chroot-style repairs, and experimenting

---

## Requirements

- Raspberry Pi running **Raspberry Pi OS Bookworm (64-bit recommended)**
- `systemd-nspawn` (from the `systemd-container` package)
- A USB drive or SD card with a **Linux root filesystem** on one of its partitions  
  (should contain `/bin`, `/etc`, `/usr`, `/home`, etc.)

The installer will automatically install `systemd-container` if it's missing.

---

## Files in this repo

- `usb-pi-os.sh` – Main launcher script (menu-driven, picks drive and mode)
- `install-usb-pi-os-launcher.sh` – Installer that:
  - Installs the main script to `/usr/local/bin/usb-pi-os`
  - Installs a wrapper `/usr/local/bin/usb-pi-os-launch`
  - Installs the icon to `/usr/share/icons/usb-pi-os.png`
  - Creates `usb-pi-os.desktop` for the Raspberry Pi menu
- `install-online.sh` – One-line curl/wget installer
- `icon/usb-pi-os.png` – 3D dark neon "USB Pi OS" app icon

---

## Installation (manual / from clone)

Clone or copy this repo onto your Raspberry Pi:

```bash
git clone https://github.com/comp6062/usb-pi-os-launcher.git
cd usb-pi-os-launcher
```

Then run the installer:

```bash
chmod +x install-usb-pi-os-launcher.sh
sudo ./install-usb-pi-os-launcher.sh
```

The installer will:

1. Copy `usb-pi-os.sh` to `/usr/local/bin/usb-pi-os`
2. Install the icon to `/usr/share/icons/usb-pi-os.png`
3. Create `/usr/local/bin/usb-pi-os-launch` (wrapper that opens a terminal and runs `sudo usb-pi-os`)
4. Create `/usr/share/applications/usb-pi-os.desktop`
5. Optionally place a shortcut on your Desktop

---

## Usage

### Launch from the menu

After installation, open:

> **Menu → System Tools → USB Pi OS Launcher**

A terminal will open and prompt (via sudo) if elevation is needed.

You will see:

1. A list of available partitions (excluding your current root and boot)  
2. You choose which partition to treat as the OS root  
3. You choose one of three modes:

```text
1) Option A - Simple shell inside OS
2) Option B - Forced /bin/bash inside OS
3) Option C - Full boot (systemd) of OS
q) Quit
```

### Launch from the terminal

You can also run:

```bash
usb-pi-os-launch
```

or, directly (already root):

```bash
sudo usb-pi-os
```

---

## Modes explained

### Option A – Simple shell

- Starts a basic shell inside the selected root filesystem
- Good for quick checks, edits, and package management
- No full systemd boot

### Option B – Forced `/bin/bash`

- Same as A, but explicitly runs `/bin/bash`
- More robust if the default shell or login is broken

### Option C – Full boot (systemd)

- Boot the selected OS with its own `systemd`
- You’ll see boot logs, then a login prompt
- Great for testing services and "full OS" behavior  
- Exit by logging out or pressing `Ctrl+]` three times

---

## Safety notes

- The script **never offers your live root or boot partitions** as options.
- Only select partitions that you understand and expect to contain a Linux root filesystem.
- While a partition is being used by `systemd-nspawn`, avoid mounting it elsewhere.

---

## Uninstall

You can remove the installed pieces with:

```bash
sudo rm -f /usr/local/bin/usb-pi-os
sudo rm -f /usr/local/bin/usb-pi-os-launch
sudo rm -f /usr/share/applications/usb-pi-os.desktop
sudo rm -f /usr/share/icons/usb-pi-os.png
```

You may also delete `/mnt/pi-os-root` if you no longer need that mountpoint:

```bash
sudo rmdir /mnt/pi-os-root 2>/dev/null || true
```

---

## License

You are free to use, modify, and adapt this for your own Raspberry Pi setups. Add your preferred license (e.g., MIT) if publishing publicly on GitHub.
