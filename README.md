# flutter-sdk
flutter sdk for edgez mesh

## EdgeZ Flutter SDK

This package is the Flutter-facing SDK boundary for the EdgeZ HaLow mesh app.

For a structured feature overview and application setup, start with the
[`doc/` documentation hub](doc/README.md) and the
[`integration guide`](doc/integration-guide.md).
Planned offline maps and libp2p cross-boundary mixed-mesh support are tracked in
the [`roadmap`](doc/roadmap.md).

The SDK owns BLE transport and mesh operations:

- BLE connect/disconnect
- HaLow mesh initialization
- mesh status events
- node/beacon events
- text and voice message send APIs
- background message notifications and lock-screen incoming-call notifications
- device settings send APIs
- BLE firmware OTA with acknowledged writes, progress events, and cancellation

Production builds use `EdgezChannelTransport`, which bridges the SDK to the
Android BLE plugin through Flutter method and event channels. Tests can inject
an `EdgezPlatformTransport` implementation to mock BLE commands and incoming
events without hardware.

The example app persists nodes, conversations, sensor history, geofences, and
dashboard preferences in SQLite. Its Map tab displays live mesh nodes that
share a location. Organic Maps uses Android location permission and device
orientation sensors to render the current position and heading natively.

## Android offline voice translation

The example ports the core flow from
[Gemma Translator](https://github.com/google-gemma/gemma-translator) to Android
with Gemma 4 E2B and LiteRT-LM. Voice messages can be translated locally after
a one-time 2.6 GB download started on first use; message audio and generated
text stay on the phone. The conversation screen shows download progress and
exposes the target-language selector, transcript, and translated result. Later
launches reuse the cached model. On Android, each result is spoken
automatically with the same Moonshine Voice Kokoro/Piper pipeline used by the
reference translator and can be replayed from the speaker button. The selected
language's voice assets download on first use and are reused offline; Chinese
uses the reference app's `kokoro_zf_xiaoxiao` voice override.

The SDK method `decodeVoiceMessageToWav` normalizes its Opus/Ogg and AMR/3GP
voice containers to the 16 kHz mono WAV input expected by the model. LiteRT-LM
currently requires an `arm64-v8a` Android device. Host apps that reuse the
example integration must initialize `LiteRtLmEngine`, add the optional OpenCL
libraries to their application manifest, and provide enough free storage for
the model plus download headroom.

## Offline Organic Maps

`EdgezOrganicMap` embeds the EdgeZ Organic Maps Android renderer and accepts a
list of `EdgezMapNode` markers. The plugin uses the v0.0.4 Android libraries
published on the
[EdgeZ Organic Maps release](https://github.com/edgez-ai/organicmaps/releases/tag/v0.0.4).

Add the release as an Ivy artifact repository in the host application's
`android/build.gradle` `allprojects.repositories` block:

```groovy
ivy {
    url 'https://github.com/edgez-ai/organicmaps/releases/download/v0.0.4'
    patternLayout { artifact '[artifact]-[revision].[ext]' }
    metadataSources { artifact() }
    content { includeGroup 'ai.edgez.organicmaps' }
}
```

Organic Maps also requires core-library desugaring in the host app. Add this
inside `android/app/build.gradle`:

```groovy
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.5'
}
```

Then place the widget in a bounded layout:

```dart
EdgezOrganicMap(
  nodes: const [
    EdgezMapNode(
      id: 'gateway-1',
      label: 'Gateway',
      latitude: 59.3293,
      longitude: 18.0686,
      marker: 'blue',
    ),
  ],
)
```

The bundled world map provides the offline base map. Detailed regional maps
still require the Organic Maps download APIs in a future SDK surface.

## Background messages and calls

While BLE is connected, the Android plugin runs a `connectedDevice` foreground
service. Incoming messages can be posted as Android conversation notifications;
incoming calls use a high-importance call notification with Answer and Decline
intents and a dedicated call screen that remains usable over the lock screen
after Answer. Android 13+
requires notification permission, and Android 14+ lets the user separately
control full-screen intent access.

See [Background notifications and calls](doc/background-notifications.md) for
host manifest requirements, Dart callbacks, notification channels, lock-screen
behavior, and lifecycle limitations. Native changes require a full stop,
rebuild, and reinstall; hot reload is not sufficient.

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

Map rendering is exposed through the Android platform view in
`EdgezOrganicMapView.kt`; Flutter applications do not need to copy the native
Organic Maps source tree.

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
