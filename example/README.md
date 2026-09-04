# EdgeZ Flutter SDK Example

This is a conventional Flutter example app for the EdgeZ Flutter SDK.

It persists nodes, conversations, sensor history, geofences, and dashboard
preferences in SQLite. Current UI selections and settings remain in widget
state. The example does not include the map UI.

Run it from this directory when Flutter tooling is installed:

```sh
flutter pub get
flutter run
```

## Localization

The app ships with English, Simplified Chinese, French, Spanish, German, and
Japanese. On first launch it follows the device locale when supported and falls
back to English otherwise. A language selected under **Settings > Others** is
saved with `shared_preferences` and overrides the device locale.

Translations live in `assets/i18n/app_<language-code>.arb`. ARB is JSON with
Flutter localization metadata. After editing a catalog, regenerate the typed
localization classes with:

```sh
flutter gen-l10n
```

The Nodes tab includes a **Prov** action that follows the Android app's
eight-step BLE device-provisioning flow. Only the Random Temperature sample is
bundled; production UART/I2C and RS485 drivers are installed from the
marketplace. Selected drivers are uploaded with the provisioning settings.

Marketplace links use
`edgez://drivers/install?id=<uuid>&slug=<slug>`. The example validates the link,
downloads and validates the marketplace bundle and HTTPS image, asks for install
confirmation, and then saves it through the SDK's `EdgezDriverStore`.

## Background messages and calls

The example requests Android notification permission before connecting BLE.
While connected, the plugin runs a `connectedDevice` foreground service. Text
and completed voice messages appear as Android notifications; incoming calls
use a high-priority call notification that can show over the lock screen and
routes Open, Answer, and Decline links back into the active Flutter session.
Incoming, outgoing, and active calls use a dedicated full-screen UI. After
Answer, it remains visible over the lock screen until the call ends; microphone
permission must already be granted. The conversation call banner is disabled,
and the active screen displays elapsed call time.

After pulling native notification changes, fully stop and rebuild the app:

```sh
flutter clean
flutter pub get
flutter run
```

Hot reload does not update the Android manifest, service, notification
channels, or `MainActivity`. See
[`doc/background-notifications.md`](../doc/background-notifications.md) for
permissions, Android 14 full-screen intent behavior, and the locked-screen test
checklist.
