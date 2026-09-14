# Migrating from SDK 0.3.2 or 0.3.3

This guide covers upgrading an Android Flutter application from EdgeZ Flutter
SDK `v0.3.2` or `v0.3.3` to the Wi-Fi-enabled SDK. The existing BLE APIs remain
available, but Wi-Fi is now the default preferred transport and is able to use
the same control services as USB and BLE.

## Compatibility summary

Most existing BLE-only applications continue to compile without changes. Check
the following areas during the upgrade:

- Add `wifi` to exhaustive switches over `EdgezConnectionType` and
  `EdgezPreferredTransport`.
- Do not restore either transport enum from a previously persisted numeric
  index. Store and restore enum names instead.
- Explicitly select `EdgezPreferredTransport.ble` if the application must keep
  the old BLE-first behavior.
- Save or provide `EdgezMeshConfig` before opening a Wi-Fi connection, so the
  session can initialize HaLow as soon as TCP becomes ready.
- Preserve `wifiSoftapEnabled` and `bleEnabled` when updating device settings.
  At least one of them must remain enabled.
- Perform a full Android rebuild. Hot reload does not install the updated
  native plugin or merge its Wi-Fi permissions.

SDK `v0.3.3` only adds transport diagnostics on top of `v0.3.2`; both versions
use the same migration steps below.

## Update and rebuild

Update the package constraint, Git tag, or Git ref in the host application's
`pubspec.yaml` to the new SDK release, then rebuild the native application:

```sh
flutter clean
flutter pub get
flutter run
```

The SDK is currently Android-only. The plugin manifest supplies
`ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`, `CHANGE_NETWORK_STATE`, and
`NEARBY_WIFI_DEVICES`; Android merges these into the host manifest. The plugin
requests the required nearby-Wi-Fi/location permission when Wi-Fi discovery is
started. If the host application removes library permissions with manifest
merge directives, allow these permissions explicitly.

## Update exhaustive transport handling

`wifi` was inserted into both connection enums:

```dart
switch (session.state.connection) {
  case EdgezConnectionType.wifi:
    // The phone is connected to an EdgeZ SoftAP and TCP control is ready.
  case EdgezConnectionType.ble:
    // BLE control is ready.
  case EdgezConnectionType.usb:
    // USB CDC control is ready.
  case EdgezConnectionType.none:
    // No device transport is connected.
}
```

Do the same for `EdgezPreferredTransport`:

```dart
switch (preferredTransport) {
  case EdgezPreferredTransport.wifi:
    // Show or reconnect the saved EdgeZ Wi-Fi network.
  case EdgezPreferredTransport.ble:
    // Scan for or reconnect the saved BLE device.
  case EdgezPreferredTransport.usb:
    // List or reconnect an attached USB device.
}
```

### Migrating persisted enum indexes

The old numeric values must not be read through the new `values[index]` order:

| Enum | 0.3.x indexes | New indexes |
| --- | --- | --- |
| `EdgezConnectionType` | `none=0`, `ble=1`, `usb=2` | `none=0`, `wifi=1`, `ble=2`, `usb=3` |
| `EdgezPreferredTransport` | `ble=0`, `usb=1` | `wifi=0`, `ble=1`, `usb=2` |

Convert old stored indexes once, then persist names:

```dart
EdgezPreferredTransport migratePreferredTransport(int oldIndex) {
  return switch (oldIndex) {
    0 => EdgezPreferredTransport.ble,
    1 => EdgezPreferredTransport.usb,
    _ => EdgezPreferredTransport.wifi,
  };
}

await preferences.setString(
  'preferred_transport',
  migratePreferredTransport(oldIndex).name,
);
```

`EdgezBleConfigurationStore` already persists transport names. Applications
using only that store do not need an index migration.

## Choose the default connection

An `EdgezBleConfiguration` with no saved preference now defaults to Wi-Fi. To
retain the old BLE-first behavior, set it explicitly in application state:

```dart
var preferredTransport = EdgezPreferredTransport.ble;
```

Previously saved `"ble"` and `"usb"` preferences continue to load normally.

## Add Wi-Fi discovery and connection

The native Android plugin lists only SSIDs beginning with `EdgeZ-`. Use the
low-level SDK to scan, then use the session to connect:

```dart
final networks = await session.sdk.listWifiNetworks();
if (networks.isEmpty) {
  throw StateError('No EdgeZ Wi-Fi network found');
}

final selectedNetwork = networks.first;
await session.connectWifi(ssid: selectedNetwork.ssid);
```

Passing the selected SSID asks Android to switch the phone to that SoftAP
before opening the control socket. Leave `host` empty to use the selected
network's IPv4 gateway; TCP port `4242` is the default:

```dart
await session.connectWifi(
  ssid: selectedNetwork.ssid,
  // host: '',
  // port: 4242,
);
```

The list method belongs to `EdgezMeshSdk`, so call
`session.sdk.listWifiNetworks()`, not `session.listWifiNetworks()`.

### Initialize configuration before connecting

Make the mesh configuration available before calling `connectWifi`. This is
the important ordering used by the example application:

```dart
await session.initializeMesh(
  EdgezMeshConfig(
    identity: identity,
    countryCode: 'EU',
    meshId: 'my-mesh',
    passphrase: 'my-passphrase',
    meshBandwidthMhz: 2,
    meshFrequencyKhz: 866000,
  ),
);

await session.connectWifi(ssid: selectedNetwork.ssid);
```

Calling `initializeMesh` while disconnected stores the configuration. Once TCP
is ready, the session sends SDK authorization followed by `INIT_HALOW`. If the
device reports that its HaLow stack is still uninitialized, the session retries
the idempotent initialization command.

Only one phone-to-device transport is active in a session. `connectWifi`,
`connectBle`, and `connectUsb` close an existing transport as needed. Use the
existing `session.disconnect()` call for every transport.

## Preserve connection-radio settings

`EdgezDeviceSettings` adds two fields, both defaulting to `true`:

```dart
wifiSoftapEnabled: true,
bleEnabled: true,
```

When changing an unrelated setting, start from the current device settings or
copy both values. Otherwise, constructing a fresh settings object can
unintentionally re-enable a radio:

```dart
final current = session.state.deviceSettings;
if (current == null) {
  await session.requestDeviceSettings();
  return;
}

await session.sendDeviceSettings(
  current.copyWith(
    wifiSoftapEnabled: false,
    bleEnabled: true,
  ),
);
```

The SDK rejects a settings update where both fields are `false`, preventing the
device from becoming unreachable through both Wi-Fi and BLE.

Older firmware does not report these protobuf fields. The session recognizes a
report where both fields are absent/false as a legacy report and exposes both
connection methods as enabled.

## OTA behavior

The Dart OTA API is unchanged:

```dart
final ready = await session.isOtaReady();
if (ready) {
  await session.performOta(image);
}
```

On current firmware, the same API selects the active transport automatically:

- BLE uses the existing OTA characteristics.
- Wi-Fi and USB use acknowledged `FW2` messages over the shared framed stream.

No OTA-specific application migration is required.

## Firmware combinations

| Flutter SDK | Firmware | Result |
| --- | --- | --- |
| New SDK | Current firmware | Wi-Fi, BLE, and USB control; transport OTA; radio toggles. |
| New SDK | Older firmware | Existing BLE features remain compatible; new Wi-Fi and radio-toggle features are unavailable. |
| SDK 0.3.2/0.3.3 | Current firmware | Existing BLE operation remains available; the old SDK cannot select Wi-Fi control or manage the new toggles. |

The added device-setting fields use new protobuf field numbers, so older
decoders safely ignore them. The SDK release compatibility remains `^0.5.0`.
Wi-Fi control nevertheless requires firmware that starts the `EdgeZ-*` SoftAP
and TCP control service.

BLE provisioning remains a BLE-only workflow. Keep the BLE selection and
connection path if the host application exposes provisioning.

## Upgrade checklist

- [ ] Update every exhaustive transport switch.
- [ ] Migrate any enum indexes to enum names.
- [ ] Explicitly keep BLE as the preferred transport if desired.
- [ ] Add Wi-Fi discovery and selection UI if using Wi-Fi.
- [ ] Call `initializeMesh` before `connectWifi`.
- [ ] Preserve both connection-radio fields when saving device settings.
- [ ] Keep at least one of Wi-Fi SoftAP or BLE enabled.
- [ ] Install current firmware before enabling Wi-Fi-only functionality.
- [ ] Run a clean Android rebuild and test Wi-Fi permission denial/retry.
- [ ] Test reconnect, HaLow initialization, settings, messaging, and OTA on
      each transport exposed by the application.

