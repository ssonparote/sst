# SST Bench Test Wiring

Breadboard wiring for bench validation using the full stack:
**LiPo Shim (bottom) → Pico WH → Adalogger PicoWbell (top)**.

The Adalogger is stacked on top of the Pico, blocking access to the
underside pins. All Adalogger-managed pins are marked with `*` below —
do not wire these manually.

---

## Pico WH pinout (USB end at top)

```
                          .------- USB -------.
                          |      PICO WH       |
                          |   (Adalogger on    |
                          |    top, stacked)   |
  UART debug --- GP0   1 -|                   |- 40  VBUS
  UART debug --- GP1   2 -|                   |- 39  VSYS
                 GND   3 -|                   |- 38  GND ----------- GND rail
  SSD1306 SDA -- GP2   4 -|                   |- 37  3V3_EN
  SSD1306 SCL -- GP3   5 -|                   |- 36  3V3 OUT ------- 3V3 rail
     * IMU SDA - GP4   6 -|                   |- 35  ADC_VREF
     * IMU SCL - GP5   7 -|                   |- 34  GP28/ADC2 free
                 GND   8 -|                   |- 33  AGND
    BTN LEFT --- GP6   9 -|                   |- 32  GP27/ADC1 free
    BTN RIGHT -- GP7  10 -|                   |- 31  GP26/ADC0 ----- SoftPot wiper
    free         GP8  11 -|                   |- 30  RUN
    free         GP9  12 -|                   |- 29  * GP22 SDIO D3
                 GND  13 -|                   |- 28  GND
  LED rec (red) GP10  14 -|                   |- 27  * GP21 SDIO D2
  LED WiFi(grn) GP11  15 -|                   |- 26  * GP20 SDIO D1
    free        GP12  16 -|                   |- 25  * GP19 SDIO D0
    free        GP13  17 -|                   |- 24  * GP18 SDIO CMD
                 GND  18 -|                   |- 23  GND
  AS5600 SDA -- GP14  19 -|                   |- 22  * GP17 SDIO CLK
  AS5600 SCL -- GP15  20 -|                   |- 21  free GP16
                          '-------------------'

  * = managed by Adalogger PicoWbell — do not wire manually
```

---

## SSD1306 OLED (128×64, I2C 0x3C)

Uses PIO software I2C — not on the hardware I2C buses.

```
Pico pin 36  3V3 OUT ─── VCC
Pico pin  3  GND     ─── GND
Pico pin  4  GP2     ─── SDA
Pico pin  5  GP3     ─── SCL
```

Most SSD1306 breakouts include on-board pull-ups. Do not add external ones.

---

## AS5600 Rotary Sensor (I2C1 0x36)

```
Pico pin 36  3V3 OUT ─── VCC
Pico pin  3  GND     ─── GND
Pico pin 19  GP14    ─── SDA
Pico pin 20  GP15    ─── SCL
```

AS5600 breakouts include on-board pull-ups. Do not add external ones.

---

## SoftPot Linear Sensor (ADC0, GP26)

Build this protection circuit on the breadboard between SoftPot and Pico:

```
3V3 ──────────────────────── SoftPot End A (Pin 1)
GND ──────────────────────── SoftPot End B (Pin 3)

SoftPot Wiper (Pin 2)
    |
  [100Ω]
    |
    +──────────────────────── GP26 (Pico pin 31)
    |
    +── [100nF] ─── GND       RC low-pass filter, ~16 kHz cutoff
    |
    └── [100kΩ] ─── GND       pull-down, prevents float when stylus off track
```

- **100Ω** — protects ADC if wiper shorts to a rail
- **100nF** — filters noise; place close to the Pico pin
- **100kΩ** — holds ADC near 0 V when SoftPot is disconnected

---

## Buttons (active-low, internal pull-up)

One leg to GPIO, other leg to GND. No external resistor needed —
firmware enables the Pico's internal pull-up.

```
Pico pin  9  GP6 ─── [BTN LEFT]  ─── GND
Pico pin 10  GP7 ─── [BTN RIGHT] ─── GND
```

---

## Status LEDs

LED anode → resistor → GPIO. Cathode to GND. GPIO HIGH = LED on.

```
Pico pin 14  GP10 ─── [560Ω] ─── LED+ (red)   ─── LED- ─── GND
Pico pin 15  GP11 ─── [560Ω] ─── LED+ (green) ─── LED- ─── GND
```

330Ω gives ~4 mA (brighter) if 560Ω is too dim.

---

## Button action summary

| Button | Press     | Action                                              |
|--------|-----------|-----------------------------------------------------|
| LEFT   | Short     | Start recording (idle) / Stop recording (recording) |
| LEFT   | Long (1s) | Sync data to gosst server over WiFi                 |
| RIGHT  | Short     | Sleep                                               |
| RIGHT  | Long (1s) | **Set fork zero** — hold with fork at full extension |
