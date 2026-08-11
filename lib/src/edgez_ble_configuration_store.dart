import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

enum EdgezPreferredTransport { ble, usb }

class EdgezBleConfiguration {
  const EdgezBleConfiguration({
    this.deviceId = '',
    this.deviceName = '',
    this.autoConnect = false,
    this.shareLocation = false,
    this.preferredTransport = EdgezPreferredTransport.ble,
    this.usbVendorId = 0,
    this.usbProductId = 0,
    this.usbDeviceName = '',
    this.logLevel = EdgezDeviceLogLevel.warning,
  });

  final String deviceId;
  final String deviceName;
  final bool autoConnect;
  final bool shareLocation;
  final EdgezPreferredTransport preferredTransport;
  final int usbVendorId;
  final int usbProductId;
  final String usbDeviceName;
  final EdgezDeviceLogLevel logLevel;

  bool get hasSelectedDevice => deviceId.isNotEmpty;

  EdgezBleDevice? get selectedDevice => hasSelectedDevice
      ? EdgezBleDevice(
          id: deviceId,
          name: deviceName,
          rssi: 0,
          lastSeenMs: 0,
        )
      : null;

  bool get hasSelectedUsbDevice => usbVendorId != 0 || usbProductId != 0;
}

class EdgezBleConfigurationStore {
  static const _keyDeviceId = 'edgez_ble_device_id';
  static const _keyDeviceName = 'edgez_ble_device_name';
  static const _keyAutoConnect = 'edgez_ble_auto_connect';
  static const _keyShareLocation = 'edgez_share_location';
  static const _keyPreferredTransport = 'edgez_preferred_transport';
  static const _keyUsbVendorId = 'edgez_usb_vendor_id';
  static const _keyUsbProductId = 'edgez_usb_product_id';
  static const _keyUsbDeviceName = 'edgez_usb_device_name';
  static const _keyLogLevel = 'edgez_log_level';

  Future<EdgezBleConfiguration> load() async {
    final preferences = await SharedPreferences.getInstance();
    return EdgezBleConfiguration(
      deviceId: preferences.getString(_keyDeviceId) ?? '',
      deviceName: preferences.getString(_keyDeviceName) ?? '',
      autoConnect: preferences.getBool(_keyAutoConnect) ?? false,
      shareLocation: preferences.getBool(_keyShareLocation) ?? false,
      preferredTransport: preferences.getString(_keyPreferredTransport) == 'usb'
          ? EdgezPreferredTransport.usb
          : EdgezPreferredTransport.ble,
      usbVendorId: preferences.getInt(_keyUsbVendorId) ?? 0,
      usbProductId: preferences.getInt(_keyUsbProductId) ?? 0,
      usbDeviceName: preferences.getString(_keyUsbDeviceName) ?? '',
      logLevel: EdgezDeviceLogLevel.values.firstWhere(
        (level) => level.wireValue == preferences.getInt(_keyLogLevel),
        orElse: () => EdgezDeviceLogLevel.warning,
      ),
    );
  }

  Future<void> saveSelectedDevice(EdgezBleDevice device) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_keyDeviceId, device.id);
    await preferences.setString(_keyDeviceName, device.name);
    await preferences.setString(_keyPreferredTransport, 'ble');
  }

  Future<void> saveSelectedUsbDevice(EdgezUsbDevice device) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_keyUsbVendorId, device.vendorId);
    await preferences.setInt(_keyUsbProductId, device.productId);
    await preferences.setString(_keyUsbDeviceName, device.name);
    await preferences.setString(_keyPreferredTransport, 'usb');
  }

  Future<void> setPreferredTransport(EdgezPreferredTransport transport) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_keyPreferredTransport, transport.name);
  }

  Future<void> setAutoConnect(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keyAutoConnect, enabled);
  }

  Future<void> setShareLocation(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keyShareLocation, enabled);
  }

  Future<void> setLogLevel(EdgezDeviceLogLevel level) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_keyLogLevel, level.wireValue);
  }

  Future<void> clearSelectedDevice() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_keyDeviceId);
    await preferences.remove(_keyDeviceName);
  }
}
