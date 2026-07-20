import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'shared_widgets.dart';

List<int> halowFrequenciesKhz(String country, int bandwidthMhz) {
  List<int> range(int start, int end, int step) =>
      <int>[for (var value = start; value <= end; value += step) value];
  return switch (country) {
    'US' => switch (bandwidthMhz) {
        1 => range(902500, 927500, 1000),
        2 => range(903000, 927000, 2000),
        4 => range(904000, 926000, 4000),
        8 => range(908000, 924000, 8000),
        _ => const <int>[],
      },
    'JP' => switch (bandwidthMhz) {
        1 => range(920500, 927500, 1000),
        2 => range(921000, 927000, 2000),
        4 => const <int>[922000, 926000],
        8 => const <int>[924000],
        _ => const <int>[],
      },
    'EU' => switch (bandwidthMhz) {
        1 => range(863500, 867500, 1000),
        2 => const <int>[864000, 866000],
        4 => const <int>[865000],
        _ => const <int>[],
      },
    _ => const <int>[],
  };
}

List<int> halowBandwidthOptions(String country) => <int>[1, 2, 4, 8]
    .where((value) => halowFrequenciesKhz(country, value).isNotEmpty)
    .toList(growable: false);

String halowFrequencyLabel(String country, int frequencyKhz) {
  final baseKhz = switch (country) {
    'US' => 902000,
    'JP' => 920000,
    'EU' => 863000,
    _ => frequencyKhz,
  };
  final channel = (frequencyKhz - baseKhz) ~/ 500;
  return 'Channel $channel - ${frequencyKhz / 1000} MHz';
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.activeConnection,
    required this.shareLocation,
    required this.autoReplayReceivedVoice,
    required this.deviceModeEnabled,
    required this.bleDevices,
    required this.statusLine,
    required this.meshCountry,
    required this.meshId,
    required this.passphrase,
    required this.maxHop,
    required this.meshBandwidthMhz,
    required this.meshFrequencyKhz,
    required this.beaconIntervalSeconds,
    required this.userName,
    required this.userIdentity,
    required this.userMarker,
    required this.deviceUserName,
    required this.deviceMarker,
    required this.deviceMeshId,
    required this.deviceMaxHop,
    required this.deviceBeaconIntervalSeconds,
    required this.deviceShareLocation,
    required this.deviceLatitude,
    required this.deviceLongitude,
    required this.deviceGeoFenceName,
    required this.deviceGeoIndex,
    required this.uartI2cSensorType,
    required this.rs485SensorType,
    required this.deviceType,
    required this.devicePassphrase,
    required this.deviceUpstreamEnabled,
    required this.deviceUpstreamWifiSsid,
    required this.deviceUpstreamWifiPassphrase,
    required this.deviceBeaconMulticast,
    required this.deviceSleepModeEnabled,
    required this.onConnectBle,
    required this.onStopBleScan,
    required this.onConnectBleDevice,
    required this.onDisconnect,
    required this.onSaveAppSettings,
    required this.onRegenerateUserKeyPair,
    required this.onSaveDeviceSettings,
    required this.onShareLocationChanged,
    required this.onAutoReplayChanged,
    required this.onDeviceModeChanged,
    required this.onMeshCountryChanged,
    required this.onMeshBandwidthChanged,
    required this.onMeshFrequencyChanged,
    required this.onMeshIdChanged,
    required this.onPassphraseChanged,
    required this.onMaxHopChanged,
    required this.onBeaconIntervalChanged,
    required this.onUserNameChanged,
    required this.onUserMarkerChanged,
    required this.onDeviceUserNameChanged,
    required this.onDeviceMarkerChanged,
    required this.onDeviceMeshIdChanged,
    required this.onDeviceMaxHopChanged,
    required this.onDeviceBeaconIntervalChanged,
    required this.onDeviceShareLocationChanged,
    required this.onDeviceLatitudeChanged,
    required this.onDeviceLongitudeChanged,
    required this.onDeviceGeoFenceNameChanged,
    required this.onDeviceGeoIndexChanged,
    required this.onUartI2cSensorChanged,
    required this.onRs485SensorChanged,
    required this.onDeviceTypeChanged,
    required this.onDevicePassphraseChanged,
    required this.onDeviceUpstreamEnabledChanged,
    required this.onDeviceUpstreamWifiSsidChanged,
    required this.onDeviceUpstreamWifiPassphraseChanged,
    required this.onDeviceBeaconMulticastChanged,
    required this.onDeviceSleepModeChanged,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final bool shareLocation;
  final bool autoReplayReceivedVoice;
  final bool deviceModeEnabled;
  final List<EdgezBleDevice> bleDevices;
  final String statusLine;
  final String meshCountry;
  final String meshId;
  final String passphrase;
  final String maxHop;
  final int meshBandwidthMhz;
  final int meshFrequencyKhz;
  final String beaconIntervalSeconds;
  final String userName;
  final EdgezUserIdentity? userIdentity;
  final ExampleMarker userMarker;
  final String deviceUserName;
  final ExampleMarker deviceMarker;
  final String deviceMeshId;
  final String deviceMaxHop;
  final String deviceBeaconIntervalSeconds;
  final bool deviceShareLocation;
  final String deviceLatitude;
  final String deviceLongitude;
  final String deviceGeoFenceName;
  final int deviceGeoIndex;
  final String uartI2cSensorType;
  final String rs485SensorType;
  final String deviceType;
  final String devicePassphrase;
  final bool deviceUpstreamEnabled;
  final String deviceUpstreamWifiSsid;
  final String deviceUpstreamWifiPassphrase;
  final String deviceBeaconMulticast;
  final bool deviceSleepModeEnabled;
  final VoidCallback onConnectBle;
  final VoidCallback onStopBleScan;
  final ValueChanged<String> onConnectBleDevice;
  final VoidCallback onDisconnect;
  final FutureOr<void> Function() onSaveAppSettings;
  final FutureOr<void> Function() onRegenerateUserKeyPair;
  final FutureOr<void> Function() onSaveDeviceSettings;
  final ValueChanged<bool> onShareLocationChanged;
  final ValueChanged<bool> onAutoReplayChanged;
  final ValueChanged<bool> onDeviceModeChanged;
  final ValueChanged<String> onMeshCountryChanged;
  final ValueChanged<int> onMeshBandwidthChanged;
  final ValueChanged<int> onMeshFrequencyChanged;
  final ValueChanged<String> onMeshIdChanged;
  final ValueChanged<String> onPassphraseChanged;
  final ValueChanged<String> onMaxHopChanged;
  final ValueChanged<String> onBeaconIntervalChanged;
  final ValueChanged<String> onUserNameChanged;
  final ValueChanged<ExampleMarker> onUserMarkerChanged;
  final ValueChanged<String> onDeviceUserNameChanged;
  final ValueChanged<ExampleMarker> onDeviceMarkerChanged;
  final ValueChanged<String> onDeviceMeshIdChanged;
  final ValueChanged<String> onDeviceMaxHopChanged;
  final ValueChanged<String> onDeviceBeaconIntervalChanged;
  final ValueChanged<bool> onDeviceShareLocationChanged;
  final ValueChanged<String> onDeviceLatitudeChanged;
  final ValueChanged<String> onDeviceLongitudeChanged;
  final ValueChanged<String> onDeviceGeoFenceNameChanged;
  final ValueChanged<int> onDeviceGeoIndexChanged;
  final ValueChanged<String> onUartI2cSensorChanged;
  final ValueChanged<String> onRs485SensorChanged;
  final ValueChanged<String> onDeviceTypeChanged;
  final ValueChanged<String> onDevicePassphraseChanged;
  final ValueChanged<bool> onDeviceUpstreamEnabledChanged;
  final ValueChanged<String> onDeviceUpstreamWifiSsidChanged;
  final ValueChanged<String> onDeviceUpstreamWifiPassphraseChanged;
  final ValueChanged<String> onDeviceBeaconMulticastChanged;
  final ValueChanged<bool> onDeviceSleepModeChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          InfoCard(
            title: 'BLE connection',
            children: <Widget>[
              Text('Active connection: ${activeConnection.name.toUpperCase()}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                      onPressed: onConnectBle,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Scan BLE')),
                  OutlinedButton.icon(
                      onPressed: onStopBleScan,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop')),
                  OutlinedButton.icon(
                      onPressed: onDisconnect,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect')),
                  OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.battery_saver),
                      label: const Text('Battery optimization')),
                ],
              ),
              if (statusLine.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(statusLine, style: Theme.of(context).textTheme.bodySmall)
              ],
              const SizedBox(height: 10),
              if (bleDevices.isEmpty)
                const Text('No BLE devices found yet.')
              else
                for (final device in bleDevices)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bluetooth),
                    title:
                        Text(device.name.isEmpty ? 'BLE device' : device.name),
                    subtitle: Text('${device.id} · RSSI ${device.rssi}'),
                    trailing: FilledButton(
                      onPressed: () => onConnectBleDevice(device.id),
                      child: const Text('Connect'),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'User mesh settings',
            children: <Widget>[
              Text(
                  'These settings join the phone to the mesh as a normal user.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              DropdownSetting<String>(
                  label: 'Country',
                  value: meshCountry,
                  values: const <String>['US', 'JP', 'EU'],
                  titleFor: (value) => value,
                  onChanged: onMeshCountryChanged),
              DropdownSetting<int>(
                label: 'Bandwidth',
                value: meshBandwidthMhz,
                values: halowBandwidthOptions(meshCountry),
                titleFor: (value) => '$value MHz',
                onChanged: onMeshBandwidthChanged,
              ),
              DropdownSetting<int>(
                label: 'Frequency',
                value: meshFrequencyKhz,
                values: halowFrequenciesKhz(
                  meshCountry,
                  meshBandwidthMhz,
                ),
                titleFor: (value) => halowFrequencyLabel(meshCountry, value),
                onChanged: onMeshFrequencyChanged,
              ),
              SettingsTextField(
                  label: 'Mesh ID', value: meshId, onChanged: onMeshIdChanged),
              SettingsTextField(
                  label: 'Passphrase',
                  value: passphrase,
                  onChanged: onPassphraseChanged,
                  obscureText: true),
              SettingsTextField(
                  label: 'Max hop',
                  value: maxHop,
                  onChanged: onMaxHopChanged,
                  keyboardType: TextInputType.number),
              SettingsTextField(
                  label: 'Beacon interval seconds',
                  value: beaconIntervalSeconds,
                  onChanged: onBeaconIntervalChanged,
                  keyboardType: TextInputType.number),
              SettingsTextField(
                  label: 'User name',
                  value: userName,
                  onChanged: onUserNameChanged),
              const SizedBox(height: 8),
              IdentitySummary(
                identity: userIdentity,
                onRegenerateUserKeyPair: onRegenerateUserKeyPair,
              ),
              DropdownSetting<ExampleMarker>(
                label: 'Marker',
                value: userMarker,
                values: ExampleMarker.values,
                titleFor: (value) => value.label,
                onChanged: onUserMarkerChanged,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share location'),
                value: shareLocation,
                onChanged: onShareLocationChanged,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto replay received voice'),
                value: autoReplayReceivedVoice,
                onChanged: onAutoReplayChanged,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                    onPressed: () =>
                        unawaited(Future<void>.value(onSaveAppSettings())),
                    child: const Text('Save settings')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Device mode',
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Device mode'),
                value: deviceModeEnabled,
                onChanged: onDeviceModeChanged,
              ),
              if (!deviceModeEnabled)
                Text(
                    'Enable device mode to configure device identity, beacon, geofence, and sensors.',
                    style: Theme.of(context).textTheme.bodySmall),
              if (deviceModeEnabled) ...<Widget>[
                DropdownSetting<String>(
                  label: 'Device profile',
                  value: deviceType,
                  values: const <String>['beacon', 'sensor', 'relay'],
                  titleFor: (value) => switch (value) {
                    'beacon' => 'Beacon',
                    'sensor' => 'Sensor',
                    _ => 'Relay',
                  },
                  onChanged: onDeviceTypeChanged,
                ),
                SettingsTextField(
                    label: 'Device user name',
                    value: deviceUserName,
                    onChanged: onDeviceUserNameChanged),
                DropdownSetting<ExampleMarker>(
                  label: 'Device marker',
                  value: deviceMarker,
                  values: ExampleMarker.values,
                  titleFor: (value) => value.label,
                  onChanged: onDeviceMarkerChanged,
                ),
                SettingsTextField(
                    label: 'Device mesh ID',
                    value: deviceMeshId,
                    onChanged: onDeviceMeshIdChanged),
                SettingsTextField(
                  label: 'Device passphrase',
                  value: devicePassphrase,
                  onChanged: onDevicePassphraseChanged,
                  obscureText: true,
                ),
                SettingsTextField(
                    label: 'Device max hop',
                    value: deviceMaxHop,
                    onChanged: onDeviceMaxHopChanged,
                    keyboardType: TextInputType.number),
                SettingsTextField(
                    label: 'Device beacon interval seconds',
                    value: deviceBeaconIntervalSeconds,
                    onChanged: onDeviceBeaconIntervalChanged,
                    keyboardType: TextInputType.number),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Device share location'),
                  value: deviceShareLocation,
                  onChanged: onDeviceShareLocationChanged,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                        child: SettingsTextField(
                            label: 'Latitude',
                            value: deviceLatitude,
                            onChanged: onDeviceLatitudeChanged,
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: SettingsTextField(
                            label: 'Longitude',
                            value: deviceLongitude,
                            onChanged: onDeviceLongitudeChanged,
                            keyboardType: TextInputType.number)),
                  ],
                ),
                SettingsTextField(
                    label: 'Geo fence',
                    value: deviceGeoFenceName,
                    onChanged: onDeviceGeoFenceNameChanged),
                StepperSetting(
                    label: 'Geo index',
                    value: deviceGeoIndex,
                    onChanged: onDeviceGeoIndexChanged),
                DropdownSetting<String>(
                  label: 'UART/I2C sensor',
                  value: uartI2cSensorType,
                  values: const <String>[
                    '',
                    'sht3x_temperature_humidity',
                    'random_temperature_sample'
                  ],
                  titleFor: (value) => value.isEmpty ? 'None' : value,
                  onChanged: onUartI2cSensorChanged,
                ),
                DropdownSetting<String>(
                  label: 'RS485 sensor',
                  value: rs485SensorType,
                  values: const <String>[
                    '',
                    'vibration_sensor_rs485',
                    'flow_meter_rs485'
                  ],
                  titleFor: (value) => value.isEmpty ? 'None' : value,
                  onChanged: onRs485SensorChanged,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable upstream network'),
                  subtitle: const Text(
                      'Forward through Wi-Fi and send beacons to a multicast address.'),
                  value: deviceUpstreamEnabled,
                  onChanged: onDeviceUpstreamEnabledChanged,
                ),
                if (deviceUpstreamEnabled) ...<Widget>[
                  SettingsTextField(
                    label: 'Upstream Wi-Fi SSID',
                    value: deviceUpstreamWifiSsid,
                    onChanged: onDeviceUpstreamWifiSsidChanged,
                  ),
                  SettingsTextField(
                    label: 'Upstream Wi-Fi passphrase',
                    value: deviceUpstreamWifiPassphrase,
                    onChanged: onDeviceUpstreamWifiPassphraseChanged,
                    obscureText: true,
                  ),
                  DropdownSetting<String>(
                    label: 'Beacon multicast',
                    value: deviceBeaconMulticast,
                    values: const <String>[
                      '',
                      '224.0.0.1',
                      '224.0.0.251',
                      '239.255.255.250',
                      '239.255.0.1',
                      '239.192.0.1',
                    ],
                    titleFor: (value) => switch (value) {
                      '' => 'Not set',
                      '224.0.0.1' => '224.0.0.1 - all hosts',
                      '224.0.0.251' => '224.0.0.251 - mDNS',
                      '239.255.255.250' => '239.255.255.250 - SSDP',
                      '239.255.0.1' => '239.255.0.1 - site-local',
                      _ => '239.192.0.1 - organization-local',
                    },
                    onChanged: onDeviceBeaconMulticastChanged,
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable sleep mode'),
                  subtitle:
                      const Text('Allow the device to enter low-power sleep.'),
                  value: deviceSleepModeEnabled,
                  onChanged: onDeviceSleepModeChanged,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                      onPressed: () =>
                          unawaited(Future<void>.value(onSaveDeviceSettings())),
                      child: const Text('Save device settings')),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class IdentitySummary extends StatelessWidget {
  const IdentitySummary({
    required this.identity,
    required this.onRegenerateUserKeyPair,
    super.key,
  });

  final EdgezUserIdentity? identity;
  final FutureOr<void> Function() onRegenerateUserKeyPair;

  @override
  Widget build(BuildContext context) {
    final current = identity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: current == null
          ? const <Widget>[
              Text('User identity'),
              Text('Loading identity'),
            ]
          : <Widget>[
              Text('User identity',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('UUID ${current.userUuid}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text('X25519 public key',
                  style: Theme.of(context).textTheme.titleSmall),
              SelectableText(edgezFormatHex(current.publicKey),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text('X25519 private key',
                  style: Theme.of(context).textTheme.titleSmall),
              SelectableText(edgezFormatHex(current.privateKey),
                  style: Theme.of(context).textTheme.bodySmall),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () =>
                      unawaited(Future<void>.value(onRegenerateUserKeyPair())),
                  child: const Text('Regenerate key pair'),
                ),
              ),
            ],
    );
  }
}

class DropdownSetting<T> extends StatelessWidget {
  const DropdownSetting({
    required this.label,
    required this.value,
    required this.values,
    required this.titleFor,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) titleFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) =>
              DropdownMenuItem<T>(value: item, child: Text(titleFor(item))))
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class SettingsTextField extends StatefulWidget {
  const SettingsTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SettingsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && controller.text != widget.value) {
      controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
            labelText: widget.label, border: const OutlineInputBorder()),
      ),
    );
  }
}

class StepperSetting extends StatelessWidget {
  const StepperSetting(
      {required this.label,
      required this.value,
      required this.onChanged,
      super.key});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text('$label $value')),
        IconButton(
            onPressed: value <= 0 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove)),
        IconButton(
            onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add)),
      ],
    );
  }
}
