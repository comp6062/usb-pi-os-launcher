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
bash <(curl -s https://raw.githubusercontent.com/YOUR-USER/usb-pi-os-launcher/main/install-online.sh)
```

### **wget**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/YOUR-USER/usb-pi-os-launcher/main/install-online.sh)
```

---

## Features

- ✅ Interactive partition picker using `lsblk`  
- ✅ Excludes your live root and boot partitions for safety  
- ✅ Automatically (re)mounts the selected partition at `/mnt/pi-os-root`  
- ✅ Runs the OS with `systemd-nspawn` in three modes (A/B/C)  
- ✅ Desktop launcher with a 3D dark neon "USB Pi OS" icon  
- ✅ Works great for testing OS images, chroot-style repairs, and experimenting
