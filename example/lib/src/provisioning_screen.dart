import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'driver_catalog.dart';
import 'models.dart';
import 'settings_tab.dart';
import 'shared_widgets.dart';

enum _ProvisionStep {
  selectBle('Select BLE device'),
  mode('Device mode'),
  deviceUser('Device user'),
  network('Network'),
  location('Location'),
  geoFence('Geo fence'),
  sensor('Sensor'),
  sleepMode('Sleep mode');

  const _ProvisionStep(this.title);
  final String title;
}

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({
    required this.session,
    required this.drivers,
    required this.onCancel,
    required this.onComplete,
    super.key,
  });

  final EdgezMeshSession session;
  final List<ExampleDriver> drivers;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  _ProvisionStep step = _ProvisionStep.selectBle;
  EdgezBleDevice? selectedBle;
  late EdgezUserIdentity deviceIdentity;
  bool waitingForSettings = false;
  bool requestedSettings = false;
  bool saving = false;
  String? error;

  String deviceType = '';
  String userName = 'EdgeZ Device';
  ExampleMarker marker = ExampleMarker.green;
  String meshId = 'edgez';
  String passphrase = '';
  String maxHop = '4';
  String beaconInterval = '30';
  bool shareLocation = false;
  String latitude = '';
  String longitude = '';
  String geoFenceName = '';
  int geoIndex = 0;
  String uartI2cDriver = '';
  String rs485Driver = '';
  bool upstreamEnabled = false;
  String upstreamSsid = '';
  String upstreamPassphrase = '';
  String beaconMulticast = '';
  bool sleepMode = false;

  @override
  void initState() {
    super.initState();
    deviceIdentity = EdgezIdentityStore().createIdentity(name: userName);
    widget.session.addListener(_sessionChanged);
    unawaited(widget.session.startBleScan());
  }

  @override
  void dispose() {
    widget.session.removeListener(_sessionChanged);
    if (step == _ProvisionStep.selectBle) {
      unawaited(widget.session.stopBleScan());
    }
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted || !waitingForSettings) return;
    final state = widget.session.state;
    if (state.bleReady && !requestedSettings) {
      requestedSettings = true;
      unawaited(widget.session.requestDeviceSettings());
    }
    final settings = state.deviceSettings;
    if (requestedSettings && settings != null) {
      _applySettings(settings);
      setState(() {
        waitingForSettings = false;
        step = _ProvisionStep.mode;
      });
    } else {
      setState(() {});
    }
  }

  void _applySettings(EdgezDeviceSettings settings) {
    deviceType = switch (settings.deviceType) {
      'beacon' => 'beacon',
      'sensor' => 'sensor',
      'relay' => 'relay',
      _ => '',
    };
    userName = settings.userName.isEmpty ? userName : settings.userName;
    marker = ExampleMarker.fromId(settings.marker);
    meshId = settings.meshId.isEmpty ? meshId : settings.meshId;
    passphrase = settings.passphrase;
    maxHop = settings.maxHop.toString();
    beaconInterval = settings.beaconIntervalSeconds.toString();
    shareLocation = settings.shareLocation;
    latitude = settings.latitude?.toString() ?? '';
    longitude = settings.longitude?.toString() ?? '';
    geoFenceName = settings.geoFenceName;
    geoIndex = settings.geoIndex;
    uartI2cDriver = settings.uartI2cSensorType;
    rs485Driver = settings.rs485SensorType;
    upstreamSsid = settings.upstreamWifiSsid;
    upstreamPassphrase = settings.upstreamWifiPassphrase;
    beaconMulticast = _formatIpv4(settings.beaconUnicast);
    upstreamEnabled = upstreamSsid.isNotEmpty ||
        upstreamPassphrase.isNotEmpty ||
        beaconMulticast.isNotEmpty;
    sleepMode = settings.sleepModeEnabled;
    if (settings.userPrivateKey.length == 32 &&
        (settings.userIdHigh != 0 || settings.userIdLow != 0)) {
      deviceIdentity = EdgezUserIdentity(
        userUuid: _uuid(settings.userIdHigh, settings.userIdLow),
        userIdHigh: settings.userIdHigh,
        userIdLow: settings.userIdLow,
        name: userName,
        privateKey: settings.userPrivateKey,
        publicKey: settings.userPublicKey,
      );
    }
  }

  Future<void> _connectAndLoad() async {
    final device = selectedBle;
    if (device == null) return;
    setState(() {
      waitingForSettings = true;
      requestedSettings = false;
      error = null;
    });
    await widget.session.stopBleScan();
    await widget.session.connectBle(device.id);
    _sessionChanged();
  }

  void _back() {
    if (step == _ProvisionStep.selectBle) {
      _cancel();
      return;
    }
    setState(() {
      step = _ProvisionStep.values[step.index - 1];
      error = null;
    });
  }

  Future<void> _next() async {
    if (step == _ProvisionStep.selectBle) {
      await _connectAndLoad();
      return;
    }
    if (step == _ProvisionStep.mode && deviceType.isEmpty) {
      setState(() => error = 'Select Beacon, Sensor, or Relay mode');
      return;
    }
    if (step == _ProvisionStep.sensor && deviceType == 'relay' ||
        step == _ProvisionStep.sleepMode) {
      await _save();
      return;
    }
    setState(() {
      step = _ProvisionStep.values[step.index + 1];
      error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final scripts = <EdgezSensorScriptConfig>[];
      for (final key in <String>[uartI2cDriver, rs485Driver]) {
        if (key.isEmpty) continue;
        final driver = widget.drivers.firstWhere((item) => item.key == key);
        scripts.add(await driver.loadScript());
      }
      final currentIdentity = deviceIdentity.copyWith(name: userName);
      await widget.session.sendDeviceSettings(
        EdgezDeviceSettings(
          deviceModeEnabled: deviceType != 'relay',
          deviceType: deviceType,
          meshId: meshId.trim(),
          passphrase: passphrase,
          userName: userName.trim(),
          marker: marker.name,
          maxHop: int.tryParse(maxHop) ?? 4,
          beaconIntervalSeconds: int.tryParse(beaconInterval) ?? 30,
          shareLocation: shareLocation,
          latitude: shareLocation ? double.tryParse(latitude) : null,
          longitude: shareLocation ? double.tryParse(longitude) : null,
          geoFenceName: geoFenceName.trim(),
          geoIndex: geoIndex,
          uartI2cSensorType: uartI2cDriver,
          rs485SensorType: rs485Driver,
          upstreamWifiSsid: upstreamEnabled ? upstreamSsid.trim() : '',
          upstreamWifiPassphrase: upstreamEnabled ? upstreamPassphrase : '',
          beaconUnicast: upstreamEnabled ? _parseIpv4(beaconMulticast) : 0,
          sleepModeEnabled: deviceType == 'relay' ? false : sleepMode,
        ),
        identity: currentIdentity,
        scripts: scripts,
      );
      await widget.session.disconnect();
      if (mounted) widget.onComplete();
    } catch (exception) {
      if (mounted) setState(() => error = 'Provisioning failed: $exception');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _cancel() async {
    await widget.session.stopBleScan();
    if (widget.session.state.connection != EdgezConnectionType.none) {
      await widget.session.disconnect();
    }
    if (mounted) widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.session.state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provisioning'),
        leading: TextButton(onPressed: _back, child: const Text('Back')),
        leadingWidth: 72,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('Step ${step.index + 1} of 8: ${step.title}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Interface: ${state.connection.name.toUpperCase()}'),
            Text(state.statusLine,
                style: Theme.of(context).textTheme.bodySmall),
            if (state.status?.licenseStatus ==
                EdgezLicenseStatus.deviceNotLicensed)
              Text('Device is not licensed. Provisioning is unavailable.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            _stepContent(state),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : _cancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _canContinue(state) ? _next : null,
                  child: Text(saving
                      ? 'Saving'
                      : step == _ProvisionStep.sleepMode ||
                              step == _ProvisionStep.sensor &&
                                  deviceType == 'relay'
                          ? 'Save'
                          : waitingForSettings
                              ? 'Loading'
                              : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canContinue(EdgezMeshState state) {
    if (saving || waitingForSettings) return false;
    if (state.status?.licenseStatus == EdgezLicenseStatus.deviceNotLicensed) {
      return false;
    }
    return step != _ProvisionStep.selectBle || selectedBle != null;
  }

  Widget _stepContent(EdgezMeshState state) {
    switch (step) {
      case _ProvisionStep.selectBle:
        return InfoCard(
          title: 'Select BLE device',
          action: IconButton(
            tooltip: 'Scan again',
            onPressed: widget.session.startBleScan,
            icon: const Icon(Icons.refresh),
          ),
          children: <Widget>[
            if (state.sortedBleDevices.isEmpty)
              const Text('Scanning for EdgeZ devices...'),
            for (final device in state.sortedBleDevices)
              ListTile(
                selected: selectedBle?.id == device.id,
                leading: Icon(selectedBle?.id == device.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(device.label),
                subtitle: Text('${device.id} · RSSI ${device.rssi}'),
                onTap: () => setState(() => selectedBle = device),
              ),
          ],
        );
      case _ProvisionStep.mode:
        return InfoCard(
          title: 'Device mode',
          children: <Widget>[
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment(value: 'beacon', label: Text('Beacon')),
                ButtonSegment(value: 'sensor', label: Text('Sensor')),
                ButtonSegment(value: 'relay', label: Text('Relay')),
              ],
              emptySelectionAllowed: true,
              selected: deviceType.isEmpty ? const {} : {deviceType},
              onSelectionChanged: (value) =>
                  setState(() => deviceType = value.first),
            ),
            const SizedBox(height: 8),
            Text(switch (deviceType) {
              'beacon' => 'Advertises a device profile and location.',
              'sensor' => 'Advertises a device profile and sensor readings.',
              'relay' => 'Extends mesh coverage without a device profile.',
              _ => 'Choose how this EdgeZ device will operate.',
            }),
          ],
        );
      case _ProvisionStep.deviceUser:
        return InfoCard(
          title: 'Device user',
          children: <Widget>[
            SettingsTextField(
              label: 'Device user name',
              value: userName,
              onChanged: (value) => setState(() => userName = value),
            ),
            DropdownSetting<ExampleMarker>(
              label: 'Marker',
              value: marker,
              values: ExampleMarker.values,
              titleFor: (value) => value.label,
              onChanged: (value) => setState(() => marker = value),
            ),
            const SizedBox(height: 8),
            Text('ID ${deviceIdentity.userUuid}',
                style: Theme.of(context).textTheme.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  deviceIdentity =
                      EdgezIdentityStore().createIdentity(name: userName);
                }),
                child: const Text('Regenerate device ID'),
              ),
            ),
          ],
        );
      case _ProvisionStep.network:
        return Column(
          children: <Widget>[
            InfoCard(
              title: 'HaLow network',
              children: <Widget>[
                SettingsTextField(
                    label: 'Mesh ID / SSID',
                    value: meshId,
                    onChanged: (value) => setState(() => meshId = value)),
                SettingsTextField(
                    label: 'Passphrase',
                    value: passphrase,
                    obscureText: true,
                    onChanged: (value) => setState(() => passphrase = value)),
                SettingsTextField(
                    label: 'Max hop',
                    value: maxHop,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => maxHop = value)),
                SettingsTextField(
                    label: 'Beacon interval (seconds)',
                    value: beaconInterval,
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        setState(() => beaconInterval = value)),
              ],
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: 'Upstream network',
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable upstream network'),
                  value: upstreamEnabled,
                  onChanged: (value) => setState(() => upstreamEnabled = value),
                ),
                if (upstreamEnabled) ...<Widget>[
                  SettingsTextField(
                      label: 'Upstream Wi-Fi SSID',
                      value: upstreamSsid,
                      onChanged: (value) =>
                          setState(() => upstreamSsid = value)),
                  SettingsTextField(
                      label: 'Upstream Wi-Fi passphrase',
                      value: upstreamPassphrase,
                      obscureText: true,
                      onChanged: (value) =>
                          setState(() => upstreamPassphrase = value)),
                  SettingsTextField(
                      label: 'Beacon multicast',
                      value: beaconMulticast,
                      onChanged: (value) =>
                          setState(() => beaconMulticast = value)),
                ],
              ],
            ),
          ],
        );
      case _ProvisionStep.location:
        return InfoCard(
          title: 'Device location',
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share location'),
              value: shareLocation,
              onChanged: (value) => setState(() => shareLocation = value),
            ),
            if (shareLocation) ...<Widget>[
              SettingsTextField(
                  label: 'Latitude',
                  value: latitude,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => latitude = value)),
              SettingsTextField(
                  label: 'Longitude',
                  value: longitude,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => longitude = value)),
              OutlinedButton.icon(
                onPressed: _refreshLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use phone location'),
              ),
            ],
          ],
        );
      case _ProvisionStep.geoFence:
        return InfoCard(
          title: 'Geo fence',
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable geo fence'),
              value: geoFenceName.isNotEmpty,
              onChanged: (value) =>
                  setState(() => geoFenceName = value ? 'Geo fence' : ''),
            ),
            if (geoFenceName.isNotEmpty) ...<Widget>[
              SettingsTextField(
                  label: 'Geo fence name',
                  value: geoFenceName,
                  onChanged: (value) => setState(() => geoFenceName = value)),
              StepperSetting(
                  label: 'Geo index',
                  value: geoIndex,
                  onChanged: (value) => setState(() => geoIndex = value)),
            ],
          ],
        );
      case _ProvisionStep.sensor:
        final uart = widget.drivers
            .where((item) => item.connector == EdgezSensorConnector.uartI2c)
            .toList(growable: false);
        final rs485 = widget.drivers
            .where((item) => item.connector == EdgezSensorConnector.rs485)
            .toList(growable: false);
        return InfoCard(
          title: 'Sensor drivers',
          children: <Widget>[
            DropdownSetting<String>(
              label: 'UART / I2C connector',
              value: uart.any((item) => item.key == uartI2cDriver)
                  ? uartI2cDriver
                  : '',
              values: <String>['', ...uart.map((item) => item.key)],
              titleFor: (key) => key.isEmpty
                  ? 'None'
                  : uart.firstWhere((item) => item.key == key).label,
              onChanged: (value) => setState(() => uartI2cDriver = value),
            ),
            DropdownSetting<String>(
              label: 'RS485 connector',
              value: rs485.any((item) => item.key == rs485Driver)
                  ? rs485Driver
                  : '',
              values: <String>['', ...rs485.map((item) => item.key)],
              titleFor: (key) => key.isEmpty
                  ? 'None'
                  : rs485.firstWhere((item) => item.key == key).label,
              onChanged: (value) => setState(() => rs485Driver = value),
            ),
          ],
        );
      case _ProvisionStep.sleepMode:
        return InfoCard(
          title: 'Sleep mode',
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable sleep mode'),
              subtitle:
                  const Text('Allow the device to enter low-power sleep.'),
              value: sleepMode,
              onChanged: (value) => setState(() => sleepMode = value),
            ),
          ],
        );
    }
  }

  Future<void> _refreshLocation() async {
    final location = await widget.session.sdk.getBestKnownLocation();
    if (!mounted || location == null) return;
    setState(() {
      latitude = location.latitude.toStringAsFixed(6);
      longitude = location.longitude.toStringAsFixed(6);
    });
  }

  int _parseIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return 0;
    var result = 0;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) return 0;
      result = (result << 8) | octet;
    }
    return result;
  }

  String _formatIpv4(int value) {
    if (value == 0) return '';
    return <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ].join('.');
  }

  String _uuid(int high, int low) {
    final hex = '${high.toUnsigned(64).toRadixString(16).padLeft(16, '0')}'
        '${low.toUnsigned(64).toRadixString(16).padLeft(16, '0')}';
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
