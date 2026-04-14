# Proper Level

A precision spirit level, clinometer, and measuring tool for Android and iOS.

Built for serious DIYers, woodworkers, tile setters, and interior designers.
Feels like a Leica, not a toy.

**Bundle ID:** `ca.themillrace.proper.level`  
**Publisher:** The Millrace Co  
**Licence:** MIT

---

## Features (V1)

- **Orientation-driven level** — hold the phone landscape for horizontal, portrait for vertical, flat for 360° surface level. Switches automatically.
- **Clinometer** — measure any angle of inclination. Set a target angle and get alerted when you hit it.
- **Freeze / Hold** — lock the reading while you move the phone. Volume-up shortcut.
- **Audio & vibration feedback** — tone rises in pitch approaching level; tempo-based vibration. Works with screen off.
- **Sensitivity adjustment** — configurable low-pass filter so the bubble responds exactly as fast as you want.
- **Precision calibration** — two-step sensor bias calibration that cancels surface imperfection.
- **Flashlight toggle** — built into the toolbar for dark workspaces.
- **Open source** — MIT licence, F-Droid compatible.

## Roadmap

- **V2:** AR Laser Level — overlay a gravity-aligned horizontal or vertical line over the camera view for hanging artwork and aligning tiles.
- **V3:** AR Distance Measure + Photo Mapping with measurement annotations.

---

## Build

Requires Flutter 3.x stable.

```bash
git clone https://github.com/millrace/proper-level
cd proper-level/level
flutter pub get
flutter run
```

### Run tests

```bash
flutter test test/unit/
```

### Analyse

```bash
flutter analyze
```

---

## Project structure

```
level/
  lib/
    core/           # Sensors, calibration, audio, haptics, theme, units
    state/          # Riverpod providers (sensor, settings, freeze)
    widgets/        # BubbleVial, Bullseye, AngleReadout, Toolbar
    features/
      level/        # Orientation-driven level page (H/V/Surface)
      clinometer/   # Clinometer page
      settings/     # Settings page
      calibration/  # Two-step calibration flow
  test/
    unit/           # Angle math, calibration, filter tests (25 tests)
```

---

## Distribution

| Store | Price | Notes |
|---|---|---|
| Google Play | $1.99 | Primary launch |
| Apple App Store | $1.99 | iOS companion |
| F-Droid | Free | Full features, open source build |

---

## Contributing

Issues and pull requests welcome. See `HOW_TO_USE.txt` for full feature documentation.
