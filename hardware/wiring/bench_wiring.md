# SST Bench Test Wiring

Breadboard wiring for bench validation. All sensors connect to the Pico WH
(or the full stack: LiPo Shim → Pico WH → Adalogger).

---

## Quick-reference table

| Signal        | Pico GPIO | Pico Pin | Connected to               |
|---------------|-----------|----------|----------------------------|
| PIO I2C SDA   | GP2       | 4        | SSD1306 SDA                |
| PIO I2C SCL   | GP3       | 5        | SSD1306 SCL                |
| Button LEFT   | GP6       | 9        | Button → GND (active-low)  |
| Button RIGHT  | GP7       | 10       | Button → GND (active-low)  |
| LED recording | GP10      | 14       | 560Ω → LED(red) → GND     |
| LED WiFi      | GP11      | 15       | 560Ω → LED(green) → GND   |
| Shock SDA     | GP14      | 19       | AS5600 SDA                 |
| Shock SCL     | GP15      | 20       | AS5600 SCL                 |
| Fork ADC      | GP26      | 31       | SoftPot wiper (see below)  |
| 3V3 OUT       | —         | 36       | Power rail                 |
| GND           | —         | 38       | Ground rail                |

---

## Overall diagram

```
                           ┌─────────────────┐
                 USB ──────┤  Pico WH        │
                           │  (or full stack) │
          3V3 rail ────────┤ 3V3(pin 36)     │
          GND rail ────────┤ GND(pin 38)     │
                           │                 ├── GP2 ────────── SSD1306 SDA
                           │                 ├── GP3 ────────── SSD1306 SCL
                           │                 ├── GP6 ──┐
                           │                 │         └── BTN_L ── GND
                           │                 ├── GP7 ──┐
                           │                 │         └── BTN_R ── GND
                           │                 ├── GP10 ── 560Ω ── LED+ (red)   ── GND
                           │                 ├── GP11 ── 560Ω ── LED+ (green) ── GND
                           │                 ├── GP14 ─────────── AS5600 SDA
                           │                 ├── GP15 ─────────── AS5600 SCL
                           │                 ├── GP26 ─────────── (see SoftPot circuit)
                           └─────────────────┘
```

---

## SSD1306 OLED (128×64, I2C 0x3C)

```
Pico 3V3 ──── VCC
Pico GND ──── GND
Pico GP2 ──── SDA
Pico GP3 ──── SCL
```

Uses PIO I2C (software), not hardware I2C — no pull-up conflict with AS5600.
Most SSD1306 breakouts include on-board pull-ups; no external ones needed.

---

## AS5600 Rotary Sensor (I2C1 0x36)

```
Pico 3V3  ──── VCC
Pico GND  ──── GND
Pico GP14 ──── SDA
Pico GP15 ──── SCL
```

AS5600 breakouts include on-board pull-ups. Do not add additional pull-ups.

---

## SoftPot Linear Sensor (ADC0, GP26)

Protection circuit on the breadboard between SoftPot and Pico:

```
3V3 ──────────────────────── SoftPot End A (Pin 1)
GND ──────────────────────── SoftPot End B (Pin 3)

SoftPot Wiper (Pin 2)
    │
   100Ω
    │
    ├──────────────────────── GP26 (Pico pin 31)
    │
    ├── 100nF ──── GND        (RC low-pass, ~16 kHz cutoff)
    │
    └── 100kΩ ──── GND        (pull-down, prevents float when stylus off track)
```

- **100Ω**: protects ADC if wiper shorts to a rail
- **100nF**: filters high-frequency noise (place close to Pico pin)
- **100kΩ**: holds ADC near 0 V when SoftPot is disconnected or stylus off active area

---

## Buttons (active-low, internal pull-up)

Buttons connect between the GPIO and GND. The Pico's internal pull-up is
enabled in firmware — no external resistor needed.

```
GP6 ──── [BTN_LEFT]  ──── GND      short press → start/stop recording
                                    long press  → WiFi data sync

GP7 ──── [BTN_RIGHT] ──── GND      short press → sleep
                                    long press  → set fork zero
```

---

## Status LEDs

LEDs connect from GPIO through a 560Ω current-limiting resistor to GND.
GPIO HIGH = LED on.

```
GP10 ──── 560Ω ──── LED(red, anode) ──── LED(cathode) ──── GND
                    Recording active

GP11 ──── 560Ω ──── LED(green, anode) ── LED(cathode) ──── GND
                    WiFi active (connecting / syncing)
```

At 3.3 V with a ~2 V forward drop: (3.3 - 2.0) / 560 ≈ 2.3 mA — dim but visible.
Use a 330Ω resistor (~4 mA) if you want more brightness.

---

## Button actions summary

| Button | Action      | State  |
|--------|-------------|--------|
| LEFT   | Short press | Start recording (IDLE) / Stop recording (RECORD) |
| LEFT   | Long press  | Sync data to server over WiFi |
| RIGHT  | Short press | Sleep |
| RIGHT  | Long press  | **Set fork zero** — captures current SoftPot position as 0 mm baseline |
