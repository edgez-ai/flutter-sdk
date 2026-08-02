# flutter-sdk
flutter sdk for edgez mesh

## EdgeZ Flutter SDK

This package is the Flutter-facing SDK boundary for the EdgeZ HaLow mesh app.

For a structured feature overview and application setup, start with the
[`docs/` documentation hub](docs/README.md) and the
[`integration guide`](docs/integration-guide.md).
Planned offline maps and libp2p cross-boundary mixed-mesh support are tracked in
the [`roadmap`](docs/roadmap.md).

The SDK owns BLE transport and mesh operations:

- BLE connect/disconnect
- HaLow mesh initialization
- mesh status events
- node/beacon events
- text and voice message send APIs
- device settings send APIs
- BLE firmware OTA with acknowledged writes, progress events, and cancellation

Production builds use `EdgezChannelTransport`, which bridges the SDK to the
Android BLE plugin through Flutter method and event channels. Tests can inject
an `EdgezPlatformTransport` implementation to mock BLE commands and incoming
events without hardware.

The example app persists nodes, conversations, sensor history, geofences, and
dashboard preferences in SQLite. It does not include the map tab or Organic
Maps dependencies.

## Flash Firmware

Flash your device with the firmware available from the [EdgeZ web flasher](https://www.edgez.ai/flasher).
Currently, only the Heltec HT-HC33 is supported.

## Firmware OTA

The Android transport follows the same OTA protocol as `edgez-android-app`:
it discovers characteristics FFF5/FFF6, sends begin/data/end commands using
acknowledged BLE writes, limits data chunks for the ESP32 NimBLE ACL buffer,
and emits `EdgezMeshEventType.otaProgress` events.

Use `EdgezOtaRelease.fromJson` to validate the firmware manifest and compare its
version with the connected device. After downloading and validating the image
size, call `EdgezMeshSession.performOta`. The example demonstrates the complete
check, download, install, progress, and cancel workflow in its Settings tab.

## Driver storage

`EdgezDriverStore` owns the installed-driver list and persistent bundle storage.
Host apps resolve marketplace links and download the manifest, Lua source, and
optional image, then pass the completed `EdgezDriverBundle` to `save`. The
example demonstrates this boundary for `edgez://drivers/install` links.

## Current Android Reference

The Android implementation should be wired from the current project seams:

- `app/src/main/java/ai/edgez/edgez/ble/EdgezBleClient.kt`
- `app/src/main/java/ai/edgez/edgez/HaLowStatusFrames.kt`
- `app/src/main/java/ai/edgez/edgez/ConversationCrypto.kt`
- `app/src/main/java/ai/edgez/edgez/VoiceMessageAudio.kt`
- `app/src/main/java/ai/edgez/edgez/DeviceSettingModels.kt`
- the existing mesh control protobuf schema in the Android app

The map-specific files are deliberately not part of this SDK/example split:

- `MapScreen.kt`
- `LocationMapLauncher.kt`
- `NodeMapMarkerUi.kt`
- Organic Maps Gradle modules and `third_party/organicmaps`

## Example

The demo below shows the example application built from the Flutter SDK's
`example/` project. It demonstrates peer-to-peer communication and sensor data
collection over the EdgeZ mesh network.

[![Watch the EdgeZ Flutter SDK example application demo](https://img.youtube.com/vi/PoI31k7hviY/maxresdefault.jpg)](https://youtu.be/PoI31k7hviY)

The example app keeps current UI selections and settings in widget state while
persisting mesh data and dashboard preferences in SQLite.

When Flutter tooling is available, run:

```sh
cd example
flutter pub get
flutter run
```

## Protobuf Stubs

The SDK keeps the mesh control protobuf schema in `protos/edgez_mesh.proto` and commits the generated Dart stubs under `lib/src/proto/`.

Regenerate the stubs after changing the schema:

```sh
dart pub get
tool/generate_protos.sh
```

## Tests

Run the SDK tests with:

```sh
flutter test
```

`test/support/mock_ble_transport.dart` provides an in-memory BLE transport.
The mocked-BLE suite verifies connection commands and events, ready-gated mesh
initialization, inbound beacons and sensor values, encrypted conversations, and
transport failures.
