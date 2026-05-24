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

Adalogger manages GP4, GP5, GP17–GP22 internally (`*` below). Do not wire these pins.

---

## Full wiring diagram

```
                                              .──────── USB ────────.
                                              │       PICO WH        │
                                              │  (top face visible)  │
                   (free)   GP0       [1] ────┤                      ├──── [40]  VBUS
                   (free)   GP1       [2] ────┤                      ├──── [39]  VSYS
                GND rail    GND       [3] ────┤                      ├──── [38]  GND ─────── GND rail
             SSD1306 SDA    GP2       [4] ────┤                      ├──── [37]  3V3_EN
             SSD1306 SCL    GP3       [5] ────┤                      ├──── [36]  3V3 OUT ─── 3V3 rail
         * Adalogger IMU    GP4       [6] ────┤                      ├──── [35]  ADC_VREF
         * Adalogger IMU    GP5       [7] ────┤                      ├──── [34]  GP28    (free)
                GND rail    GND       [8] ────┤                      ├──── [33]  AGND
GND ─── [BTN LEFT] ──       GP6       [9] ────┤                      ├──── [32]  GP27    (free)
GND ─── [BTN RIGHT] ─       GP7      [10] ────┤                      ├──── [31]  GP26 ───┬── [100Ω] ── SoftPot Wiper
                   (free)   GP8      [11] ────┤                      ├──── [30]  RUN     ├── [100nF] ── GND rail
                   (free)   GP9      [12] ────┤                      ├──── [29]  GP22 *  └── [100kΩ] ── GND rail
                GND rail    GND      [13] ────┤                      ├──── [28]  GND ─────── GND rail
GND ─[LED R]─ [560Ω] ──     GP10     [14] ────┤                      ├──── [27]  GP21 *
GND ─[LED G]─ [560Ω] ──     GP11     [15] ────┤                      ├──── [26]  GP20 *
                   (free)   GP12     [16] ────┤                      ├──── [25]  GP19 *
                   (free)   GP13     [17] ────┤                      ├──── [24]  GP18 *
                GND rail    GND      [18] ────┤                      ├──── [23]  GND ─────── GND rail
              AS5600 SDA    GP14     [19] ────┤                      ├──── [22]  GP17 *
              AS5600 SCL    GP15     [20] ────┤                      ├──── [21]  GP16    (free)
                                              '──────────────────────'

  Power for all components:
    SSD1306  VCC ── 3V3 rail    GND ── GND rail   (pull-ups on-board)
    AS5600   VCC ── 3V3 rail    GND ── GND rail   (pull-ups on-board)
    SoftPot  End A (pin 1) ── 3V3 rail    End B (pin 3) ── GND rail
```

---

## Button actions

| Button | Press     | Action                                              |
|--------|-----------|-----------------------------------------------------|
| LEFT   | Short     | Start recording (idle) / Stop recording (recording) |
| LEFT   | Long (1s) | Sync data to gosst server over WiFi                 |
| RIGHT  | Short     | Sleep                                               |
| RIGHT  | Long (1s) | Set fork zero — hold with fork at full extension    |
