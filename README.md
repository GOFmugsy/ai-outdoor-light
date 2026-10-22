# QT Py Solar Garden Light

A parametric OpenSCAD enclosure for a stake-mounted solar light: the light column on top, a sealed electronics box below it, and a pole socket on the bottom. The NeoPixel ring faces up into a diffuser tube. A white cone under the solar-panel cap bounces the light outward and down onto the ground.

```
  ┌──────────┐  cap: Voltaic P123 recessed in the top; also a rain shade
  └──┬─\/─┬──┘  reflector cone (white), point down
     │  ║  │     diffuser tube (natural PETG) around the hollow spine
     │  ║  │     (panel cable runs inside the spine, hidden from view)
  ┌──┴─◯◯─┴──┐  deck: NeoPixel ring faces up; carries the light column
  ├──────────┤  gasket (TPU)
  │batt  chg │  body (82.5 mm square): battery, charger + QT Py cradles,
  │     QTPy │        USB-C port + plug
  └───╲──╱───┘  base: pole socket
       ▼        stake (or a 1/2" EMT pole)
```

## Files

| File | Purpose |
|---|---|
| `solar_light.scad` | Every part. All dimensions are Customizer parameters. |
| `export_stls.sh` | Writes each part to `stl/<part>.stl`. Extra arguments go to OpenSCAD, e.g. `./export_stls.sh -D 'battery_type="lipo"'`. |

To preview, open `solar_light.scad` and set `part` to `assembly` or `exploded`.

## Bill of materials

- Adafruit QT Py ESP32-S2
- Adafruit NeoPixel Ring, 16 x 5050 RGB
- Adafruit 5V 0.6W Mini ETFE solar panel (Voltaic P123, 65.5 x 65.5 x 3.1 mm)
- **A charger.** The QT Py can't charge a battery itself. The default cradle is sized for the Adafruit bq24074 Universal USB/DC/Solar charger (#4755). **Measure your board** and set `charger_size`.
- **A battery**, one of:
  - `battery_type="lipo"` (default): a pouch cell, sized with `lipo_size` (default 36 x 62 x 8 mm, about 2000 mAh).
  - `battery_type="18650"`: a protected 18650 cell in a single-cell holder (`holder_18650`). The 78 mm holder doesn't fit the square body, so also set `body_extra = [0, 6]`. That makes the body and deck 6 mm longer than the cap.
- Deck to body: 4x M3x35 screws, inserted from underneath the body, + 4x M3 heat-set inserts
- Light column: 3x M3 threaded rod (~84 mm) + 3x inserts in the cap + 3x nuts under the deck
- Base to body: 3x M3x8 screws + 3x short M3 heat-set inserts (≤5 mm)
- Clear or neutral silicone to seal the panel, the cable channel, and both diffuser grooves

The console prints the exact screw and rod lengths for your parameters.

## Assembly order

1. Run the panel cable down through the cap and spine and into the deck. Cut off the DC plug if it won't fit through `spine_id`.
2. Light column: screw the rods into the cap. Slide the reflector onto the spine and push the spine into the cap. Silicone the diffuser into the cap's groove. Seat the ring in the deck, with its pads over the wire hole. Silicone the diffuser into the deck groove and tighten the nuts under the deck.
3. Wire everything up in the body. Fit the gasket, then screw the deck down from underneath through the corner bosses.
4. Screw the base on from below, then push it onto the stake or pole.

To service the electronics, remove the 4 corner screws. The whole light column lifts off with the deck.

## Printing

| Part | Material | Orientation / notes |
|---|---|---|
| cap, deck, body | ASA or PETG (UV-stable) | As modelled. Everything on the underside is recessed, so no supports. |
| diffuser | natural/translucent PETG | 2 perimeters, no top or bottom layers |
| reflector | **white** | Flat face down, as modelled |
| spine | any | Upright |
| base | ASA/PETG | As modelled (flange on the bed); flip it over to install |
| gasket, usb_plug | TPU | |
| stake | PETG/ASA | Plug end down. Use a real pole in hard soil. |

## Wiring (overview)

```
Panel ─► bq24074 DC/solar IN        bq24074 BAT ─► battery
bq24074 OUT/LOAD ─► QT Py 5V pin and NeoPixel ring 5V,  GND common
QT Py A3 (or any GPIO) ─► ring DIN (330 Ω series resistor)
Dusk sensing: panel+ ─► 100k/100k divider ─► QT Py A0  (or read the charger's PGOOD pin)
```

- WS2812 LEDs draw about 0.5–1 mA each even when dark, which adds up to roughly 15 mA all day. To avoid that, switch the ring's power with a P-channel MOSFET driven from a GPIO.
- WS2812s hold their last colour without data. Set the pixels, then put the ESP32-S2 into deep sleep and wake it periodically to check for dawn.
- Li-ion must not be charged below 0 °C. In freezing climates, fit the charger's thermistor (TS) input.

## Power budget (rough)

| | Current | 12 h night |
|---|---|---|
| 16 LEDs, warm white at ~5% | ~20 mA | 240 mAh |
| QT Py, deep sleep with periodic wake | ~1–3 mA | ~30 mAh |
| **Total** | | **~270 mAh** |

The P123 is a 0.6 W panel, about 120 mA in full sun. That works out to roughly 300–400 mAh on a clear day and much less when it's overcast. That's half of what the larger P124 makes, so plan around a dim glow instead of a bright light:

- Keep the average LED current around 20 mA. Fewer lit pixels or lower brightness both work.
- Run dusk to midnight in winter rather than all night.
- A 2000 mAh LiPo covers about 7 nights with no sun at this budget.

## Key parameters

- `panel_cable_pos`, `panel_jbox`: where the panel's cable exits its back. **Measure your panel.**
- `panel_size`: Adafruit lists 3.1 mm thick and some distributors list 3.6 mm. A thicker panel simply sits a little more proud of the cap.
- `body_extra`: grows the body and deck beyond the cap footprint, for bigger batteries or boards.
- `diff_h`, `diff_od`: lantern proportions.
- `refl_angle`: reflector half-angle. Above 45° throws light downward; below 45° throws it upward.
- `pole_d`, `socket_depth`: pole size. The default of 18 mm fits 1/2" EMT.
- `insert_d`: 4.2 for heat-set inserts, or ~2.6 to self-tap.

Assertions in the file catch geometry collisions after you change parameters, such as the tie rods hitting the ring seat or the cable channel breaking into the diffuser groove.
