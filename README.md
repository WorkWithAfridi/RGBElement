# RGBElement

RGBElement is a Flutter companion app for LEDDMX Bluetooth RGB strip controllers. It takes the color-first controls and effect catalog from the existing native prototype and expands them into a scene studio, favorites, sleep timer, and configurable firmware options.

## Current features

- Bluetooth LE scan and GATT connection for LEDDMX style controllers.
- Color wheel, saved color favorites, presets, brightness and white-temperature controls.
- 211 searchable built-in effects, with effect-speed control and microphone mode.
- Saved looks that restore color, brightness, speed, effect and temperature.
- Color-tour demo, recent activity, dark/light appearance, and a sleep timer.
- Frame/power/color-byte options for known LEDDMX firmware variants.

## Run

Install Flutter 3.50+ and Android Studio, then run:

```sh
flutter pub get
flutter run
```

The app currently targets Android and iOS. BLE needs a real phone and a nearby powered controller; simulators generally cannot scan for the strip. On iOS, allow Bluetooth access when prompted.

## Project layout

- `lib/state/app_state.dart` — app state, scan/connect lifecycle, persistence and commands.
- `lib/protocol/leddmx_protocol.dart` — 9-byte frame builders.
- `lib/data/pattern_catalog.dart` — pattern labels copied from the native reference app.
- `lib/models/light_scene.dart` — saved scene serialization.
- `lib/main.dart` — Material UI and the five main app sections.

## BLE protocol notes

The tested controller uses service `FFE0` and write characteristic `FFE1`. Frames are nine bytes: `7B FF <command> <five data bytes> BF`. RGBElement supports the alternate `7B 04` frame pad, the two documented power-byte pairs, and the two observed color-data-byte-7 values. The LEDDMX family has no reliable state readback, so the UI tracks the commands it sends.

The original hardware session recorded a Windows-specific GATT characteristic discovery failure. RGBElement is intended to connect from a phone. Pattern labels are firmware hints and may not exactly match each controller.

## BLE dependency license

The project currently uses `flutter_blue_plus` 2.3.15 with `License.nonprofit`, which covers personal use. A commercial release requires the package's commercial license or replacement with a dependency that permits that distribution.
