# ROCKNIX Hardware Support for RK3326 Clones (Batlexp G350 / XF-45V)

[![Platform](https://img.shields.io/badge/Platform-ROCKNIX%20%7C%20Mainline%20Linux-blue.svg)](https://rocknix.org/)
[![Hardware](https://img.shields.io/badge/Hardware-RK3326%20%7C%201024x768%20MIPI-orange.svg)](https://rocknix.org/)
[![Status](https://img.shields.io/badge/Status-Fully%20Working%20(Display%2C%20Audio%2C%20Amp%2C%20Joypad)-success.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Vollständiges Hardware-Support-Paket für den populären **RK3326 EE-Clone (Batlexp G350 / XF-45V)** unter dem modernen **ROCKNIX (Mainline Linux 7.x / aarch64)**.

Dieses Repository behebt alle herstellerspezifischen Abweichungen des Handhelds gegenüber Standard-Geräten (wie Anbernic RG351P oder Odroid Go Advance), sodass **Display, Soundkarte, Lautsprecher-Verstärker, Rumble-Motor und beide Analog-Joysticks** sofort und ohne Kernel-Kompilierung auf jedem Standard-ROCKNIX funktionieren.

---

## 🎮 Hardware-Profil des Geräts

| Komponente | Spezifikation & Hardware-Verdrahtung |
| :--- | :--- |
| **SoC** | Rockchip RK3326 (Quad-Core ARM Cortex-A35 @ 1.3 - 1.5 GHz) |
| **GPU** | ARM Mali-G31 MP2 (GLES 3.2 via Wayland/Sway & Panfrost/libmali) |
| **RAM** | 1 GB DDR3L |
| **Display** | **1024×768 (4:3)** 4-Lane MIPI DSI Panel (`rocknix,generic-dsi`) |
| **Display GPIOs** | Reset = `GPIO3_D3` (Pin 27), Enable = `GPIO3_A3` (Pin 3) |
| **Audio-Codec** | Rockchip RK817 Audio Codec (`rk817-sound-amplified`, I2S) |
| **Lautsprecher-Amp** | Externer Class-D Verstärker gesteuert über **`GPIO3_A7` (Pin 7)** |
| **Analog-Joysticks** | Single SARADC Kanal 1 über 4-Kanal Analog-Multiplexer (AMUX) |
| **AMUX Steuerleitungen**| Enable = **`GPIO2_B3` (Pin 11)**, Sel A = `GPIO2_B8` (Pin 16), Sel B = `GPIO2_B7` (Pin 15) |
| **Kanal-Mapping** | Ch 3 = Links X, Ch 2 = Links Y, Ch 0 = Rechts X, Ch 1 = Rechts Y |
| **Trigger / Buttons** | L2 = `GPIO3_A6` (Pin 6), R2 = `GPIO3_A0` (Pin 0), FN = `GPIO3_D2` (Pin 26) |

---

## 🔍 Warum Standard-ROCKNIX vorher nicht funktionierte

1. **Schwarzer Bildschirm:**
   Standard-ROCKNIX für RK3326 ist für 640×480 oder 320×480 Panels vorkonfiguriert. Ohne den 4-Lane MIPI DSI Initialisierungs-Overlay und die korrekten GPIO3-Steuerpins blieb das Panel komplett dunkel.
2. **Kein Ton (*No soundcards found*):**
   Im generischen Boot-DTB stand der interne Soundknoten auf `status = "disabled"`.
3. **Lautsprecher stumm trotz laufendem ALSA:**
   Selbst wenn der RK817-Codec aktiv war, schaltete das Handheld den Lautsprecher erst frei, wenn **GPIO3 Pin 7** auf HIGH gezogen wurde. Fehlt dieser Pin im Device Tree, bleibt der Lautsprecher hardwareseitig gemutet.
4. **Fehlfunktion der Analog-Joysticks (insb. linker oberer Stick):**
   Das generische Clone-DTB steuerte die Multiplexer-Freigabe fälschlicherweise über Pin 12 statt **Pin 11**, hatte vertauschte ADC-Kanal-Reihenfolgen (`2 3 1 0` statt `3 2 0 1`) und fehlende Achseninversionen (`invert-absx`, `invert-absry`). Zudem lagen L2 und R2 auf falschen GPIO-Pins.
5. **Dauerbrummen beim Booten:**
   Der Rumble-Vibrationsmotor wurde durch invertierte Polarität beim Start ununterbrochen angesteuert.

---

## 📦 Inhalt dieses Repositories

```text
ROCKNIX-RK3326-Clone-XF45V-G350-Support/
├── dtb/
│   ├── rk3326-gameconsole-eeclone.dtb   # Primäres, voll gepatchtes DTB
│   ├── rk3326-anbernic-rg351v.dtb       # Fallback 1
│   ├── rk3326-gameconsole-r36s.dtb      # Fallback 2
│   └── rk3326-odroid-go2.dtb            # Fallback 3
├── overlays/
│   ├── mipi-panel.dtbo                  # Vorkompilierter 1024x768 MIPI DSI Overlay
│   └── mipi-panel.dts                   # Quelltext der Panel-Timings & Init-Sequenz
├── extlinux/
│   └── extlinux.conf                    # Bootloader-Konfiguration (lädt DTB & Overlay)
├── dts/
│   └── rk3326-gameconsole-eeclone.dts   # Vollständiger, dokumentierter DTS-Quellbaum
├── tools/
│   └── importpanel.py                   # ROCKNIX Generic-DSI Panel-Tool
├── install.sh                           # 1-Klick Installer (Linux PC oder SSH Handheld)
├── LICENSE                              # MIT Lizenz
└── README.md                            # Diese Dokumentation
```

---

## 🚀 Installation

### Methode 1: Automatisch via `install.sh` (Empfohlen)

1. Stecke deine ROCKNIX MicroSD-Karte in deinen PC.
2. Klone oder lade dieses Repository herunter:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ROCKNIX-RK3326-Clone-XF45V-G350-Support.git
   cd ROCKNIX-RK3326-Clone-XF45V-G350-Support
   ```
3. Starte das Installationsskript:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
4. Das Skript erkennt die gemountete ROCKNIX-Partition automatisch, sichert deine bestehende Konfiguration und kopiert alle DTBs und Overlays an die richtige Stelle.

---

### Methode 2: Manuelle Installation (Drag & Drop)

1. Öffne die FAT32-Boot-Partition deiner MicroSD-Karte (Name meist `ROCKNIX`).
2. Kopiere die Dateien aus `dtb/` direkt in das **Hauptverzeichnis** der Boot-Partition.
3. Kopiere `overlays/mipi-panel.dtbo` in den Ordner `overlays/` auf der Boot-Partition.
4. Ersetze `extlinux/extlinux.conf` durch die Datei aus diesem Repository.
5. Führe einen sauberen Auswurf (`sync` / Auswerfen) durch und starte das Gerät.

---

### Methode 3: Direkt auf dem Handheld via SSH

Falls das Handheld bereits läuft und im Netzwerk erreichbar ist:
```bash
mount -o remount,rw /flash
# Dateien nach /flash und /flash/overlays kopieren
sync
mount -o remount,ro /flash
reboot
```

---

## 🛠️ Technische Details der Patches (Device Tree)

### 1. Audio-Verstärker (GPIO3_A7)
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
    /* ... */
};
```

### 2. Analog-Multiplexer & Joysticks (`rocknix-singleadc-joypad`)
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
    
    /* Shoulder Triggers */
    sw20 { label = "GPIO TOP-RIGHT2"; gpios = <&gpio3 0 GPIO_ACTIVE_LOW>;  linux,code = <0x139>; }; /* R2 */
    sw21 { label = "GPIO TOP-LEFT2";  gpios = <&gpio3 6 GPIO_ACTIVE_LOW>;  linux,code = <0x138>; }; /* L2 */
    sw13 { label = "GPIO BTN_FN";      gpios = <&gpio3 26 GPIO_ACTIVE_LOW>; linux,code = <0x13C>; }; /* FN */
};
```

---

## 🤝 Upstream Contribution (Für ROCKNIX Maintainer)

Dieses Repository kann als Grundlage für einen Pull Request an das offizielle [ROCKNIX Distribution Repository](https://github.com/ROCKNIX/distribution) verwendet werden. Die Datei `dts/rk3326-gameconsole-eeclone.dts` kann direkt in den ROCKNIX Linux-Kernel-Build-Tree für RK3326 integriert werden.

---

## 📜 Lizenz

Dieses Projekt steht unter der [MIT Lizenz](LICENSE). Die Device Tree Quelltexte unterliegen der GPL-2.0-or-later des Linux-Kernels.
