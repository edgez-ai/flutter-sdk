# API map

Import all supported public APIs from:

```dart
import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
```

This is an orientation guide, not generated API documentation. The canonical
signatures are in [`lib/`](../lib/).

## Application facade

### `EdgezMeshSession`

Recommended entry point for applications. It is a `ChangeNotifier` with a
read-only `state` snapshot.

| Group | Members |
| --- | --- |
| BLE | `startBleScan`, `stopBleScan`, `connectBle`, `disconnect` |
| Mesh | `initializeMesh`, `restoreCachedMeshData`, `removeNode` |
| Messaging | `sendTextMessage`, `startVoiceMessage`, `finishVoiceMessage`, `cancelVoiceMessage`, `playVoiceMessage` |
| Live voice | `startVoiceCall`, `acceptVoiceCall`, `endVoiceCall` |
| Provisioning | `beginProvisioning`, `endProvisioning`, `authorizeSession`, `requestDeviceSettings`, `sendDeviceSettings` |
| OTA | `isOtaReady`, `performOta`, `abortOta` |

### `EdgezMeshState`

Immutable snapshot containing connection and readiness, BLE devices, mesh
status, nodes, sensor samples, topology, conversations, voice-call state,
device settings, OTA progress, and a user-facing status line.

## Low-level SDK

### `EdgezMeshSdk`

Sends commands to the native transport, publishes `EdgezMeshEvent` objects,
encodes protobuf packets, and handles conversation encryption. Use it when a
custom reducer or architecture cannot use `EdgezMeshSession`.

### `EdgezPlatformTransport`

Interface with an event stream and generic method invocation. Production uses
`EdgezChannelTransport`; tests can inject a fake implementation.

## Configuration and persistence

| Type | Purpose |
| --- | --- |
| `EdgezMeshConfig` | Country, network, radio, identity, hop, and beacon configuration. |
| `EdgezBeaconConfig` | Beacon interval, marker, and optional shared location. |
| `EdgezDeviceSettings` | Provisioned device mode, network, identity presentation, sensor, upstream, location, and sleep settings. |
| `EdgezIdentityStore` | Creates, loads, updates, and persists the app identity. |
| `EdgezBleConfigurationStore` | Persists selected BLE device and app preferences. |
| `EdgezDriverStore` / `EdgezDriverBundle` | Validates and persists installed Lua driver bundles. |
| `EdgezOtaRelease` | Validates OTA manifest metadata and compares versions. |

## Runtime models

| Type | Purpose |
| --- | --- |
| `EdgezBleDevice` | Scan result with platform ID, name, RSSI, and timestamp. |
| `EdgezMeshStatus` | HaLow readiness, address, licensing, and firmware status. |
| `EdgezMeshNode` | Discovered peer/device identity, route, key, marker, location, and device metadata. |
| `EdgezSensorData` / `EdgezSensorSample` | Decoded sensor values and capture timestamp. |
| `EdgezTopologyLink` | Observed mesh adjacency and RSSI. |
| `EdgezConversationMessage` | Text or voice message plus delivery state. |
| `EdgezVoiceCallState` | Current call peer, ID, and phase. |
| `EdgezMeshEvent` | Typed event emitted by the low-level SDK. |

## Generated protocol types

The public barrel also exports generated types from
[`lib/src/proto/edgez_mesh.pb.dart`](../lib/src/proto/edgez_mesh.pb.dart). Prefer
the session and model APIs unless implementing protocol-level behavior. The
schema is [`protos/edgez_mesh.proto`](../protos/edgez_mesh.proto); regeneration
instructions are in the root README.

