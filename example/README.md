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

The Nodes tab includes a **Prov** action that follows the Android app's
eight-step BLE device-provisioning flow. Only the Random Temperature sample is
bundled; production UART/I2C and RS485 drivers are installed from the
marketplace. Selected drivers are uploaded with the provisioning settings.

Marketplace links use
`edgez://drivers/install?id=<uuid>&slug=<slug>`. The example validates the link,
downloads and validates the marketplace bundle and HTTPS image, asks for install
confirmation, and then saves it through the SDK's `EdgezDriverStore`.
