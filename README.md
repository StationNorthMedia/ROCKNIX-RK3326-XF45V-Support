# ROCKNIX Hardware Support for RK3326 Clones (XF-45V / R36S Max 2 / DC45V)

[![Platform](https://img.shields.io/badge/Platform-ROCKNIX%20%7C%20Mainline%20Linux-blue.svg)](https://rocknix.org/)
[![Hardware](https://img.shields.io/badge/Hardware-RK3326%20%7C%201024x768%20MIPI-orange.svg)](https://rocknix.org/)
[![Status](https://img.shields.io/badge/Status-Fully%20Working%20(Display%2C%20Audio%2C%20Amp%2C%20Joypad)-success.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Complete hardware support package for the popular **RK3326 EE-Clone handhelds (marketed as XF-45V, R36S Max 2, and DC45V)** running modern **ROCKNIX (Mainline Linux 7.x / aarch64)**.

This repository resolves all manufacturer-specific hardware discrepancies between these clone devices and generic RK3326 consoles (such as Anbernic RG351P or Odroid Go Advance). With these fixes, the **native 1024x768 display, audio codec, speaker amplifier, silent rumble motor, and calibrated analog joysticks** work out-of-the-box on standard ROCKNIX installations without requiring manual kernel compilation.

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

## 🔍 Root Cause Analysis: Why Stock ROCKNIX Failed

1. **Black Screen (Display Inactivity):**  
   Standard RK3326 firmware builds target 640×480 or 320×480 panels. Without the 4-lane MIPI DSI panel timing overlay (`mipi-panel.dtbo`) and panel reset/enable GPIO3 pin definitions, the screen received no clocks and remained pitch black.
2. **Audio Failure (*No soundcards found*):**  
   In generic DTBs, the internal RK817 sound card node was marked `status = "disabled"`, preventing ALSA from discovering the audio hardware.
3. **Muted Speaker Output:**  
   Even with the RK817 sound driver enabled, this device routes speaker audio through an external amplifier IC that remains hardware-muted until **GPIO3 Pin 7** is driven HIGH. Without this pin assigned to `enable-gpios` in the amplifier node, the speaker stays completely silent.
4. **Malfunctioning Analog Joysticks (Left Upper Stick Dead / Stiff):**  
   The generic clone DTB toggled the wrong enable GPIO (Pin 12 instead of **Pin 11**), scrambled the channel multiplexer order (`2 3 1 0` instead of `3 2 0 1`), and lacked axis inversion parameters (`invert-absx; invert-absry;`). Furthermore, the L2 and R2 trigger buttons were linked to wrong GPIO pins.
5. **Continuous Rumble Vibration on Boot:**  
   Inverted PWM polarity in generic device trees caused the vibration motor to buzz continuously starting from early kernel boot.

---

## 📦 Repository Structure

```text
ROCKNIX-RK3326-XF45V-Support/
├── dtb/
│   ├── rk3326-gameconsole-eeclone.dtb   # Primary fully patched device tree blob
│   ├── rk3326-anbernic-rg351v.dtb       # Compatibility fallback 1
│   ├── rk3326-gameconsole-r36s.dtb      # Compatibility fallback 2
│   └── rk3326-odroid-go2.dtb            # Compatibility fallback 3
├── overlays/
│   ├── mipi-panel.dtbo                  # Compiled 1024x768 MIPI DSI overlay
│   └── mipi-panel.dts                   # Source code for panel timings & init sequence
├── extlinux/
│   └── extlinux.conf                    # Bootloader config linking DTB & overlay
├── dts/
│   └── rk3326-gameconsole-eeclone.dts   # Complete decompiled, documented DTS source tree
├── tools/
│   └── importpanel.py                   # ROCKNIX generic-dsi panel tool
├── install.sh                           # 1-Click installer script (Linux PC or SSH)
├── LICENSE                              # MIT License
└── README.md                            # Documentation
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
4. The installer automatically detects the mounted `ROCKNIX` FAT32 boot partition, creates a backup of your original configuration, and installs all DTBs and overlays.

---

### Method 2: Manual Installation (Drag & Drop)

1. Open the FAT32 boot partition of your MicroSD card (labeled `ROCKNIX`).
2. Copy the files inside `dtb/` into the **root** of the boot partition.
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

## 🛠️ Technical Device Tree Specifications

### 1. Speaker Amplifier Node (`GPIO3_A7`)
```dts
audio-amplifier {
    compatible = "simple-audio-amplifier";
    enable-gpios = <&gpio3 7 GPIO_ACTIVE_HIGH>;
    pinctrl-0 = <&amp_gpio>;
    pinctrl-names = "default";
    sound-name-prefix = "Speaker Amp";
};

rk817-sound-amplified {
    status = "okay";
    simple-audio-card,aux-devs = <&audio_amp>;
};
```

### 2. Analog Multiplexer & Joypad Driver (`rocknix-singleadc-joypad`)
```dts
joypad {
    compatible = "rocknix-singleadc-joypad";
    amux-count = <4>;
    amux-channel-mapping = <3 2 0 1>;  /* Ch3=LeftX, Ch2=LeftY, Ch0=RightX, Ch1=RightY */
    amux-en-gpios = <&gpio2 11 GPIO_ACTIVE_HIGH>;
    amux-a-gpios  = <&gpio2 16 GPIO_ACTIVE_HIGH>;
    amux-b-gpios  = <&gpio2 15 GPIO_ACTIVE_HIGH>;
    invert-absx;
    invert-absry;
    
    /* Shoulder & Function Keys */
    sw20 { label = "GPIO TOP-RIGHT2"; gpios = <&gpio3 0 GPIO_ACTIVE_LOW>;  linux,code = <0x139>; }; /* R2 */
    sw21 { label = "GPIO TOP-LEFT2";  gpios = <&gpio3 6 GPIO_ACTIVE_LOW>;  linux,code = <0x138>; }; /* L2 */
    sw13 { label = "GPIO BTN_FN";      gpios = <&gpio3 26 GPIO_ACTIVE_LOW>; linux,code = <0x13C>; }; /* FN */
};
```

---

## 🤝 Upstream Contribution

This repository is designed to serve as a reference for upstream inclusion into the official [ROCKNIX Distribution](https://github.com/ROCKNIX/distribution). The provided `dts/rk3326-gameconsole-eeclone.dts` can be integrated directly into ROCKNIX kernel trees for RK3326 boards.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE). Device Tree source files are licensed under GPL-2.0-or-later matching the Linux kernel.
