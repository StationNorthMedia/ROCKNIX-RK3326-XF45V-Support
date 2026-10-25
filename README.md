# ROCKNIX Hardware Support for RK3326 Clones (XF-45V / R36S Max 2 / DC45V)

[![Platform](https://img.shields.io/badge/Platform-ROCKNIX%20%7C%20Mainline%20Linux-blue.svg)](https://rocknix.org/)
[![Hardware](https://img.shields.io/badge/Hardware-RK3326%20%7C%201024x768%20MIPI-orange.svg)](https://rocknix.org/)
[![Status](https://img.shields.io/badge/Status-Fully%20Working%20(Display%2C%20Audio%2C%20Amp%2C%20Joypad)-success.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Dedicated hardware support package for **RK3326 clone handhelds (marketed as XF-45V, R36S Max 2, and DC45V)** running modern **ROCKNIX (Mainline Linux 7.x / aarch64)**.

This repository provides a **dedicated Device Tree Blob (`rk3326-xf45v.dtb`)** along with panel overlays and boot configurations, resolving all hardware discrepancies so that the **native 1024x768 display, audio codec, speaker amplifier, silent rumble motor, and calibrated analog joysticks** function out-of-the-box on standard ROCKNIX installations without custom kernel compilation.

---

## 🎮 Device Hardware Profile

| Component | Specification & Hardware Wiring |
| :--- | :--- |
| **SoC** | Rockchip RK3326 (Quad-Core ARM Cortex-A35 @ 1.3 - 1.5 GHz) |
| **GPU** | ARM Mali-G31 MP2 (GLES 3.2 via Wayland/Sway & Panfrost/libmali) |
| **RAM** | 1 GB DDR3L |
| **Display** | **1024×768 (4:3)** 4-Lane MIPI DSI Panel (`rocknix,generic-dsi`) |
| **Display GPIOs** | Reset = `GPIO3_D3` (Pin 27), Enable = `GPIO3_A3` (Pin 3) |
| **Audio Codec** | Rockchip RK817 Audio Codec (`rk817-sound-amplified`, I2S) |
| **Speaker Amp** | External Class-D Amplifier gated via **`GPIO3_A7` (Pin 7)** |
| **Analog Joysticks** | Single SARADC Channel 1 via 4-Channel Analog Multiplexer (AMUX) |
| **AMUX Control Lines** | Enable = **`GPIO2_B3` (Pin 11)**, Sel A = `GPIO2_B8` (Pin 16), Sel B = `GPIO2_B7` (Pin 15) |
| **Channel Mapping** | Ch 3 = Left X, Ch 2 = Left Y, Ch 0 = Right X, Ch 1 = Right Y |
| **Axis Inversions** | `invert-absx;` and `invert-absry;` active |
| **Triggers / Buttons** | L2 = `GPIO3_A6` (Pin 6), R2 = `GPIO3_A0` (Pin 0), FN = `GPIO3_D2` (Pin 26) |

---

## 🌐 Network & Connectivity Status (Wi-Fi & USB Networking)

### ⚠️ Internal Wi-Fi (AIC8800) — Currently NOT Working
* **Status:** Inactive under modern mainline Linux / ROCKNIX.
* **Technical Cause:** The on-board wireless chip is an **Aicsemi AIC8800**. It currently relies on proprietary vendor kernel drivers compiled strictly for legacy Linux 4.4.189 kernels (found on stock darkOS / EmuELEC). No working mainline Linux driver exists yet in Linux 7.x.

### ✅ Supported Network Solutions

1. **External USB Wi-Fi Dongle (OTG Port):**
   * Standard USB Wi-Fi dongles (e.g., Realtek `RTL8188EUS`, `RTL8192EU`, MediaTek `MT7601U`) work plug-and-play via the USB-C OTG port.
   * *Hardware Tip:* 300 Mbps high-power dongles (like TP-Link TL-WN823N) draw up to 500 mA, which can cause voltage brownouts on battery power. We recommend compact **150 Mbps Nano USB sticks** (e.g., TL-WN725N) or a solid, short USB-C adapter to prevent disconnects.
2. **USB Gadget Ethernet / PC Tethering (Recommended & Rock-Solid):**
   * Simply connect a USB-C data cable from your PC to the handheld's **OTG port**.
   * ROCKNIX automatically initializes as a USB Ethernet gadget (`rndis_host` / `cdc_ether`).
   * Provides immediate internet sharing, high-speed file transfers, and instant SSH access at IP `169.254.170.2`.

---

## 🔍 Root Cause Analysis: Why Stock ROCKNIX Failed

1. **Black Screen (Display Inactivity):**  
   Standard RK3326 builds target 640×480 or 320×480 panels. Without the 4-lane MIPI DSI panel timing overlay (`mipi-panel.dtbo`) and panel reset/enable GPIO3 pin definitions, the screen received no clocks and remained pitch black.
2. **Audio Failure (*No soundcards found*):**  
   In generic DTBs, the internal RK817 sound card node was marked `status = "disabled"`, preventing ALSA from discovering the audio hardware.
3. **Muted Speaker Output:**  
   Even with the RK817 sound driver enabled, this device routes speaker audio through an external amplifier IC that remains hardware-muted until **GPIO3 Pin 7** is driven HIGH. Without this pin assigned to `enable-gpios` in the amplifier node, the speaker stays completely silent.
4. **Malfunctioning Analog Joysticks (Left Upper Stick Dead / Stiff):**  
   The generic clone DTB toggled the wrong enable GPIO (Pin 12 instead of **Pin 11**), scrambled the channel multiplexer order (`2 3 1 0` instead of `3 2 0 1`), and lacked axis inversion parameters (`invert-absx; invert-absry;`). Furthermore, the L2 and R2 trigger buttons were linked to wrong GPIO pins.
5. **Continuous Rumble Vibration on Boot:**  
   Inverted PWM polarity in generic device trees caused the vibration motor to buzz continuously starting from early kernel boot.

---

## 📦 Dedicated DTB vs. Overwriting Original Files

This package does **not** simply overwrite stock files blindly:
* It introduces a **dedicated device tree identity**: **`rk3326-xf45v.dtb`**.
* The bootloader config (`extlinux/extlinux.conf`) explicitly sets `FDT /rk3326-xf45v.dtb`.
* The automated installer saves existing boot files into `backup_original/`.
* Compatibility DTBs (`rk3326-gameconsole-eeclone.dtb`, `rg351v.dtb`, etc.) are also updated so that fallback boot entries or secondary profiles boot smoothly with working hardware.

```text
ROCKNIX-RK3326-XF45V-Support/
├── dtb/
│   ├── rk3326-xf45v.dtb                 # Dedicated primary device tree blob
│   ├── rk3326-gameconsole-eeclone.dtb   # Clone fallback target
│   ├── rk3326-anbernic-rg351v.dtb       # Profile fallback 1
│   ├── rk3326-gameconsole-r36s.dtb      # Profile fallback 2
│   └── rk3326-odroid-go2.dtb            # Profile fallback 3
├── overlays/
│   ├── mipi-panel.dtbo                  # Compiled 1024x768 MIPI DSI overlay
│   └── mipi-panel.dts                   # Source code for panel timings & init sequence
├── extlinux/
│   └── extlinux.conf                    # Bootloader config setting FDT /rk3326-xf45v.dtb
├── dts/
│   ├── rk3326-xf45v.dts                 # Dedicated DTS source tree
│   └── rk3326-gameconsole-eeclone.dts   # Decompiled reference source tree
├── tools/
│   └── importpanel.py                   # ROCKNIX generic-dsi panel tool
├── install.sh                           # 1-Click installer script (Linux PC or SSH)
├── LICENSE                              # MIT License
└── README.md                            # Complete documentation
```

---

## 🚀 Installation Guide

### Method 1: Automatic Installation via `install.sh` (Recommended)

1. Insert your ROCKNIX MicroSD card into your PC.
2. Clone this repository:
   ```bash
   git clone https://github.com/StationNorthMedia/ROCKNIX-RK3326-XF45V-Support.git
   cd ROCKNIX-RK3326-XF45V-Support
   ```
3. Run the installer:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
4. The installer automatically detects the mounted `ROCKNIX` FAT32 boot partition, backs up the previous configuration, and installs all dedicated DTBs and overlays.

---

### Method 2: Manual Installation (Drag & Drop)

1. Open the FAT32 boot partition of your MicroSD card (labeled `ROCKNIX`).
2. Copy the files inside `dtb/` into the **root** directory of the boot partition.
3. Copy `overlays/mipi-panel.dtbo` into the `overlays/` directory on the boot partition.
4. Replace `extlinux/extlinux.conf` with the file from `extlinux/` in this repository.
5. Safely unmount/eject the SD card and insert it into your handheld.

---

### Method 3: Direct Installation on Handheld via SSH

If your device is already booted and connected via USB/Wi-Fi:
```bash
mount -o remount,rw /flash
# Copy dtb files to /flash and mipi-panel.dtbo to /flash/overlays/
sync
mount -o remount,ro /flash
reboot
```

---

## 🤝 How to Notify & Upstream to the ROCKNIX Project

We want the official ROCKNIX team to include this device out-of-the-box in future releases! Here is how to submit it:

1. **GitHub Pull Request / Issue:**
   * Repository: [https://github.com/ROCKNIX/distribution](https://github.com/ROCKNIX/distribution)
   * Submit an issue or PR with the file `dts/rk3326-xf45v.dts` and `overlays/mipi-panel.dtbo`.
   * Reference the display timings and GPIO pinout documented in this README.
2. **ROCKNIX Discord Community:**
   * Join the official ROCKNIX Discord (linked at [rocknix.org](https://rocknix.org)).
   * Share this repository in the `#rk3326` or `#development` channels. The maintainers actively integrate tested device trees for newly released clone models.
3. **Community Forums (Reddit / RetroHandhelds):**
   * Share this repository on [r/SBCGaming](https://reddit.com/r/SBCGaming) for users struggling with black screens on the XF-45V / R36S Max 2 / DC45V.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE). Device Tree source files are licensed under GPL-2.0-or-later matching the Linux kernel.
