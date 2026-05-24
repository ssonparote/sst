# SST Bench Test Wiring

## Stack (top to bottom)

```
  ┌─────────────────────────────┐  ← USB connector, BOOTSEL btn, chips (all visible on top)
  │         PICO WH             │
  └──┬──┬──┬──┬──┬──┬──┬──┬───┘  ← male headers pointing down
     │  │  │  │  │  │  │  │
  ┌──┴──┴──┴──┴──┴──┴──┴──┴───┐  ← LiPo Shim (sandwiched, soldered to Pico headers)
  └──┬──┬──┬──┬──┬──┬──┬──┬───┘
     │  │  │  │  │  │  │  │
  ┌──┴──┴──┴──┴──┴──┴──┴──┴───┐  ← female headers facing up
  │    Adalogger PicoWbell     │     (MicroSD, RTC, STEMMA QT — all hidden underneath)
  └─────────────────────────────┘
```

The Adalogger manages GP4, GP5, GP17–GP22 internally.
Do not wire these pins — they are marked `*` below.

---

## Full wiring diagram

```
                                    .──────── USB ────────.
                                    │       PICO WH        │
                                    │  (top face visible)  │
               (free)  GP0   [1] ───┤                      ├─── [40]  VBUS
               (free)  GP1   [2] ───┤                      ├─── [39]  VSYS
             GND rail  GND   [3] ───┤                      ├─── [38]  GND ──────── GND rail
          SSD1306 SDA  GP2   [4] ───┤                      ├─── [37]  3V3_EN
          SSD1306 SCL  GP3   [5] ───┤                      ├─── [36]  3V3 OUT ──── 3V3 rail
      * Adalogger IMU  GP4   [6] ───┤                      ├─── [35]  ADC_VREF
      * Adalogger IMU  GP5   [7] ───┤                      ├─── [34]  GP28   (free)
             GND rail  GND   [8] ───┤                      ├─── [33]  AGND
            BTN LEFT   GP6   [9] ───┤                      ├─── [32]  GP27   (free)
           BTN RIGHT   GP7  [10] ───┤                      ├─── [31]  GP26 ─── SoftPot (see A)
               (free)  GP8  [11] ───┤                      ├─── [30]  RUN
               (free)  GP9  [12] ───┤                      ├─── [29]  GP22 * Adalogger SDIO
             GND rail  GND  [13] ───┤                      ├─── [28]  GND ──────── GND rail
        LED record(R)  GP10 [14] ───┤                      ├─── [27]  GP21 * Adalogger SDIO
          LED WiFi(G)  GP11 [15] ───┤                      ├─── [26]  GP20 * Adalogger SDIO
               (free)  GP12 [16] ───┤                      ├─── [25]  GP19 * Adalogger SDIO
               (free)  GP13 [17] ───┤                      ├─── [24]  GP18 * Adalogger SDIO
             GND rail  GND  [18] ───┤                      ├─── [23]  GND ──────── GND rail
          AS5600 SDA   GP14 [19] ───┤                      ├─── [22]  GP17 * Adalogger SDIO
          AS5600 SCL   GP15 [20] ───┤                      ├─── [21]  GP16   (free)
                                    '──────────────────────'
```

---

## Component connections

### SSD1306 OLED (I2C 0x3C)
```
  3V3 rail ──── VCC
  GND rail ──── GND
  GP2 pin  4 ── SDA
  GP3 pin  5 ── SCL
```
Breakout has on-board pull-ups — do not add external ones.

---

### AS5600 rotary sensor (I2C 0x36)
```
  3V3 rail ──── VCC
  GND rail ──── GND
  GP14 pin 19 ── SDA
  GP15 pin 20 ── SCL
```
Breakout has on-board pull-ups — do not add external ones.

---

### (A) SoftPot — GP26 protection circuit
```
  SoftPot End A (pin 1) ──── 3V3 rail
  SoftPot End B (pin 3) ──── GND rail

  SoftPot Wiper (pin 2)
       │
     [100Ω]
       │
       ├──────────────────── GP26  pin 31
       │
       ├──── [100nF] ──── GND rail      ← noise filter
       │
       └──── [100kΩ] ──── GND rail      ← pull-down (prevents float)
```

---

### Buttons — active low, internal pull-up
```
  GP6  pin  9 ──── [BTN LEFT]  ──── GND rail
  GP7  pin 10 ──── [BTN RIGHT] ──── GND rail
```
One leg to the GPIO, other leg to GND. No external resistor needed.

---

### Status LEDs
```
  GP10 pin 14 ──── [560Ω] ──── LED anode (+) ──── LED cathode (−) ──── GND rail
                               red = recording

  GP11 pin 15 ──── [560Ω] ──── LED anode (+) ──── LED cathode (−) ──── GND rail
                               green = WiFi active
```
Use 330Ω instead of 560Ω for slightly brighter output (~4 mA vs ~2 mA).

---

## Button actions

| Button | Press     | Action                                              |
|--------|-----------|-----------------------------------------------------|
| LEFT   | Short     | Start recording (idle) / Stop recording (recording) |
| LEFT   | Long (1s) | Sync data to gosst server over WiFi                 |
| RIGHT  | Short     | Sleep                                               |
| RIGHT  | Long (1s) | Set fork zero — hold with fork at full extension    |
