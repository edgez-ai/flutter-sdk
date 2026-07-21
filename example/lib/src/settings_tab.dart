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

enum _SettingsTab { user, meshNetwork, others }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.activeConnection,
    required this.shareLocation,
    required this.autoReplayReceivedVoice,
    required this.deviceModeEnabled,
    required this.bleDevices,
    required this.selectedBleDevice,
    required this.meshStatus,
    required this.bleAutoConnect,
    required this.statusLine,
    required this.otaAvailableVersion,
    required this.otaCheckInProgress,
    required this.otaInProgress,
    required this.otaProgress,
    required this.otaMessage,
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
    required this.onSelectBleDevice,
    required this.onBleAutoConnectChanged,
    required this.onDisconnect,
    required this.onCheckForOtaUpdate,
    required this.onInstallOtaUpdate,
    required this.onAbortOta,
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
  final EdgezBleDevice? selectedBleDevice;
  final EdgezMeshStatus? meshStatus;
  final bool bleAutoConnect;
  final String statusLine;
  final String? otaAvailableVersion;
  final bool otaCheckInProgress;
  final bool otaInProgress;
  final double otaProgress;
  final String otaMessage;
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
  final ValueChanged<EdgezBleDevice> onSelectBleDevice;
  final ValueChanged<bool> onBleAutoConnectChanged;
  final VoidCallback onDisconnect;
  final FutureOr<void> Function() onCheckForOtaUpdate;
  final FutureOr<void> Function() onInstallOtaUpdate;
  final FutureOr<void> Function() onAbortOta;
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
  State<SettingsScreen> createState() => _SettingsScreenState();

  Widget _buildContent(
    BuildContext context, {
    required _SettingsTab selectedTab,
    required TabController tabController,
    required ValueChanged<int> onTabChanged,
    required VoidCallback onSelectBle,
  }) {
    const cardGap = SizedBox(height: 12);
    final sensorsEnabled =
        uartI2cSensorType.isNotEmpty || rs485SensorType.isNotEmpty;
    final geoFenceEnabled = deviceGeoFenceName.trim().isNotEmpty;
    final selectedBle = selectedBleDevice;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          if (statusLine.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(statusLine, style: Theme.of(context).textTheme.bodySmall),
          ],
          cardGap,
          InfoCard(
            title: 'BLE connection',
            action: OutlinedButton(
              onPressed: onSelectBle,
              child: const Text('Select'),
            ),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Selected device',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(selectedBle?.label ?? 'No BLE device selected'),
                        if (selectedBle != null)
                          Text(
                            selectedBle.id,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          activeConnection == EdgezConnectionType.ble
                              ? 'BLE connected'
                              : 'BLE disconnected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (activeConnection == EdgezConnectionType.ble &&
                            meshStatus?.firmwareVersion.isNotEmpty == true)
                          Text(
                            'Firmware: ${meshStatus!.firmwareVersion}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Row(
                          children: <Widget>[
                            Icon(
                              meshStatus?.licensed == true
                                  ? Icons.verified
                                  : meshStatus == null
                                      ? Icons.help_outline
                                      : Icons.gpp_bad_outlined,
                              size: 16,
                              color: meshStatus?.licensed == true
                                  ? Theme.of(context).colorScheme.primary
                                  : meshStatus == null
                                      ? Theme.of(context).colorScheme.outline
                                      : Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'License: ${meshStatus?.licenseStatus.label ?? 'Waiting for device status'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: activeConnection == EdgezConnectionType.ble
                        ? onDisconnect
                        : selectedBle == null
                            ? null
                            : () => onConnectBleDevice(selectedBle.id),
                    child: Text(
                      activeConnection == EdgezConnectionType.ble
                          ? 'Disconnect'
                          : 'Connect',
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto connect'),
                subtitle: const Text(
                  'Connect the selected BLE device on app start and reconnect if it drops',
                ),
                value: bleAutoConnect,
                onChanged: onBleAutoConnectChanged,
              ),
            ],
          ),
          cardGap,
          TabBar(
            controller: tabController,
            onTap: onTabChanged,
            tabs: const <Widget>[
              Tab(text: 'User'),
              Tab(text: 'Mesh Network'),
              Tab(text: 'Others'),
            ],
          ),
          if (selectedTab == _SettingsTab.user) ...<Widget>[
            cardGap,
            InfoCard(
              title: deviceModeEnabled ? 'Device user' : 'User',
              children: <Widget>[
                SettingsTextField(
                  label: deviceModeEnabled ? 'Device user name' : 'User name',
                  value: deviceModeEnabled ? deviceUserName : userName,
                  onChanged: deviceModeEnabled
                      ? onDeviceUserNameChanged
                      : onUserNameChanged,
                ),
                DropdownSetting<ExampleMarker>(
                  label: 'Marker',
                  value: deviceModeEnabled ? deviceMarker : userMarker,
                  values: ExampleMarker.values,
                  titleFor: (value) => value.label,
                  onChanged: deviceModeEnabled
                      ? onDeviceMarkerChanged
                      : onUserMarkerChanged,
                ),
                if (deviceModeEnabled)
                  Text(
                    'ID ${userIdentity?.userUuid ?? 'Not loaded'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  IdentitySummary(
                    identity: userIdentity,
                    onRegenerateUserKeyPair: onRegenerateUserKeyPair,
                  ),
              ],
            ),
            cardGap,
            InfoCard(
              title: deviceModeEnabled ? 'Device location' : 'Location',
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share location'),
                  subtitle: const Text('Include location in HaLow beacon'),
                  value:
                      deviceModeEnabled ? deviceShareLocation : shareLocation,
                  onChanged: deviceModeEnabled
                      ? onDeviceShareLocationChanged
                      : onShareLocationChanged,
                ),
                if (deviceModeEnabled && deviceShareLocation)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SettingsTextField(
                          label: 'Latitude',
                          value: deviceLatitude,
                          onChanged: onDeviceLatitudeChanged,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SettingsTextField(
                          label: 'Longitude',
                          value: deviceLongitude,
                          onChanged: onDeviceLongitudeChanged,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (deviceModeEnabled) ...<Widget>[
            cardGap,
            InfoCard(
              title: 'Device geofence',
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable geofence'),
                  subtitle: const Text('Include a geofence in device beacons'),
                  value: geoFenceEnabled,
                  onChanged: (enabled) => onDeviceGeoFenceNameChanged(
                    enabled ? 'Geo fence' : '',
                  ),
                ),
                SettingsTextField(
                  label: 'Geo fence',
                  value: deviceGeoFenceName,
                  onChanged: onDeviceGeoFenceNameChanged,
                ),
                StepperSetting(
                  label: 'Geo index',
                  value: deviceGeoIndex,
                  onChanged: onDeviceGeoIndexChanged,
                ),
              ],
            ),
            cardGap,
            InfoCard(
              title: 'Device sensors',
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable sensors'),
                  subtitle: const Text('Configure device sensor connectors'),
                  value: sensorsEnabled,
                  onChanged: (enabled) {
                    if (enabled) {
                      onUartI2cSensorChanged('sht3x_temperature_humidity');
                    } else {
                      onUartI2cSensorChanged('');
                      onRs485SensorChanged('');
                    }
                  },
                ),
                DropdownSetting<String>(
                  label: 'UART/I2C connector',
                  value: uartI2cSensorType,
                  values: const <String>[
                    '',
                    'sht3x_temperature_humidity',
                    'random_temperature_sample'
                  ],
                  titleFor: (value) => value.isEmpty ? 'None' : value,
                  onChanged: onUartI2cSensorChanged,
                  enabled: sensorsEnabled,
                ),
                DropdownSetting<String>(
                  label: 'RS485 connector',
                  value: rs485SensorType,
                  values: const <String>[
                    '',
                    'vibration_sensor_rs485',
                    'flow_meter_rs485'
                  ],
                  titleFor: (value) => value.isEmpty ? 'None' : value,
                  onChanged: onRs485SensorChanged,
                  enabled: sensorsEnabled,
                ),
              ],
            ),
          ],
          if (deviceModeEnabled ||
              selectedTab == _SettingsTab.meshNetwork) ...<Widget>[
            cardGap,
            InfoCard(
              title: deviceModeEnabled ? 'Network' : 'Mesh network',
              children: <Widget>[
                if (!deviceModeEnabled) ...<Widget>[
                  DropdownSetting<String>(
                    label: 'Country',
                    value: meshCountry,
                    values: const <String>['US', 'JP', 'EU'],
                    titleFor: (value) => value,
                    onChanged: onMeshCountryChanged,
                  ),
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
                    titleFor: (value) =>
                        halowFrequencyLabel(meshCountry, value),
                    onChanged: onMeshFrequencyChanged,
                  ),
                ],
                SettingsTextField(
                  label: 'Mesh ID / SSID',
                  value: deviceModeEnabled ? deviceMeshId : meshId,
                  onChanged: deviceModeEnabled
                      ? onDeviceMeshIdChanged
                      : onMeshIdChanged,
                ),
                SettingsTextField(
                  label: 'Passphrase',
                  value: deviceModeEnabled ? devicePassphrase : passphrase,
                  onChanged: deviceModeEnabled
                      ? onDevicePassphraseChanged
                      : onPassphraseChanged,
                  obscureText: true,
                ),
                SettingsTextField(
                  label: 'Max hop',
                  value: deviceModeEnabled ? deviceMaxHop : maxHop,
                  onChanged: deviceModeEnabled
                      ? onDeviceMaxHopChanged
                      : onMaxHopChanged,
                  keyboardType: TextInputType.number,
                ),
                SettingsTextField(
                  label: 'Beacon interval (seconds)',
                  value: deviceModeEnabled
                      ? deviceBeaconIntervalSeconds
                      : beaconIntervalSeconds,
                  onChanged: deviceModeEnabled
                      ? onDeviceBeaconIntervalChanged
                      : onBeaconIntervalChanged,
                  keyboardType: TextInputType.number,
                ),
                if (!deviceModeEnabled)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => unawaited(
                        Future<void>.value(onSaveAppSettings()),
                      ),
                      child: const Text('Save settings'),
                    ),
                  ),
              ],
            ),
          ],
          if (deviceModeEnabled) ...<Widget>[
            cardGap,
            InfoCard(
              title: 'Upstream network',
              children: <Widget>[
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
              ],
            ),
            cardGap,
            InfoCard(
              title: 'Sleep mode',
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable sleep mode'),
                  subtitle:
                      const Text('Allow the device to enter low-power sleep.'),
                  value: deviceSleepModeEnabled,
                  onChanged: onDeviceSleepModeChanged,
                ),
              ],
            ),
            cardGap,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    unawaited(Future<void>.value(onSaveDeviceSettings())),
                child: const Text('Save to device'),
              ),
            ),
          ],
          if (!deviceModeEnabled &&
              selectedTab == _SettingsTab.others) ...<Widget>[
            cardGap,
            InfoCard(
              title: 'Firmware update',
              children: <Widget>[
                Text(
                  'Current: ${meshStatus?.firmwareVersion.isNotEmpty == true ? meshStatus!.firmwareVersion : 'Unknown'}',
                ),
                if (otaAvailableVersion != null)
                  Text('Available: $otaAvailableVersion'),
                if (otaInProgress) ...<Widget>[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: otaProgress),
                ],
                if (otaMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(otaMessage,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: activeConnection == EdgezConnectionType.ble &&
                              !otaCheckInProgress &&
                              !otaInProgress
                          ? () => unawaited(
                                Future<void>.value(onCheckForOtaUpdate()),
                              )
                          : null,
                      child: Text(
                        otaCheckInProgress ? 'Checking...' : 'Check for update',
                      ),
                    ),
                    if (otaAvailableVersion != null && !otaInProgress)
                      FilledButton(
                        onPressed: activeConnection == EdgezConnectionType.ble
                            ? () => unawaited(
                                  Future<void>.value(onInstallOtaUpdate()),
                                )
                            : null,
                        child: const Text('Update'),
                      ),
                    if (otaInProgress)
                      TextButton(
                        onPressed: () => unawaited(
                          Future<void>.value(onAbortOta()),
                        ),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
            cardGap,
            InfoCard(
              title: 'Chat',
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto replay received voice'),
                  subtitle: const Text(
                      'Play new incoming voice messages automatically'),
                  value: autoReplayReceivedVoice,
                  onChanged: onAutoReplayChanged,
                ),
              ],
            ),
          ],
          cardGap,
        ],
      ),
    );
  }

  Widget _buildBleSelection(
    BuildContext context, {
    required EdgezBleDevice? selectedBleDevice,
    required VoidCallback onBack,
    required ValueChanged<EdgezBleDevice> onSelect,
  }) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Select BLE device',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(statusLine, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (bleDevices.isEmpty)
            const InfoCard(
              title: 'Scanning for EdgeZ devices',
              children: <Widget>[
                LinearProgressIndicator(),
                SizedBox(height: 8),
                Text('Nearby BLE devices will appear here.'),
              ],
            )
          else
            for (final device in bleDevices) ...<Widget>[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.label),
                  subtitle: Text('${device.id} · RSSI ${device.rssi}'),
                  trailing: selectedBleDevice?.id == device.id
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => onSelect(device),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _SettingsTab _selectedTab = _SettingsTab.user;
  bool _showBleSelection = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _SettingsTab.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showBleSelection) {
      return widget._buildBleSelection(
        context,
        selectedBleDevice: widget.selectedBleDevice,
        onBack: () {
          widget.onStopBleScan();
          setState(() => _showBleSelection = false);
        },
        onSelect: (device) {
          widget.onStopBleScan();
          widget.onSelectBleDevice(device);
          setState(() {
            _showBleSelection = false;
          });
        },
      );
    }
    return widget._buildContent(
      context,
      selectedTab: _selectedTab,
      tabController: _tabController,
      onTabChanged: (index) {
        setState(() => _selectedTab = _SettingsTab.values[index]);
      },
      onSelectBle: () {
        widget.onConnectBle();
        setState(() => _showBleSelection = true);
      },
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
    this.enabled = true,
    super.key,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) titleFor;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) =>
              DropdownMenuItem<T>(value: item, child: Text(titleFor(item))))
          .toList(),
      onChanged: enabled
          ? (next) {
              if (next != null) onChanged(next);
            }
          : null,
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
