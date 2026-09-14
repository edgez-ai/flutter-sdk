import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_locale.dart';
import 'models.dart';
import 'driver_catalog.dart';
import 'localized_model_labels.dart';
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
    required this.appLanguage,
    required this.onAppLanguageChanged,
    required this.activeConnection,
    required this.bleConnecting,
    required this.bleReady,
    required this.shareLocation,
    required this.autoReplayReceivedVoice,
    required this.defaultVoiceTargetLanguage,
    required this.voiceTargetLanguages,
    required this.deviceModeEnabled,
    required this.bleDevices,
    required this.wifiNetworks,
    required this.usbDevices,
    required this.drivers,
    required this.selectedBleDevice,
    required this.selectedUsbDevice,
    required this.usbLinkStats,
    required this.meshStatus,
    required this.bleAutoConnect,
    required this.statusLine,
    required this.otaUpdateAvailable,
    required this.otaReady,
    required this.otaCheckInProgress,
    required this.otaInProgress,
    required this.otaProgress,
    required this.otaMessage,
    required this.locationMessage,
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
    required this.deviceGpsEnabled,
    required this.deviceGpsLocation,
    required this.deviceLatitude,
    required this.deviceLongitude,
    required this.deviceGeoFenceName,
    required this.deviceGeoIndex,
    required this.uartI2cSensorType,
    required this.rs485SensorType,
    required this.deviceType,
    required this.devicePassphrase,
    required this.deviceSleepModeEnabled,
    required this.logLevel,
    required this.onConnectBle,
    required this.onConnectWifi,
    required this.onConnectWifiNetwork,
    required this.onRefreshWifiNetworks,
    required this.onStopBleScan,
    required this.onConnectBleDevice,
    required this.onSelectBleDevice,
    required this.onClearBleDevice,
    required this.onRefreshUsbDevices,
    required this.onConnectUsbDevice,
    required this.onBleAutoConnectChanged,
    required this.onDisconnect,
    required this.onOpenDebug,
    required this.onCheckForOtaUpdate,
    required this.onInstallOtaUpdate,
    required this.onSaveAppSettings,
    required this.onRegenerateUserKeyPair,
    required this.onSaveDeviceSettings,
    required this.onShareLocationChanged,
    required this.onAutoReplayChanged,
    required this.onDefaultVoiceTargetLanguageChanged,
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
    required this.onDeviceGpsEnabledChanged,
    required this.onRefreshDeviceLocation,
    required this.onDeviceLatitudeChanged,
    required this.onDeviceLongitudeChanged,
    required this.onDeviceGeoFenceNameChanged,
    required this.onDeviceGeoIndexChanged,
    required this.onUartI2cSensorChanged,
    required this.onRs485SensorChanged,
    required this.onDeviceTypeChanged,
    required this.onDevicePassphraseChanged,
    required this.onDeviceSleepModeChanged,
    required this.onLogLevelChanged,
    super.key,
  });

  final AppLanguage appLanguage;
  final ValueChanged<AppLanguage> onAppLanguageChanged;
  final EdgezConnectionType activeConnection;
  final bool bleConnecting;
  final bool bleReady;
  final bool shareLocation;
  final bool autoReplayReceivedVoice;
  final String defaultVoiceTargetLanguage;
  final List<String> voiceTargetLanguages;
  final bool deviceModeEnabled;
  final List<EdgezBleDevice> bleDevices;
  final List<EdgezWifiNetwork> wifiNetworks;
  final List<EdgezUsbDevice> usbDevices;
  final List<ExampleDriver> drivers;
  final EdgezBleDevice? selectedBleDevice;
  final EdgezUsbDevice? selectedUsbDevice;
  final EdgezUsbLinkStats usbLinkStats;
  final EdgezMeshStatus? meshStatus;
  final bool bleAutoConnect;
  final String statusLine;
  final bool otaUpdateAvailable;
  final bool otaReady;
  final bool otaCheckInProgress;
  final bool otaInProgress;
  final double otaProgress;
  final String otaMessage;
  final String locationMessage;
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
  final bool deviceGpsEnabled;
  final EdgezLocation? deviceGpsLocation;
  final String deviceLatitude;
  final String deviceLongitude;
  final String deviceGeoFenceName;
  final int deviceGeoIndex;
  final String uartI2cSensorType;
  final String rs485SensorType;
  final String deviceType;
  final String devicePassphrase;
  final bool deviceSleepModeEnabled;
  final EdgezDeviceLogLevel logLevel;
  final VoidCallback onConnectBle;
  final FutureOr<void> Function() onConnectWifi;
  final ValueChanged<EdgezWifiNetwork> onConnectWifiNetwork;
  final Future<void> Function() onRefreshWifiNetworks;
  final VoidCallback onStopBleScan;
  final ValueChanged<String> onConnectBleDevice;
  final ValueChanged<EdgezBleDevice> onSelectBleDevice;
  final VoidCallback onClearBleDevice;
  final Future<void> Function() onRefreshUsbDevices;
  final ValueChanged<EdgezUsbDevice> onConnectUsbDevice;
  final ValueChanged<bool> onBleAutoConnectChanged;
  final VoidCallback onDisconnect;
  final VoidCallback onOpenDebug;
  final FutureOr<void> Function() onCheckForOtaUpdate;
  final FutureOr<void> Function() onInstallOtaUpdate;
  final FutureOr<void> Function() onSaveAppSettings;
  final FutureOr<void> Function() onRegenerateUserKeyPair;
  final FutureOr<void> Function() onSaveDeviceSettings;
  final ValueChanged<bool> onShareLocationChanged;
  final ValueChanged<bool> onAutoReplayChanged;
  final ValueChanged<String> onDefaultVoiceTargetLanguageChanged;
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
  final ValueChanged<bool> onDeviceGpsEnabledChanged;
  final FutureOr<void> Function() onRefreshDeviceLocation;
  final ValueChanged<String> onDeviceLatitudeChanged;
  final ValueChanged<String> onDeviceLongitudeChanged;
  final ValueChanged<String> onDeviceGeoFenceNameChanged;
  final ValueChanged<int> onDeviceGeoIndexChanged;
  final ValueChanged<String> onUartI2cSensorChanged;
  final ValueChanged<String> onRs485SensorChanged;
  final ValueChanged<String> onDeviceTypeChanged;
  final ValueChanged<String> onDevicePassphraseChanged;
  final ValueChanged<bool> onDeviceSleepModeChanged;
  final ValueChanged<EdgezDeviceLogLevel> onLogLevelChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  Widget _buildContent(
    BuildContext context, {
    required _SettingsTab selectedTab,
    required TabController tabController,
    required ValueChanged<int> onTabChanged,
    required VoidCallback onSelectBle,
  }) {
    final l10n = AppLocalizations.of(context);
    const cardGap = SizedBox(height: 12);
    final sensorsEnabled =
        uartI2cSensorType.isNotEmpty || rs485SensorType.isNotEmpty;
    final geoFenceEnabled = deviceGeoFenceName.trim().isNotEmpty;
    final selectedBle = selectedBleDevice;
    final uartDrivers = drivers
        .where((driver) => driver.connector == EdgezSensorConnector.uartI2c)
        .toList(growable: false);
    final rs485Drivers = drivers
        .where((driver) => driver.connector == EdgezSensorConnector.rs485)
        .toList(growable: false);
    final uartDriverKeys = <String>[
      '',
      ...uartDrivers.map((driver) => driver.key),
      if (uartI2cSensorType.isNotEmpty &&
          !uartDrivers.any((driver) => driver.key == uartI2cSensorType))
        uartI2cSensorType,
    ];
    final rs485DriverKeys = <String>[
      '',
      ...rs485Drivers.map((driver) => driver.key),
      if (rs485SensorType.isNotEmpty &&
          !rs485Drivers.any((driver) => driver.key == rs485SensorType))
        rs485SensorType,
    ];
    String driverLabel(List<ExampleDriver> available, String key) {
      if (key.isEmpty) return l10n.none;
      return available
              .where((driver) => driver.key == key)
              .map((driver) => driver.label)
              .firstOrNull ??
          key;
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.settings,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenDebug,
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(l10n.debug),
              ),
            ],
          ),
          if (statusLine.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(statusLine, style: Theme.of(context).textTheme.bodySmall),
          ],
          cardGap,
          InfoCard(
            title: l10n.deviceConnection,
            action: OutlinedButton(
              onPressed: onSelectBle,
              child: Text(l10n.select),
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
                          l10n.selectedDevice,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(switch (activeConnection) {
                          EdgezConnectionType.wifi => 'EdgeZ Wi-Fi SoftAP',
                          EdgezConnectionType.usb =>
                            selectedUsbDevice?.label ?? 'ESP32-S3 USB',
                          EdgezConnectionType.ble =>
                            selectedBle?.label ?? l10n.noDeviceSelected,
                          EdgezConnectionType.none =>
                            selectedUsbDevice?.label ??
                                selectedBle?.label ??
                                'EdgeZ Wi-Fi SoftAP',
                        }),
                        if (activeConnection != EdgezConnectionType.usb &&
                            selectedBle != null)
                          Text(
                            selectedBle.id,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          switch (activeConnection) {
                            EdgezConnectionType.wifi =>
                              'Wi-Fi connected; control channel ready',
                            EdgezConnectionType.usb => l10n.usbConnected,
                            EdgezConnectionType.ble => bleReady
                                ? l10n.bleControlReady
                                : l10n.bleSettingUp,
                            EdgezConnectionType.none => bleConnecting
                                ? l10n.blePairing
                                : l10n.disconnected,
                          },
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (activeConnection != EdgezConnectionType.none &&
                            meshStatus?.firmwareVersion.isNotEmpty == true)
                          Text(
                            l10n.firmwareVersion(meshStatus!.firmwareVersion),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (activeConnection == EdgezConnectionType.usb)
                          Text(
                            usbLinkStats.bidirectional
                                ? 'USB ping/pong OK · RTT ${usbLinkStats.rttMs} ms · '
                                    'phone→device ${usbLinkStats.receivedPongs}/${usbLinkStats.sentPings} · '
                                    'device→phone ${usbLinkStats.receivedPings}'
                                : 'Testing USB in both directions… sent ${usbLinkStats.sentPings}, '
                                    'pongs ${usbLinkStats.receivedPongs}, '
                                    'device pings ${usbLinkStats.receivedPings}, '
                                    'timeouts ${usbLinkStats.timeouts}',
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
                                'License: ${meshStatus?.licenseStatus.label ?? switch ((
                                      activeConnection,
                                      bleConnecting,
                                      bleReady
                                    )) {
                                      (_, true, _) => l10n.waitingBle,
                                      (EdgezConnectionType.none, false, _) =>
                                        'Connect over Wi-Fi, BLE, or USB',
                                      (EdgezConnectionType.wifi, false, _) =>
                                        l10n.waitingDeviceStatus,
                                      (EdgezConnectionType.ble, false, false) =>
                                        l10n.waitingBleControl,
                                      (EdgezConnectionType.ble, false, true) =>
                                        l10n.waitingDeviceStatus,
                                      (EdgezConnectionType.usb, false, _) =>
                                        l10n.waitingDeviceStatus,
                                    }}',
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
                    onPressed: bleConnecting
                        ? null
                        : activeConnection != EdgezConnectionType.none
                            ? onDisconnect
                            : selectedUsbDevice != null
                                ? () => onConnectUsbDevice(selectedUsbDevice!)
                                : selectedBle != null
                                    ? () => onConnectBleDevice(selectedBle.id)
                                    : () => unawaited(
                                          Future<void>.value(onConnectWifi()),
                                        ),
                    child: Text(
                      bleConnecting
                          ? l10n.connecting
                          : activeConnection != EdgezConnectionType.none
                              ? l10n.disconnect
                              : l10n.connect,
                    ),
                  ),
                ],
              ),
              if (activeConnection == EdgezConnectionType.ble) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed:
                          meshStatus?.firmwareVersion.isNotEmpty == true &&
                                  !otaCheckInProgress &&
                                  !otaInProgress
                              ? () => unawaited(
                                    Future<void>.value(
                                      onCheckForOtaUpdate(),
                                    ),
                                  )
                              : null,
                      child: Text(
                        otaCheckInProgress
                            ? l10n.checking
                            : l10n.checkForUpdate,
                      ),
                    ),
                    if (otaUpdateAvailable)
                      FilledButton(
                        onPressed: !otaInProgress && otaReady
                            ? () => unawaited(
                                  Future<void>.value(onInstallOtaUpdate()),
                                )
                            : null,
                        child: Text(
                          otaInProgress
                              ? l10n
                                  .updatingProgress((otaProgress * 100).floor())
                              : l10n.update,
                        ),
                      ),
                  ],
                ),
                if (otaMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    otaMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (otaUpdateAvailable && !otaReady) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    l10n.otaUnsupported,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.autoConnect),
                subtitle: Text(l10n.autoConnectDescription),
                value: bleAutoConnect,
                onChanged: onBleAutoConnectChanged,
              ),
            ],
          ),
          cardGap,
          TabBar(
            controller: tabController,
            onTap: onTabChanged,
            tabs: <Widget>[
              Tab(text: l10n.user),
              Tab(text: l10n.meshNetwork),
              Tab(text: l10n.others),
            ],
          ),
          if (selectedTab == _SettingsTab.user) ...<Widget>[
            cardGap,
            InfoCard(
              title: deviceModeEnabled ? l10n.deviceUser : l10n.user,
              children: <Widget>[
                SettingsTextField(
                  label:
                      deviceModeEnabled ? l10n.deviceUserName : l10n.userName,
                  value: deviceModeEnabled ? deviceUserName : userName,
                  onChanged: deviceModeEnabled
                      ? onDeviceUserNameChanged
                      : onUserNameChanged,
                ),
                DropdownSetting<ExampleMarker>(
                  label: l10n.marker,
                  value: deviceModeEnabled ? deviceMarker : userMarker,
                  values: ExampleMarker.values,
                  titleFor: (value) => value.localizedLabel(l10n),
                  onChanged: deviceModeEnabled
                      ? onDeviceMarkerChanged
                      : onUserMarkerChanged,
                ),
                if (deviceModeEnabled)
                  Text(
                    l10n.identifier(userIdentity?.userUuid ?? l10n.notLoaded),
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
              title: deviceModeEnabled ? l10n.deviceLocation : l10n.location,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.shareLocation),
                  subtitle: Text(l10n.shareLocationDescription),
                  value:
                      deviceModeEnabled ? deviceShareLocation : shareLocation,
                  onChanged: deviceModeEnabled
                      ? onDeviceShareLocationChanged
                      : onShareLocationChanged,
                ),
                if (deviceModeEnabled ? deviceShareLocation : shareLocation)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.useDeviceGps),
                    subtitle: Text(l10n.deviceGpsDescription),
                    value: deviceGpsEnabled,
                    onChanged: onDeviceGpsEnabledChanged,
                  ),
                if (deviceGpsEnabled && deviceGpsLocation != null)
                  Text(
                    l10n.deviceFix(
                      deviceGpsLocation!.latitude.toStringAsFixed(6),
                      deviceGpsLocation!.longitude.toStringAsFixed(6),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (locationMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    locationMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (deviceModeEnabled &&
                    deviceShareLocation &&
                    !deviceGpsEnabled) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SettingsTextField(
                          label: l10n.latitude,
                          value: deviceLatitude,
                          onChanged: onDeviceLatitudeChanged,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SettingsTextField(
                          label: l10n.longitude,
                          value: deviceLongitude,
                          onChanged: onDeviceLongitudeChanged,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(
                      Future<void>.value(onRefreshDeviceLocation()),
                    ),
                    icon: const Icon(Icons.my_location),
                    label: Text(l10n.refreshPhoneLocation),
                  ),
                ],
              ],
            ),
          ],
          if (deviceModeEnabled) ...<Widget>[
            cardGap,
            InfoCard(
              title: l10n.geoFence,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.enableGeoFence),
                  subtitle: Text(l10n.geofenceBeaconDescription),
                  value: geoFenceEnabled,
                  onChanged: (enabled) => onDeviceGeoFenceNameChanged(
                    enabled ? 'Geo fence' : '',
                  ),
                ),
                SettingsTextField(
                  label: l10n.geoFence,
                  value: deviceGeoFenceName,
                  onChanged: onDeviceGeoFenceNameChanged,
                ),
                StepperSetting(
                  label: l10n.geoIndex,
                  value: deviceGeoIndex,
                  onChanged: onDeviceGeoIndexChanged,
                ),
              ],
            ),
            cardGap,
            InfoCard(
              title: l10n.sensorDrivers,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.enableSensors),
                  subtitle: Text(l10n.sensorConnectorDescription),
                  value: sensorsEnabled,
                  onChanged: (enabled) {
                    if (enabled) {
                      if (uartDrivers.isNotEmpty) {
                        onUartI2cSensorChanged(uartDrivers.first.key);
                      } else if (rs485Drivers.isNotEmpty) {
                        onRs485SensorChanged(rs485Drivers.first.key);
                      }
                    } else {
                      onUartI2cSensorChanged('');
                      onRs485SensorChanged('');
                    }
                  },
                ),
                DropdownSetting<String>(
                  label: l10n.uartConnector,
                  value: uartI2cSensorType,
                  values: uartDriverKeys,
                  titleFor: (value) => driverLabel(uartDrivers, value),
                  onChanged: onUartI2cSensorChanged,
                  enabled: sensorsEnabled,
                ),
                DropdownSetting<String>(
                  label: l10n.rs485Connector,
                  value: rs485SensorType,
                  values: rs485DriverKeys,
                  titleFor: (value) => driverLabel(rs485Drivers, value),
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
              title: l10n.meshNetwork,
              children: <Widget>[
                if (!deviceModeEnabled) ...<Widget>[
                  DropdownSetting<String>(
                    label: l10n.country,
                    value: meshCountry,
                    values: const <String>['US', 'JP', 'EU'],
                    titleFor: (value) => value,
                    onChanged: onMeshCountryChanged,
                  ),
                  DropdownSetting<int>(
                    label: l10n.bandwidth,
                    value: meshBandwidthMhz,
                    values: halowBandwidthOptions(meshCountry),
                    titleFor: (value) => '$value MHz',
                    onChanged: onMeshBandwidthChanged,
                  ),
                ],
                DropdownSetting<int>(
                  label: l10n.channel,
                  value: meshFrequencyKhz,
                  values: halowFrequenciesKhz(
                    meshCountry,
                    meshBandwidthMhz,
                  ),
                  titleFor: (value) => halowFrequencyLabel(meshCountry, value),
                  onChanged: onMeshFrequencyChanged,
                ),
                SettingsTextField(
                  label: l10n.meshId,
                  value: deviceModeEnabled ? deviceMeshId : meshId,
                  onChanged: deviceModeEnabled
                      ? onDeviceMeshIdChanged
                      : onMeshIdChanged,
                ),
                SettingsTextField(
                  label: l10n.passphrase,
                  value: deviceModeEnabled ? devicePassphrase : passphrase,
                  onChanged: deviceModeEnabled
                      ? onDevicePassphraseChanged
                      : onPassphraseChanged,
                  obscureText: true,
                ),
                SettingsTextField(
                  label: l10n.maxHop,
                  value: deviceModeEnabled ? deviceMaxHop : maxHop,
                  onChanged: deviceModeEnabled
                      ? onDeviceMaxHopChanged
                      : onMaxHopChanged,
                  keyboardType: TextInputType.number,
                ),
                SettingsTextField(
                  label: l10n.beaconInterval,
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
                      child: Text(l10n.saveSettings),
                    ),
                  ),
              ],
            ),
          ],
          if (deviceModeEnabled) ...<Widget>[
            cardGap,
            InfoCard(
              title: l10n.sleepMode,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.enableSleepMode),
                  subtitle: Text(l10n.sleepModeDescription),
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
                child: Text(l10n.save),
              ),
            ),
          ],
          if (!deviceModeEnabled &&
              selectedTab == _SettingsTab.others) ...<Widget>[
            cardGap,
            InfoCard(
              title: l10n.language,
              children: <Widget>[
                DropdownButtonFormField<AppLanguage>(
                  key: ValueKey(appLanguage),
                  initialValue: appLanguage,
                  decoration: InputDecoration(
                    labelText: l10n.language,
                    helperText: l10n.languageDescription,
                  ),
                  items: AppLanguage.values
                      .map(
                        (language) => DropdownMenuItem<AppLanguage>(
                          value: language,
                          child: Text(language.nativeName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (language) {
                    if (language != null) onAppLanguageChanged(language);
                  },
                ),
              ],
            ),
            cardGap,
            InfoCard(
              title: l10n.logging,
              children: <Widget>[
                DropdownButtonFormField<EdgezDeviceLogLevel>(
                  initialValue: logLevel,
                  decoration: InputDecoration(
                    labelText: l10n.logLevel,
                    helperText: l10n.loggingHelper,
                  ),
                  items: EdgezDeviceLogLevel.values
                      .map(
                        (level) => DropdownMenuItem<EdgezDeviceLogLevel>(
                          value: level,
                          child: Text(level.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (level) {
                    if (level != null) onLogLevelChanged(level);
                  },
                ),
              ],
            ),
            cardGap,
            InfoCard(
              title: l10n.chat,
              children: <Widget>[
                DropdownSetting<String>(
                  label: l10n.defaultTranslationLanguage,
                  value: defaultVoiceTargetLanguage,
                  values: voiceTargetLanguages,
                  titleFor: (value) => value,
                  onChanged: onDefaultVoiceTargetLanguageChanged,
                ),
                const SizedBox(height: 8),
                Text(l10n.translationLanguageDescription),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.autoReplayVoice),
                  subtitle: Text(l10n.autoReplayVoiceDescription),
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

  Widget _buildDeviceSelection(
    BuildContext context, {
    required EdgezBleDevice? selectedBleDevice,
    required VoidCallback onBack,
    required ValueChanged<EdgezBleDevice> onSelectBle,
    required ValueChanged<EdgezUsbDevice> onSelectUsb,
    required Future<void> Function() onRefreshUsb,
    required ValueChanged<EdgezWifiNetwork> onConnectWifi,
    required Future<void> Function() onRefreshWifi,
  }) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onBack,
                tooltip: AppLocalizations.of(context).back,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Select connection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(statusLine, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Wi-Fi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => unawaited(onRefreshWifi()),
                tooltip: 'Refresh Wi-Fi networks',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (wifiNetworks.isEmpty)
            const Text('No EZ-* Wi-Fi networks found')
          else
            for (final network in wifiNetworks) ...<Widget>[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.wifi),
                  title: Text(network.ssid),
                  subtitle: Text('RSSI ${network.rssi}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => onConnectWifi(network),
                ),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'USB',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => unawaited(onRefreshUsb()),
                tooltip: AppLocalizations.of(context).refreshUsb,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (usbDevices.isEmpty)
            Text(AppLocalizations.of(context).noUsbDevices)
          else ...<Widget>[
            for (final device in usbDevices) ...<Widget>[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.usb),
                  title: Text(device.label),
                  subtitle: Text(
                    device.transport == 'tinyusb-cdc-uart'
                        ? 'TinyUSB CDC · mobile ping/pong on data port 0'
                        : 'High-speed wired transport',
                  ),
                  trailing: selectedUsbDevice?.id == device.id
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => onSelectUsb(device),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(AppLocalizations.of(context).bluetooth,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: selectedBleDevice == null ? null : onClearBleDevice,
                icon: const Icon(Icons.clear),
                label: Text(AppLocalizations.of(context).clearBleSelection),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (bleDevices.isEmpty)
            InfoCard(
              title: AppLocalizations.of(context).scanningDevices,
              children: <Widget>[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context).nearbyDevices),
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
                  onTap: () => onSelectBle(device),
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
  bool _showDeviceSelection = false;

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
    if (_showDeviceSelection) {
      return widget._buildDeviceSelection(
        context,
        selectedBleDevice: widget.selectedBleDevice,
        onBack: () {
          widget.onStopBleScan();
          setState(() => _showDeviceSelection = false);
        },
        onSelectBle: (device) {
          widget.onStopBleScan();
          widget.onSelectBleDevice(device);
          setState(() {
            _showDeviceSelection = false;
          });
        },
        onSelectUsb: (device) {
          widget.onStopBleScan();
          widget.onConnectUsbDevice(device);
          setState(() => _showDeviceSelection = false);
        },
        onRefreshUsb: widget.onRefreshUsbDevices,
        onRefreshWifi: widget.onRefreshWifiNetworks,
        onConnectWifi: (network) {
          widget.onStopBleScan();
          widget.onConnectWifiNetwork(network);
          setState(() => _showDeviceSelection = false);
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
        widget.onRefreshUsbDevices();
        widget.onRefreshWifiNetworks();
        setState(() => _showDeviceSelection = true);
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
          ? <Widget>[
              Text(AppLocalizations.of(context).userIdentity),
              Text(AppLocalizations.of(context).loadingIdentity),
            ]
          : <Widget>[
              Text(AppLocalizations.of(context).userIdentity,
                  style: Theme.of(context).textTheme.titleMedium),
              Text('UUID ${current.userUuid}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(AppLocalizations.of(context).publicKey,
                  style: Theme.of(context).textTheme.titleSmall),
              SelectableText(edgezFormatHex(current.publicKey),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(AppLocalizations.of(context).privateKey,
                  style: Theme.of(context).textTheme.titleSmall),
              SelectableText(edgezFormatHex(current.privateKey),
                  style: Theme.of(context).textTheme.bodySmall),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () =>
                      unawaited(Future<void>.value(onRegenerateUserKeyPair())),
                  child: Text(AppLocalizations.of(context).regenerateKeyPair),
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
