#!/usr/bin/env bash
# ==============================================================================
# ROCKNIX Hardware Support Installer for RK3326 Clones (XF-45V / R36S Max 2 / DC45V)
# 1024x768 MIPI DSI, RK817 Audio Codec + Amp, Analog Multiplexer Joysticks
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================================="
echo " ROCKNIX Hardware Patch Installer for RK3326 Clone (XF-45V / R36S Max 2 / DC45V)"
echo "=========================================================================="

TARGET_DIR=""

# 1. Check if running directly on the handheld
if [ -d "/flash/extlinux" ] && [ -f "/flash/KERNEL" ]; then
    TARGET_DIR="/flash"
    echo "[+] Running directly on ROCKNIX handheld (/flash detected)."
    mount -o remount,rw /flash 2>/dev/null || true
fi

# 2. Check if running on PC with mounted SD card
if [ -z "$TARGET_DIR" ]; then
    for candidate in \
        "/run/media/$USER/ROCKNIX" \
        "/run/media/plex/ROCKNIX" \
        "/media/$USER/ROCKNIX" \
        "/mnt/ROCKNIX"; do
        if [ -d "$candidate" ] && [ -f "$candidate/KERNEL" ]; then
            TARGET_DIR="$candidate"
            echo "[+] Detected ROCKNIX boot partition at: $TARGET_DIR"
            break
        fi
    done
fi

# 3. Prompt user if not automatically found
if [ -z "$TARGET_DIR" ]; then
    echo "[-] ROCKNIX boot partition not automatically detected."
    echo -n "Please enter the mount path to your ROCKNIX boot partition: "
    read -r user_path
    if [ -d "$user_path" ] && [ -f "$user_path/KERNEL" ]; then
        TARGET_DIR="$user_path"
    else
        echo "[ERROR] '$user_path' is not a valid ROCKNIX boot partition (KERNEL not found)."
        exit 1
    fi
fi

echo "[+] Target directory: $TARGET_DIR"

# 4. Create backup of existing config
mkdir -p "$TARGET_DIR/backup_original"
if [ -f "$TARGET_DIR/extlinux/extlinux.conf" ] && [ ! -f "$TARGET_DIR/backup_original/extlinux.conf.bak" ]; then
    echo "[+] Backing up original extlinux.conf..."
    cp -v "$TARGET_DIR/extlinux/extlinux.conf" "$TARGET_DIR/backup_original/extlinux.conf.bak"
fi

# 5. Install patched Device Tree Blobs (DTBs)
echo "[+] Installing patched DTB files..."
cp -v "$SCRIPT_DIR/dtb/rk3326-gameconsole-eeclone.dtb" "$TARGET_DIR/rk3326-gameconsole-eeclone.dtb"
cp -v "$SCRIPT_DIR/dtb/rk3326-anbernic-rg351v.dtb" "$TARGET_DIR/rk3326-anbernic-rg351v.dtb"
cp -v "$SCRIPT_DIR/dtb/rk3326-gameconsole-r36s.dtb" "$TARGET_DIR/rk3326-gameconsole-r36s.dtb"
cp -v "$SCRIPT_DIR/dtb/rk3326-odroid-go2.dtb" "$TARGET_DIR/rk3326-odroid-go2.dtb"

# 6. Install MIPI DSI display overlay
echo "[+] Installing MIPI display overlay..."
mkdir -p "$TARGET_DIR/overlays"
cp -v "$SCRIPT_DIR/overlays/mipi-panel.dtbo" "$TARGET_DIR/overlays/mipi-panel.dtbo"

# 7. Install extlinux boot configuration
echo "[+] Configuring extlinux bootloader..."
mkdir -p "$TARGET_DIR/extlinux"
cp -v "$SCRIPT_DIR/extlinux/extlinux.conf" "$TARGET_DIR/extlinux/extlinux.conf"

sync

if [ "$TARGET_DIR" = "/flash" ]; then
    mount -o remount,ro /flash 2>/dev/null || true
fi

echo ""
echo "=========================================================================="
echo " [SUCCESS] All patches successfully applied!"
echo " Display: 1024x768 4-Lane MIPI DSI enabled"
echo " Audio:   RK817 Codec enabled + GPIO3_A7 Speaker Amp unmuted"
echo " Input:   SARADC Analog Multiplexer & Gamepad axes calibrated"
echo " Rumble:  Silent boot motor configuration active"
echo "=========================================================================="
echo "You can now safely unmount the SD card and boot your handheld."
