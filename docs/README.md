# EdgeZ Flutter SDK documentation

This documentation describes the public Flutter SDK in [`lib/`](../lib/) and
uses the Android example in [`example/`](../example/) as the reference
integration.

## Start here

| Document | Use it for |
| --- | --- |
| [Feature guide](features.md) | Understand the SDK capabilities, platform support, and example coverage. |
| [Integration guide](integration-guide.md) | Add the SDK to a Flutter app and implement the BLE-to-mesh lifecycle. |
| [API map](api-reference.md) | Find the main public classes and choose between the session and low-level APIs. |
| [Roadmap](roadmap.md) | Review planned offline maps and libp2p cross-boundary mixed-mesh work. |

## Repository map

| Path | Purpose |
| --- | --- |
| [`lib/edgez_flutter_sdk.dart`](../lib/edgez_flutter_sdk.dart) | Public package exports. Import this file from host applications. |
| [`lib/src/edgez_mesh_session.dart`](../lib/src/edgez_mesh_session.dart) | Recommended stateful application facade. |
| [`lib/src/edgez_mesh_sdk.dart`](../lib/src/edgez_mesh_sdk.dart) | Low-level commands, transport events, packet encoding, and encryption. |
| [`lib/src/models.dart`](../lib/src/models.dart) | Configuration, state, node, message, sensor, and event models. |
| [`example/lib/src/app.dart`](../example/lib/src/app.dart) | Complete session lifecycle, settings, OTA, and app-level persistence wiring. |
| [`example/lib/src/provisioning_screen.dart`](../example/lib/src/provisioning_screen.dart) | Device authorization and provisioning flow. |
| [`example/lib/src/marketplace_driver_install.dart`](../example/lib/src/marketplace_driver_install.dart) | Marketplace link validation and driver download boundary. |

## Supported platform

The package currently registers an **Android** Flutter plugin. Its Android
library requires API 26 or newer, Java 17, and compile SDK 36. Other Flutter
platforms do not currently have a registered native transport implementation.

## Recommended integration boundary

Use `EdgezMeshSession` for most applications. It listens to native events,
reduces them into immutable `EdgezMeshState`, gates initialization until BLE is
ready, and manages conversations, voice, topology, sensor data, and OTA state.

Use `EdgezMeshSdk` directly only when you need custom state management or need
to inject an `EdgezPlatformTransport` in tests.
