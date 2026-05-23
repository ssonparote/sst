# Sufni Suspension Telemetry (SST) — Project Context

## Project Overview

Building a custom MTB suspension telemetry system based on the open-source **Sufni Suspension Telemetry (SST)** project by sghctoma. The build uses a mix of stock SST hardware (AS5600 for rear linkage) and a custom sensor approach (SoftPot for fork), with mechanical mounting designed to work without removing any pivot bolts.

**GitHub repos:**
- Upstream original: `https://github.com/sghctoma/sst`
- User fork: `https://github.com/ssonparote/sst`

**Community threads:**
- MTBR (most active, Toma posts here): `mtbr.com/threads/sufni-suspensiont-telemetry-an-open-source-suspension-telemetry-system.1220806/`
- Vital MTB DIY thread: `vitalmtb.com/forums/The-Hub,2/DIY-mtb-telemetry-data,11126`
- MTB-News.de (German, Toma also posts here): `mtb-news.de/forum/t/diy-telemetrie-data-acquisition-system.971652/`

**Deployment:**
- Pi server IP: 192.168.0.69
- Dashboard URL: https://sst.caddy.local

---

## Hardware Stack (confirmed build order, bottom to top)

1. **Pimoroni LiPo Shim (PIM557)** — soldered to Pico underside pins (VBUS, VSYS, GND, 3V3_EN, 3V3_OUT). Charging via Pico USB. ✅ installed
2. **Raspberry Pi Pico WH** — male headers pointing down into Adalogger ✅
3. **Adafruit PicoWbell Adalogger** — stacked above Pico via female socket headers. Has: MicroSD (SDIO), RTC (CR1220 installed ✅), STEMMA QT connector hardwired to GP4/GP5

## Hardware Inventory (confirmed on hand)

| Component | Part | Status |
|---|---|---|
| Microcontroller | Raspberry Pi Pico WH | ✅ in stack |
| Logger/RTC | Adafruit PicoWbell Adalogger | ✅ in stack |
| Power management | Pimoroni LiPo Shim PIM557 | ✅ installed |
| Battery | Li-ion 18650 3.7V 2.2Ah (with connector) | ✅ on hand |
| Fork sensor | Spectra Symbol SP-L-0200-103-1%-RLU (200mm, 10kΩ, 1%) | ✅ on hand |
| Rear sensor | AS5600 hall effect rotary encoder + magnet | ✅ on hand, headers soldered |
| Display | NFP1315-45A (SSD1306-equivalent OLED, 128×64, I2C) | ✅ breadboarded |
| IMU | Adafruit LSM6DSOX #4438 STEMMA QT | 🔄 ordered |
| MicroSD card | Any Class 10 A1 | ✅ on hand |
| RTC backup | CR1220 coin cell | ✅ installed |
| Buttons | 6mm tactile switches (from Parts Pal) | ✅ on hand |
| Status LEDs | 5mm red + green (from Parts Pal) | ✅ on hand |
| Resistors | 560Ω (LED), 100Ω (SoftPot series), 100kΩ (SoftPot pull-down), 1kΩ | ✅ on hand / ordered |
| Capacitors | 100nF ceramic (SoftPot filter) | ✅ on hand (Parts Pal) |

---

## Confirmed GPIO Pinout

| GPIO | Pico Pin | Function | Connected To | Notes |
|---|---|---|---|---|
| GP2 | 4 | PIO I2C SDA | SSD1306 display | Software I2C, already wired |
| GP3 | 5 | PIO I2C SCL | SSD1306 display | Software I2C, already wired |
| GP4 | 6 | I2C0 SDA | LSM6DSOX IMU | Adalogger STEMMA QT hardwired |
| GP5 | 7 | I2C0 SCL | LSM6DSOX IMU | Adalogger STEMMA QT hardwired |
| GP6 | 9 | GPIO INPUT | Button LEFT | 6mm tactile, moved from GP4 |
| GP7 | 10 | GPIO INPUT | Button RIGHT | 6mm tactile, moved from GP5 |
| GP10 | 14 | GPIO OUTPUT | LED recording (red) | 560Ω series resistor |
| GP11 | 15 | GPIO OUTPUT | LED WiFi (green) | 560Ω series resistor |
| GP14 | 19 | I2C1 SDA | AS5600 rear shock | |
| GP15 | 20 | I2C1 SCL | AS5600 rear shock | |
| GP17 | 22 | SDIO CLK | MicroSD | Adalogger internal |
| GP18 | 24 | SDIO CMD | MicroSD | Adalogger internal |
| GP19 | 25 | SDIO D0 | MicroSD | Adalogger internal |
| GP20 | 26 | SDIO D1 | MicroSD | Adalogger internal |
| GP21 | 27 | SDIO D2 | MicroSD | Adalogger internal |
| GP22 | 29 | SDIO D3 | MicroSD | Adalogger internal |
| GP26 | 31 | ADC0 | SoftPot wiper (fork) | 100Ω series + 100nF to GND + 100kΩ pull-down |

Free GPIOs: GP0/GP1 (UART debug), GP8, GP9, GP12, GP13, GP16, GP27, GP28

---

## Firmware Changes Required (vs stock SST)

- Move buttons from GP4/GP5 → GP6/GP7
- Replace fork AS5600 I2C read (GP8/GP9) with SoftPot ADC read on GP26, scaled 0.0–1.0
- Add LSM6DSOX IMU init and read on I2C0 (GP4/GP5 via STEMMA QT)
- Add status LED outputs on GP10 (recording) and GP11 (WiFi)
- WiFi: use `pico_cyw43_arch_lwip_poll` (NOT `threadsafe_background` — causes deadlocks)

---

## SoftPot Wiring Detail

**Part:** Spectra Symbol SP-L-0200-103-1%-RLU
**Connector:** RLU = 3-pin female latch-up housing on sensor tail
**Pinout:** Pin 1 = End A (voltage high), Pin 2 = Wiper output, Pin 3 = End B (GND)

**Protection circuit (on SoftPot sensor perfboard):**

```
3.3V ──→ SoftPot Pin 1 (End A)
GND  ──→ SoftPot Pin 3 (End B)
SoftPot Pin 2 (Wiper) ──→ 100Ω ──→ GP26
                        └──→ 100nF ──→ GND
                        └──→ 100kΩ ──→ GND
```

- 100Ω: protects ADC if wiper shorts to rail
- 100nF: RC low-pass filter (~16kHz cutoff with 100Ω)
- 100kΩ: pull-down, prevents float when stylus off active area (<2% non-linearity)
- No-contact state reads ~0V (GND via pull-down)
- Travel direction (which end reads high) correctable in firmware scaling

**4-pin JST-GH connector standardization (all sensors use 4-pin):**

SoftPot (3 wires + 1 NC):
- Pin 1: 3.3V → SoftPot End A
- Pin 2: GND → SoftPot End B
- Pin 3: Signal (wiper) → GP26 via protection circuit
- Pin 4: NC

AS5600 (4 wires):
- Pin 1: 3.3V → VCC
- Pin 2: GND
- Pin 3: SDA → GP14
- Pin 4: SCL → GP15

Color code cables to distinguish sensors (e.g. blue bundle for AS5600, red for SoftPot).

---

## Connector Architecture

**External connectors:** JST-GH 1.25mm, 4-pin standardized
- Sensor end: GHR-04V female crimp housing in 3D-printed bracket pocket
- Box panel end: GHR-04V female crimp housing in 3D-printed panel pocket
- Patch cable: GHR-04V female on both ends (female-female)
- Board end (wing/sensor perfboard): BM04B-GHS-TBT SMD male header

**Internal (board to panel):** short wire tails from BM04B header on Perma-Proto wing board to GHR female housing in panel pocket

**STEMMA QT (IMU):** JST SH 1.0mm 4-pin, pre-made 150mm cable, plug-and-play

---

## Physical Build Architecture

**Main control box:**
- Stack (LiPo shim → Pico WH → Adalogger) as self-contained unit
- Adafruit half-size Perma-Proto (#1609) as wing board alongside stack
  - Short wires reflowed into Adalogger duplicate pad stubs for connection
  - Power rails carry 3.3V and GND for all connections
  - BM04B-GHS-TBT SMD headers for sensor cable connections (×2: AS5600 + SoftPot)
  - Button and LED connections
- 3D-printed enclosure with Garmin quarter-turn mount on bottom
- GHR female JST-GH housings in 3D-printed panel pockets on enclosure wall
- Rubber grommets at cable wall penetrations

**Sensor modules:**
- ElectroCookie solderable perfboard, one per sensor
- BM04B-GHS-TBT SMD header for cable connection
- Protection circuit components (SoftPot only)
- 3D-printed bracket holds perfboard and mounts to bike

---

## Crimp Tool & Connectors

- **Crimper:** PEBA kit (includes crimper + JST-GH housings + contacts, AWG 32-22)
- **Wire:** 28AWG silicone multi-color (TUOFENG or BNTECHGO, 6-10 colors)
- **Sleeving:** 1/8" expandable PET braided sleeving for sensor cable runs
- **PCB headers:** BM04B-GHS-TBT (Mouser, qty 8)

---

## I2C Address Map

| Device | Bus | GPIO | Address |
|---|---|---|---|
| LSM6DSOX IMU | I2C0 (STEMMA QT) | GP4/GP5 | 0x6A or 0x6B |
| AS5600 rear shock | I2C1 | GP14/GP15 | 0x36 |
| SSD1306 display | PIO I2C | GP2/GP3 | 0x3C or 0x3D |

No address conflicts.

---

## Next Steps

1. [ ] Place Mouser order (BM04B headers, LSM6DSOX, Perma-Proto, resistors)
2. [ ] Place Amazon order (PEBA crimp kit, 28AWG wire, 1/8" braided sleeving, ElectroCookie boards, helping hands)
3. [ ] Flash stock SST firmware, validate display and I2C scan
4. [ ] Wire AS5600 to GP14/GP15, validate rear shock channel in dashboard
5. [ ] Wire SoftPot with protection circuit, modify firmware for ADC read on GP26
6. [ ] Move button pins to GP6/GP7 in firmware
7. [ ] Add status LED outputs GP10/GP11 in firmware
8. [ ] Validate full pipeline: both sensors → SD → WiFi → gosst → dashboard (Pi at 192.168.0.69)
9. [ ] Design 3D printed bench test jigs (AS5600 rotation jig, SoftPot sliding jig)
10. [ ] Design enclosure and sensor brackets in OpenSCAD
11. [ ] Add LSM6DSOX IMU integration once sensor pipeline validated
12. [ ] Mount on bike, validate real-world data

---

## Software Stack

```
firmware/          C on Pico W — sensor reading, SD card logging, WiFi upload
gosst/             Go backend — processes raw data, applies kinematics/leverage curve
dashboard/         Web UI — travel plots, velocity histograms, balance analysis
Docker + Caddy     Serving layer
```

### Key SST feature — leverage curve / kinematics
SST calculates suspension travel from sensor angle using **bike-specific linkage geometry** (pivot locations and link lengths defined on a photo of the bike, similar to Linkage X3). This means:
- Nonlinear linkage sweeps (e.g. counter-rotating rocker on Canyon Torque) are corrected in software
- Sensor can be placed at any accessible pivot — gosst unwinds the kinematics
- Each bike needs its geometry entered once in gosst's bike setup

### Important firmware note (from Toma on MTB-News.de)
WiFi on the Pico W is unstable with persistent connections. Use:
- `pico_cyw43_arch_lwip_poll` (NOT `threadsafe_background` — causes deadlocks)
- Connect/disconnect WiFi on demand rather than keeping persistent connection

---

## Target Bikes

### Transition Regulator CX (e-MTB)
- 150mm rear travel, 160mm fork, trunnion shock
- Linkage pivot angles likely small (~15–20°) — check all pivots by hand before committing to placement. Some pivots sweep more than they appear static.
- AS5600 resolution at 20°: ~228 counts — acceptable but find the highest-angle accessible pivot

### Canyon Torque
- Counter-rotating rocker linkage — large angular sweep but nonlinear relative to wheel travel
- Leverage curve correction handled by gosst kinematics — pick the pivot with most angular movement
- Better candidate for AS5600 resolution

---

## AS5600 Mechanical Mount Design

**Core concept:** Sensor mounts over the pivot bolt hex head without removing any bolts.

**Assembly (outside to inside):**
1. **Tapered internal Allen socket** — 3D printed, engages pivot bolt hex head. Taper angle ~5–8° included, self-centers on hex under preload. This is the **rotating piece** (moves with linkage/bolt head).
2. **Magnet** — on small axial boss protruding beyond bearing face. Boss keeps magnet clear of any metallic bearing components. Magnet tip sits 1–2mm from AS5600 face.
3. **Igus iglide J spherical plain bearing** — between rotating socket piece and stationary sensor body. Handles both rotation and angular misalignment between printed parts and true pivot axis. All-polymer = non-magnetic (critical — steel races distort AS5600 field).
4. **Stationary sensor body** — holds AS5600 PCB. Held from rotating by zip-tie arm.
5. **Zip-tie arm** — attached inboard to linkage, provides preload keeping socket engaged on hex head, and anti-rotation for sensor body. Includes a spacer to control bend angle and prevent over-stress at zip-tie point.

**Key notes:**
- Do NOT use standard 608 steel bearings — steel races distort AS5600 magnetic field
- Igus iglide J: all-polymer spherical plain bearing, self-lubricating, non-magnetic, extremely low profile, adequate for zero-load slow-rotation application
- Hex socket fit: ~0.1–0.15mm clearance per flat — push-on by hand, no slop
- Print socket slightly undersized, sand/file to fit (hex socket accuracy hard to nail first print)
- Add small secondary preload spring between arm and sensor body if linkage geometry could push arm outward at any travel point

---

## SoftPot Mechanical Mount (fork)
- Stylus/wiper contact point on fork stanchion
- Stylus travel must be parallel to stanchion for linearity
- Mount SoftPot to fork leg with aluminum backing plate
- Reference: Hackaday project `hackaday.io/project/2376` used this approach with Igus linear slide
- Spectra Symbol SoftPots are what Motion Instruments use in professional fork sensors
- **Future:** If SoftPot works well on fork, may use same approach for rear (replacing AS5600 mount). TBD.

---

## Related Projects / Reference Repos

| Repo | Notes |
|---|---|
| `nathancrz/MTB-telemetry` | Python, uses linear pots + ADS1115 ADC. Good reference for ADC-to-mm calibration |
| `porast1/suspension-telemetry` | STM32, FreeRTOS, DMA ADC at 200Hz. Good signal processing reference |
| `JoelKuula/Suspension_telemetry_public` | Has 3D-printable STL bracket files |
| `Finnitio/sst` | Another SST fork, check for modifications |
