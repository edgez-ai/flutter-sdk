import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class EdgezBleConfiguration {
  const EdgezBleConfiguration({
    this.deviceId = '',
    this.deviceName = '',
    this.autoConnect = false,
  });

  final String deviceId;
  final String deviceName;
  final bool autoConnect;

  bool get hasSelectedDevice => deviceId.isNotEmpty;

  EdgezBleDevice? get selectedDevice => hasSelectedDevice
      ? EdgezBleDevice(
          id: deviceId,
          name: deviceName,
          rssi: 0,
          lastSeenMs: 0,
        )
      : null;
}

class EdgezBleConfigurationStore {
  static const _keyDeviceId = 'edgez_ble_device_id';
  static const _keyDeviceName = 'edgez_ble_device_name';
  static const _keyAutoConnect = 'edgez_ble_auto_connect';

  Future<EdgezBleConfiguration> load() async {
    final preferences = await SharedPreferences.getInstance();
    return EdgezBleConfiguration(
      deviceId: preferences.getString(_keyDeviceId) ?? '',
      deviceName: preferences.getString(_keyDeviceName) ?? '',
      autoConnect: preferences.getBool(_keyAutoConnect) ?? false,
    );
  }

  Future<void> saveSelectedDevice(EdgezBleDevice device) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_keyDeviceId, device.id);
    await preferences.setString(_keyDeviceName, device.name);
  }

  Future<void> setAutoConnect(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keyAutoConnect, enabled);
  }

  Future<void> clearSelectedDevice() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_keyDeviceId);
    await preferences.remove(_keyDeviceName);
  }
}
