## 0.1.6

- Updated node coordinates from valid beacon and topology sensor GPS data.
- Added safe placeholder nodes for topology-only peers with GPS positions.
- Preserved the last valid node position when later reports contain `(0,0)`.

## 0.1.5

- Added periodic mobile GPS tracking through the dedicated
  `NetworkPacket.location_update` protocol for firmware 0.5.5 and newer.
- Added fresh Android location requests and GPS transmit/receive diagnostics.
- Decoded peer sensor data, including GPS, from topology reports.
- Ignored invalid `(0,0)` GPS values so they cannot replace a valid location.
- Inherited the host app's Android compile SDK by default, with a documented
  standalone fallback and override.

## 0.1.4

- Improved BLE setup compatibility across Android devices with MTU fallback,
  service-discovery retries, notification subscription diagnostics, and clearer
  connection status messages.
- Added Android foreground BLE operation and native notifications for incoming
  encrypted messages and voice calls.
- Added a dedicated incoming, outgoing, and active voice-call screen with
  lock-screen support and elapsed call time.
- Added incoming-message and incoming-call session callbacks.
- Expanded integration, API, feature, and background-notification documentation.

## 0.1.3

- Added provisioning support for HaLow country, frequency, and bandwidth.

## 0.1.2

- Improved the Android example and release build configuration.

## 0.1.1

- Added initial release packaging and documentation improvements.

## 0.1.0

- Initial EdgeZ Flutter SDK with Android BLE transport, mesh state, nodes,
  encrypted conversations, sensor data, provisioning, and OTA support.
