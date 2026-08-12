## 0.2.1

- Fixed Organic Maps region downloads crashing in minified Android release
  builds when JNI resolves `HttpClient.runAsync` and OkHttp cancellation.
- Preserved Java types used in JNI method descriptors and `cancel()` on
  concrete `okhttp3.Call` implementations without disabling host-app R8.

## 0.2.0

- Added automatic Android consumer R8/ProGuard rules for the Organic Maps Java
  API used through JNI.
- Fixed optimized release builds crashing in
  `BookmarkManager.nativeLoadBookmarks()` during map initialization.
- Preserved native entry-point names while allowing the rest of the host app
  to remain minified and optimized.

## 0.1.9

- Added the Organic Maps-based Android map widget with mesh-node markers,
  current-position tracking, synchronized embedded/full-screen cameras, and
  offline map-region downloads.
- Added 2D/3D perspective and day/night map controls.
- Updated the Android map library to Organic Maps 0.0.5 and added online XYZ
  satellite imagery plus direct offline MBTiles support.
- Added a bundled Stockholm satellite-map demonstration to the example app.

## 0.1.8

- Added mesh speed-test support and related example-app improvements.

## 0.1.7

- Excluded the local device from SDK node discovery, including topology GPS
  placeholders created before or after device status is received.

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
