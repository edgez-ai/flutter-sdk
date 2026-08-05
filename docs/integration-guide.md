# Integration guide

This guide follows the session-based integration used by the example app.

## 1. Add the package

For a sibling checkout, add a path dependency:

```yaml
dependencies:
  edgez_flutter_sdk:
    path: ../flutter-sdk
```

Then fetch packages:

```sh
flutter pub get
```

The package currently supports Android with `minSdk 26`. The plugin declares
Bluetooth scan/connect, location, microphone, notification, foreground-service,
and full-screen-intent permissions in its manifest.
Add `INTERNET` in the host application when it downloads OTA or marketplace
assets. Android still requires runtime grants for protected permissions; the
native plugin requests the permissions needed by its operations.

Import the public barrel only:

```dart
import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
```

## 2. Own and dispose a session

Create one session for the lifetime of the feature or application. Listen to it
with `addListener`, `ListenableBuilder`, or your preferred state-management
adapter.

```dart
class MeshController extends ChangeNotifier {
  MeshController() {
    session.addListener(_sessionChanged);
  }

  final EdgezMeshSession session = EdgezMeshSession();

  EdgezMeshState get state => session.state;

  void _sessionChanged() => notifyListeners();

  @override
  void dispose() {
    session.removeListener(_sessionChanged);
    session.dispose();
    super.dispose();
  }
}
```

See the lifecycle in [`example/lib/src/app.dart`](../example/lib/src/app.dart).

## 3. Load an identity

An identity is required for mesh discovery and encrypted conversations.

```dart
final identityStore = EdgezIdentityStore();
final identity = await identityStore.getOrCreate();
```

Keep the same identity between launches. Calling `regenerateKeyPair` changes
the peer key used for encrypted communication.

## 4. Prepare mesh configuration

Give the session its mesh config before or immediately after connecting. The
example prepares it before connecting so a fast native `ready` event cannot
race ahead of configuration.

```dart
await session.initializeMesh(
  EdgezMeshConfig(
    identity: identity,
    countryCode: 'SE',
    meshId: 'my-mesh',
    passphrase: 'replace-with-your-mesh-secret',
    maxHop: 4,
    beacon: const EdgezBeaconConfig(
      intervalSeconds: 30,
      marker: 'blue',
      shareLocation: false,
    ),
  ),
);
```

`countryCode` is limited to two characters, `meshId` to 32, identity name to
64, and passphrase to 64 by the packet encoder. Beacon intervals normalize to
5–3600 seconds. Use radio frequency and bandwidth values supported by the
target firmware and regulatory region.

## 5. Scan and connect

```dart
await session.startBleScan();

// Render session.state.sortedBleDevices and let the user select one.
await session.stopBleScan();
await session.connectBle(selectedDevice.id);
```

Wait until `state.connection == EdgezConnectionType.ble` and
`state.bleReady == true`. Mesh initialization is then sent automatically using
the most recent config. Do not treat the return from `connectBle` alone as proof
that service discovery and mesh initialization are complete.

For reconnect support, `EdgezBleConfigurationStore` can persist the selected
device, auto-connect choice, and location-sharing choice.

## 6. Render live state

```dart
ListenableBuilder(
  listenable: session,
  builder: (context, _) {
    final state = session.state;
    return Text(
      '${state.statusLine}\n'
      '${state.sortedNodes.length} node(s), '
      '${state.topologyLinks.length} link(s)',
    );
  },
)
```

Incoming native events are decoded and merged into the session snapshot. The
example persists selected parts of that snapshot in
[`example_database.dart`](../example/lib/src/example_database.dart), then uses
`restoreCachedMeshData` at startup. A production app should set its own data
retention limits, particularly for sensor samples and voice bytes.

## 7. Send messages

Only user-like nodes (`node.opensConversation == true`) can receive
conversation messages.

```dart
await session.sendTextMessage(
  toNode: peer.nodeNum,
  text: 'Hello over EdgeZ',
  maxHop: 4,
);
```

The session adds a queued message immediately, then replaces its status after
the transport succeeds or fails. Messages are available at
`state.conversations[peer.nodeNum]`.

For voice messages:

```dart
final started = await session.startVoiceMessage();
if (started) {
  // Call this after the user finishes recording.
  await session.finishVoiceMessage(toNode: peer.nodeNum, maxHop: 4);
}
```

Use `cancelVoiceMessage` to discard a recording and `playVoiceMessage` to replay
a received message. Live calls use `startVoiceCall`, `acceptVoiceCall`, and
`endVoiceCall`; render the current phase from `state.voiceCall`.

For Android system notifications while backgrounded or locked, construct the
session with `onIncomingMessage` and `onIncomingCall`, request notification
permission before connecting, and invoke the native notification helpers from
those callbacks. See [Background notifications and calls](background-notifications.md)
for the complete manifest, deep-link, call-action, and lifecycle setup.

## 8. Provision a device

Provisioning is a separate control flow from normal mesh use:

1. Disconnect the current device and call `session.beginProvisioning()`.
2. Scan, select the target, stop scanning, and connect.
3. Wait for `state.bleReady`.
4. Call `authorizeSession()` and wait for an authorized license in
   `state.status.licenseStatus`.
5. Call `requestDeviceSettings()` and wait for `state.deviceSettings`.
6. Let the user edit settings and create a separate device identity with
   `EdgezIdentityStore().createIdentity(...)`.
7. Call `sendDeviceSettings(settings, identity: deviceIdentity, scripts: ...)`.
8. Disconnect and call `session.endProvisioning()`.

Use [`provisioning_screen.dart`](../example/lib/src/provisioning_screen.dart) as
the detailed reference, including timeouts and rejected-license handling.

## 9. Install and upload sensor drivers

The host app is responsible for resolving marketplace links and downloading
remote content. Once validated, store a complete bundle:

```dart
final stored = await EdgezDriverStore().save(
  bundle,
  imageBytes: optionalImageBytes,
);

await session.sendDeviceSettings(
  deviceSettings,
  identity: deviceIdentity,
  scripts: <EdgezSensorScriptConfig>[stored.toScriptConfig()],
);
```

`EdgezDriverStore` accepts driver IDs containing letters, digits, `.`, `_`, and
`-`, and requires non-empty metadata and Lua source. See
[`marketplace_driver_install.dart`](../example/lib/src/marketplace_driver_install.dart)
for URL, response, and image validation.

## 10. Perform firmware OTA

The host downloads the manifest and image; the SDK validates manifest fields
and performs the BLE transfer.

```dart
final release = EdgezOtaRelease.fromJson(manifestJson);
final current = session.state.status?.firmwareVersion ?? '';

if (release.isNewerThan(current) && session.state.otaReady) {
  final image = await downloadFirmware(release.url);
  if (image.length != release.size) {
    throw StateError('Firmware size does not match its manifest');
  }
  await session.performOta(image);
}
```

Render `state.otaProgress` while `state.otaInProgress` is true. Call
`abortOta()` to cancel. Production code should require HTTPS and add integrity
or signature verification if the firmware service provides it.

## 11. Handle errors and teardown

- Async session methods that must expose failure to the caller rethrow; others
  report the failure through `state.statusLine`. Check each operation in the
  UI rather than assuming all failures throw.
- Stop scanning when the selection screen closes.
- End active recording/calls before leaving communication UI when appropriate.
- Call `disconnect` when explicitly leaving the device, and always `dispose`
  the session to cancel its native event subscription.
- Test without hardware by injecting a fake `EdgezPlatformTransport`; see
  [`test/support/mock_ble_transport.dart`](../test/support/mock_ble_transport.dart).

## Production checklist

- Android API 26+, Java 17, and required runtime permission UX are configured.
- Identity and mesh secrets have storage appropriate to the app's threat model.
- Connection UI distinguishes connected, BLE-ready, and mesh-ready states.
- License rejection and provisioning timeouts have visible recovery paths.
- Remote OTA and marketplace responses are authenticated and validated.
- Cached telemetry and voice data have explicit retention and deletion rules.
- Hardware tests cover scan, reconnect, messaging, provisioning, and OTA cancel.
- Locked-screen hardware tests cover message delivery and call Answer/Decline.
