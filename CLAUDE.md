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

---

## Hardware Inventory (confirmed on hand)

| Component | Part | Role |
|---|---|---|
| Microcontroller | Raspberry Pi Pico WH (2022, with headers) | Main DAQ unit |
| Fork sensor | Spectra Symbol SoftPot (linear membrane pot) | Fork travel via ADC |
| Rear sensor | AS5600 hall effect rotary sensor + included magnet | Linkage rotation via I2C |
| Display | NFP1315-45A (SSD1306-equivalent OLED, 128×64, I2C) | Status display on DAQ enclosure — battery level, recording state, WiFi status |
| Power | Pico W LiPo shim + battery | Field use (USB for bench testing) |

---

## Sensor Architecture

### Rear Shock — AS5600 (stock SST firmware path)
- **Interface:** I2C (SDA, SCL, 3.3V, GND) — 4 wires
- **Why I2C not ADC:** Pico ADC has only 7.9 ENOB (effective bits) — too low for precision angle. AS5600 gives 12-bit over I2C.
- **Resolution at small angles:** At 20° sweep → ~228 counts → ~0.66mm/count over 150mm travel. Acceptable for suspension telemetry.
- **No firmware changes needed** — AS5600 is the stock SST sensor.

### Fork — SoftPot (custom, replaces rotary encoder)
- **Interface:** Analog ADC — 3 wires (3.3V, GND, wiper signal)
- **Wiring:** 3.3V → one end, GND → other end, wiper → Pico ADC pin (GP26/27/28)
- **Protection:** 100Ω series resistor on wiper line, 100nF cap from ADC pin to GND
- **Firmware change needed:** Replace encoder interrupt read with `adc_read()`, scale 0–4095 to 0.0–1.0 float. ~20 lines of change.
- **Noise mitigation:** RC filter (hardware) + moving average or median filter (firmware)

### Display — SSD1306 OLED (NFP1315-45A)
- **Interface:** I2C — shares bus with AS5600 (address 0x3C or 0x3D)
- **AS5600 I2C address:** 0x36 — no conflict
- **ICM-42688-P I2C address:** 0x68 or 0x69 — no conflict
- All three devices can share a single I2C bus on the Pico (GP4/GP5)
- Use for: recording state indicator, WiFi status, battery level, session timer
- Libraries: standard SSD1306 MicroPython/C libraries widely available

### IMU — 6-axis in main box (to be added)
- **Recommended part:** ICM-42688-P (significantly better noise floor than MPU-6050)
- **Interface:** I2C (shares bus with AS5600) or SPI
- **Directly wired to PCB** — no connector needed
- **Value:** Correlates frame pitch/roll/acceleration with suspension travel data. Detects braking events (nose dive vs terrain compression), cornering loads, rough trail sections.

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

## Connectors & Wiring

### External connectors (panel mount on enclosure)
- **Type:** M8 circular, IP67/IP68, screw lock
- **Softpot cable:** M8 3-pin
- **AS5600 cable:** M8 4-pin
- **Sources:** DigiKey, Mouser, RS Components — search "M8 panel mount female 4 pin IP67"
- **Brands:** Phoenix Contact, Binder, Weidmuller (all interchangeable)
- **Vibration note:** Apply silicone RTV or medium threadlock to screw collar to prevent backing off
- **Pre-made cables:** M8 sensor cables with moulded male connectors available cheaply — saves crimping cable side

### Internal wiring
- **Wire:** 28AWG silicone-jacket stranded (flexible, cold-crack resistant)
- **IMU:** Direct solder to PCB, no connector
- **Fork cable routing:** Service loop at crown, braided sleeve on exposed section

### Wire counts
| Sensor | Wires | Pins |
|---|---|---|
| AS5600 (I2C) | VCC, GND, SDA, SCL | 4 |
| SoftPot (analog) | VCC, GND, signal | 3 |
| IMU | Internal to PCB | — |

**Efficiency option:** Single 5-pin cable from box splitting to both sensors (shared VCC+GND, I2C×2, analog×1). Useful if frame routing space is limited.

---

## Prototyping Setup

**Initial bench testing uses a breadboard and jumper cables** — no soldering required at this stage.

- Pico WH has pre-soldered headers, seats directly in a standard breadboard
- All sensors connected via jumper cables (female-to-male for breakout boards)
- Suggested I2C bus wiring (all devices share):

| Signal | Pico Pin | Connected To |
|---|---|---|
| SDA | GP4 | AS5600 SDA, SSD1306 SDA |
| SCL | GP5 | AS5600 SCL, SSD1306 SCL |
| 3.3V | 3V3 OUT | AS5600 VCC, SSD1306 VCC, SoftPot end A |
| GND | GND | AS5600 GND, SSD1306 GND, SoftPot end B |
| ADC | GP26 | SoftPot wiper (via 100Ω series resistor) |

- Add 100nF cap from GP26 to GND on breadboard for SoftPot noise filtering
- I2C pull-ups: AS5600 breakout boards typically include on-board pull-ups — check before adding external ones to avoid conflict
- USB power sufficient for all bench testing — no LiPo shim needed yet

---

## Bench Test Workflow (start here)

### Phase 1 — Validate full software stack (no new code)
1. Flash stock SST firmware to Pico W
2. Set up gosst backend (Docker Compose)
3. Wire AS5600 to Pico (I2C: SDA→GP4, SCL→GP5, 3.3V, GND)
4. 3D print rotation jig (see below)
5. Move jig by hand, confirm travel plot appears in dashboard
6. **Goal:** Prove firmware → SD → WiFi → gosst → dashboard pipeline works end to end

### Phase 2 — Add SoftPot (minimal firmware change)
1. Wire SoftPot to Pico ADC (GP26 recommended)
2. Modify firmware: replace second encoder read with `adc_read()`, scale to 0.0–1.0
3. 3D print sliding stylus jig (see below)
4. Test both sensors simultaneously, verify both channels in dashboard

### Phase 3 — Combined validation
1. Generate fake session moving both sensors by hand
2. Confirm dashboard shows both fork and shock channels
3. Go/no-go before designing real bike mounts

---

## 3D Print — Bench Test Jigs

### AS5600 rotation jig
- **Pivot:** M4 or M5 bolt shank through close-tolerance hole (metal-on-metal surface). OR press-fit Igus xiros polymer 608-equivalent bearing.
- **Magnet holder:** Boss with blind pocket for magnet (6mm × 2.5mm diametrically magnetized disc), centered over AS5600. Controlled 1–1.5mm airgap.
- **Lever arm:** 80–100mm long for smooth manual sweep
- **Base plate:** AS5600 breakout mounted flat, alignment posts, bench clamp hole
- **Arc markings:** Reference angles on base for repeatability

### SoftPot sliding stylus jig
- Flat backing plate, length of SoftPot (e.g. 150mm)
- Sliding carriage with 3mm proud stylus nub
- Optional return spring to simulate fork rebound
- SoftPot wired: 3.3V → end A, GND → end B, wiper → GP26 with 100Ω + 100nF

---

## Related Projects / Reference Repos

| Repo | Notes |
|---|---|
| `nathancrz/MTB-telemetry` | Python, uses linear pots + ADS1115 ADC. Good reference for ADC-to-mm calibration |
| `porast1/suspension-telemetry` | STM32, FreeRTOS, DMA ADC at 200Hz. Good signal processing reference |
| `JoelKuula/Suspension_telemetry_public` | Has 3D-printable STL bracket files |
| `Finnitio/sst` | Another SST fork, check for modifications |

---

## Open Questions / Next Steps

- [ ] Check all linkage pivot angles on Regulator CX in person — find highest-angle accessible pivot
- [ ] Confirm pivot bolt hex sizes on both bikes (M6 or M8 hex head?)
- [ ] Research ICM-42688-P breakout board options
- [ ] Write SoftPot ADC firmware patch (~20 lines, replacing encoder read)
- [ ] Design AS5600 pivot mount for 3D printing (iglide J bore size, hex socket taper geometry)
- [ ] Set up gosst backend and test Docker Compose deployment
- [ ] Enter bike geometry for Regulator CX and Canyon Torque in gosst
