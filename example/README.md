# EdgeZ Flutter SDK Example

This is a conventional Flutter example app for the EdgeZ Flutter SDK.

It intentionally keeps all users, conversations, selected node state, and settings in memory. It does not use SQLite and it does not include the map UI.

Run it from this directory when Flutter tooling is installed:

```sh
flutter pub get
flutter run
```

The Nodes tab includes a **Prov** action that follows the Android app's
eight-step BLE device-provisioning flow. The Drivers tab lists the same bundled
UART/I2C and RS485 Lua drivers as `edgez-android-app`; selected drivers are
uploaded to the device with the provisioning settings.

Marketplace links use
`edgez://drivers/install?id=<uuid>&slug=<slug>`. The example validates the link,
downloads and validates the marketplace bundle and HTTPS image, asks for install
confirmation, and then saves it through the SDK's `EdgezDriverStore`.
