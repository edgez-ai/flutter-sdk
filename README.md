# flutter-sdk
flutter sdk for edgez mesh

## EdgeZ Flutter SDK

This package is the Flutter-facing SDK boundary for the EdgeZ HaLow mesh app.

The SDK owns BLE transport and mesh operations:

- BLE connect/disconnect
- HaLow mesh initialization
- mesh status events
- node/beacon events
- text and voice message send APIs
- device settings send APIs

The example app is intentionally in-memory only. It does not use SQLite and it does not include the map tab or Organic Maps dependencies.

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

The example app lives in `example/`. It keeps nodes, messages, selected conversation, and settings in widget state.

When Flutter tooling is available, run:

```sh
cd example
flutter pub get
flutter run
```
