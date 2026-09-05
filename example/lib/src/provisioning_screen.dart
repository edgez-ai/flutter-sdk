import 'dart:async';
import 'dart:convert';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'driver_catalog.dart';
import 'localized_model_labels.dart';
import 'models.dart';
import 'settings_tab.dart';
import 'shared_widgets.dart';

enum _ProvisionStep {
  selectBle('Select BLE device'),
  mode('Device mode'),
  deviceUser('Device user'),
  network('Network'),
  relayWifi('Relay Wi-Fi'),
  location('Location'),
  geoFence('Geo fence'),
  sensor('Sensor'),
  sleepMode('Sleep mode');

  const _ProvisionStep(this.title);
  final String title;
}

String _localizedStepTitle(AppLocalizations l10n, _ProvisionStep step) =>
    switch (step) {
      _ProvisionStep.selectBle => l10n.selectBleDevice,
      _ProvisionStep.mode => l10n.deviceMode,
      _ProvisionStep.deviceUser => l10n.deviceUser,
      _ProvisionStep.network => l10n.network,
      _ProvisionStep.relayWifi => l10n.relayWifi,
      _ProvisionStep.location => l10n.location,
      _ProvisionStep.geoFence => l10n.geoFence,
      _ProvisionStep.sensor => l10n.sensor,
      _ProvisionStep.sleepMode => l10n.sleepMode,
    };

List<EdgezBleDevice> provisioningBleDevices(
  List<EdgezBleDevice> devices,
  String? excludedDeviceId,
) {
  if (excludedDeviceId == null || excludedDeviceId.isEmpty) return devices;
  return devices
      .where((device) => device.id != excludedDeviceId)
      .toList(growable: false);
}

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({
    required this.session,
    required this.drivers,
    required this.excludedBleDeviceId,
    required this.defaultMeshId,
    required this.defaultPassphrase,
    required this.defaultMaxHop,
    required this.defaultBeaconInterval,
    required this.defaultMeshCountry,
    required this.defaultMeshFrequencyKhz,
    required this.defaultMeshBandwidthMhz,
    required this.onCancel,
    required this.onComplete,
    super.key,
  });

  final EdgezMeshSession session;
  final List<ExampleDriver> drivers;
  final String? excludedBleDeviceId;
  final String defaultMeshId;
  final String defaultPassphrase;
  final String defaultMaxHop;
  final String defaultBeaconInterval;
  final String defaultMeshCountry;
  final int defaultMeshFrequencyKhz;
  final int defaultMeshBandwidthMhz;
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
  bool requestedAuthorization = false;
  bool requestedSettings = false;
  bool licenseDialogShown = false;
  bool saving = false;
  String? error;
  Timer? authorizationTimeout;

  String deviceType = '';
  String userName = 'EdgeZ Device';
  ExampleMarker marker = ExampleMarker.green;
  late String meshId;
  late String passphrase;
  late String maxHop;
  late String beaconInterval;
  late String meshCountry;
  late int meshFrequencyKhz;
  late int meshBandwidthMhz;
  bool shareLocation = false;
  bool deviceGpsEnabled = false;
  String latitude = '';
  String longitude = '';
  String geoFenceName = '';
  int geoIndex = 0;
  String uartI2cDriver = '';
  String rs485Driver = '';
  bool sleepMode = false;

  List<_ProvisionStep> get steps => _ProvisionStep.values
      .where((item) => deviceType == 'relay'
          ? item != _ProvisionStep.sleepMode
          : item != _ProvisionStep.relayWifi)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    meshId = widget.defaultMeshId;
    passphrase = widget.defaultPassphrase;
    maxHop = widget.defaultMaxHop;
    beaconInterval = widget.defaultBeaconInterval;
    meshCountry = widget.defaultMeshCountry;
    meshFrequencyKhz = widget.defaultMeshFrequencyKhz;
    meshBandwidthMhz = widget.defaultMeshBandwidthMhz;
    _normalizeRadioSelection();
    deviceIdentity = EdgezIdentityStore().createIdentity(name: userName);
    widget.session.addListener(_sessionChanged);
    unawaited(widget.session.startBleScan());
  }

  @override
  void dispose() {
    authorizationTimeout?.cancel();
    widget.session.removeListener(_sessionChanged);
    if (step == _ProvisionStep.selectBle) {
      unawaited(widget.session.stopBleScan());
    }
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted || !waitingForSettings) return;
    final state = widget.session.state;
    if (state.bleReady && !requestedAuthorization) {
      requestedAuthorization = true;
      authorizationTimeout?.cancel();
      authorizationTimeout = Timer(const Duration(seconds: 8), () {
        if (!mounted || !waitingForSettings || requestedSettings) return;
        final status = widget.session.state.status?.licenseStatus ??
            EdgezLicenseStatus.unspecified;
        setState(() {
          waitingForSettings = false;
          error = 'Device license check timed out';
        });
        if (!licenseDialogShown) {
          licenseDialogShown = true;
          unawaited(_showInvalidLicenseDialog(status));
        }
      });
      unawaited(_authorizeDevice());
    }

    final licenseStatus = state.status?.licenseStatus;
    if (requestedAuthorization &&
        licenseStatus != null &&
        _isRejectedLicense(licenseStatus)) {
      authorizationTimeout?.cancel();
      if (!licenseDialogShown) {
        licenseDialogShown = true;
        waitingForSettings = false;
        error = 'Provisioning unavailable: ${licenseStatus.label}';
        unawaited(_showInvalidLicenseDialog(licenseStatus));
      }
    } else if (requestedAuthorization &&
        licenseStatus?.isAuthorized == true &&
        !requestedSettings) {
      authorizationTimeout?.cancel();
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

  Future<void> _authorizeDevice() async {
    try {
      await widget.session.authorizeSession();
    } catch (exception) {
      authorizationTimeout?.cancel();
      if (!mounted) return;
      setState(() {
        waitingForSettings = false;
        error = 'Device license check failed: $exception';
      });
    }
  }

  bool _isRejectedLicense(EdgezLicenseStatus status) {
    return status == EdgezLicenseStatus.deviceNotLicensed ||
        status == EdgezLicenseStatus.sdkVersionIncompatible ||
        status == EdgezLicenseStatus.sdkReleaseInvalid;
  }

  Future<void> _showInvalidLicenseDialog(EdgezLicenseStatus status) {
    final detail = status == EdgezLicenseStatus.unspecified
        ? AppLocalizations.of(context).licenseNoResponse
        : '${status.label}.';
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deviceLicenseInvalid),
        content: Text(
          '$detail ${AppLocalizations.of(context).provisioningCannotContinue}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
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
    shareLocation = settings.shareLocation;
    deviceGpsEnabled = settings.deviceGpsEnabled;
    latitude = settings.latitude?.toString() ?? '';
    longitude = settings.longitude?.toString() ?? '';
    geoFenceName = settings.geoFenceName;
    geoIndex = settings.geoIndex;
    uartI2cDriver = settings.uartI2cSensorType;
    rs485Driver = settings.rs485SensorType;
    sleepMode = settings.sleepModeEnabled;
    if (settings.meshFrequencyKhz > 0) {
      meshFrequencyKhz = settings.meshFrequencyKhz;
    }
    if (settings.meshBandwidthMhz > 0) {
      meshBandwidthMhz = settings.meshBandwidthMhz;
    }
    _normalizeRadioSelection();
    final hasDeviceUuid = settings.userIdHigh != 0 || settings.userIdLow != 0;
    final hasDeviceKeyPair = settings.userPrivateKey.length == 32 &&
        settings.userPublicKey.length == 32;
    if (hasDeviceUuid && hasDeviceKeyPair) {
      deviceIdentity = EdgezUserIdentity(
        userUuid: _uuid(settings.userIdHigh, settings.userIdLow),
        userIdHigh: settings.userIdHigh,
        userIdLow: settings.userIdLow,
        name: userName,
        privateKey: settings.userPrivateKey,
        publicKey: settings.userPublicKey,
      );
    } else {
      // An unprovisioned device has no identity of its own. Generate one here
      // after reading the device instead of falling back to the app user's
      // identity from the regular Settings screen.
      deviceIdentity = EdgezIdentityStore().createIdentity(name: userName);
    }
  }

  Future<void> _connectAndLoad() async {
    final device = selectedBle;
    if (device == null) return;
    setState(() {
      // Never carry an identity candidate between provisioning targets. The
      // device report will restore a complete existing identity or generate a
      // new one when the report contains no UUID.
      deviceIdentity = EdgezIdentityStore().createIdentity(name: userName);
      waitingForSettings = true;
      requestedAuthorization = false;
      requestedSettings = false;
      licenseDialogShown = false;
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
      step = steps[steps.indexOf(step) - 1];
      error = null;
    });
  }

  void _normalizeRadioSelection() {
    final bandwidths = halowBandwidthOptions(meshCountry);
    if (!bandwidths.contains(meshBandwidthMhz)) {
      meshBandwidthMhz = bandwidths.first;
    }
    final frequencies = halowFrequenciesKhz(meshCountry, meshBandwidthMhz);
    if (!frequencies.contains(meshFrequencyKhz)) {
      meshFrequencyKhz = frequencies.first;
    }
  }

  void _setMeshCountry(String value) {
    setState(() {
      meshCountry = value;
      _normalizeRadioSelection();
    });
  }

  void _setMeshBandwidth(int value) {
    setState(() {
      meshBandwidthMhz = value;
      _normalizeRadioSelection();
    });
  }

  Future<void> _next() async {
    if (step == _ProvisionStep.selectBle) {
      await _connectAndLoad();
      return;
    }
    if (step == _ProvisionStep.mode && deviceType.isEmpty) {
      setState(() => error = AppLocalizations.of(context).selectDeviceMode);
      return;
    }
    if (step == _ProvisionStep.relayWifi && !_validateRelayWifi()) return;
    if (step == steps.last) {
      await _save();
      return;
    }
    setState(() {
      step = steps[steps.indexOf(step) + 1];
      error = null;
    });
  }

  bool _validateRelayWifi() {
    final ssid = meshId.trim();
    final password = passphrase;
    final passwordBytes = utf8.encode(password).length;
    final validPassword =
        password.isEmpty || (passwordBytes >= 8 && passwordBytes <= 63);
    if (ssid.isEmpty || utf8.encode(ssid).length > 32 || !validPassword) {
      setState(() => error = AppLocalizations.of(context).invalidRelayWifi);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (deviceType == 'relay' && !_validateRelayWifi()) {
      setState(() => step = _ProvisionStep.relayWifi);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final state = widget.session.state;
      if (state.connection != EdgezConnectionType.ble || !state.bleReady) {
        throw StateError('The provisioning device is not ready over BLE');
      }
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
          // Clear credentials saved by older firmware. OpenMANET provides WAN.
          upstreamWifiSsid: '',
          upstreamWifiPassphrase: '',
          userName: userName.trim(),
          marker: marker.name,
          maxHop: int.tryParse(maxHop) ?? 4,
          beaconIntervalSeconds: int.tryParse(beaconInterval) ?? 10,
          shareLocation: shareLocation,
          latitude: shareLocation && !deviceGpsEnabled
              ? double.tryParse(latitude)
              : null,
          longitude: shareLocation && !deviceGpsEnabled
              ? double.tryParse(longitude)
              : null,
          geoFenceName: geoFenceName.trim(),
          geoIndex: geoIndex,
          uartI2cSensorType: uartI2cDriver,
          rs485SensorType: rs485Driver,
          sleepModeEnabled: deviceType == 'relay' ? false : sleepMode,
          deviceGpsEnabled: deviceGpsEnabled,
          meshFrequencyKhz: meshFrequencyKhz,
          meshBandwidthMhz: meshBandwidthMhz,
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
        title: Text(AppLocalizations.of(context).provisioning),
        leading: TextButton(
            onPressed: _back, child: Text(AppLocalizations.of(context).back)),
        leadingWidth: 72,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
                AppLocalizations.of(context).stepProgress(
                    steps.indexOf(step) + 1,
                    steps.length,
                    _localizedStepTitle(AppLocalizations.of(context), step)),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Interface: ${state.connection.name.toUpperCase()}'),
            Text(state.statusLine,
                style: Theme.of(context).textTheme.bodySmall),
            if (state.status?.licenseStatus case final status?
                when _isRejectedLicense(status))
              Text(
                  '${status.label}. ${AppLocalizations.of(context).provisioningUnavailable}',
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
                  child: Text(AppLocalizations.of(context).cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _canContinue(state) ? _next : null,
                  child: Text(saving
                      ? AppLocalizations.of(context).saving
                      : step == steps.last
                          ? AppLocalizations.of(context).save
                          : waitingForSettings
                              ? AppLocalizations.of(context).loading
                              : AppLocalizations.of(context).next),
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
    if (state.connection == EdgezConnectionType.ble &&
        state.status != null &&
        !state.status!.licenseStatus.isAuthorized) {
      return false;
    }
    return step != _ProvisionStep.selectBle || selectedBle != null;
  }

  Widget _stepContent(EdgezMeshState state) {
    switch (step) {
      case _ProvisionStep.selectBle:
        final devices = provisioningBleDevices(
          state.sortedBleDevices,
          widget.excludedBleDeviceId,
        );
        return InfoCard(
          title: AppLocalizations.of(context).selectBleDevice,
          action: IconButton(
            tooltip: AppLocalizations.of(context).scanAgain,
            onPressed: widget.session.startBleScan,
            icon: const Icon(Icons.refresh),
          ),
          children: <Widget>[
            if (devices.isEmpty)
              Text(AppLocalizations.of(context).scanningDevices),
            for (final device in devices)
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
          title: AppLocalizations.of(context).deviceMode,
          children: <Widget>[
            SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment(
                    value: 'beacon',
                    label: Text(AppLocalizations.of(context).beacon)),
                ButtonSegment(
                    value: 'sensor',
                    label: Text(AppLocalizations.of(context).sensor)),
                ButtonSegment(
                    value: 'relay',
                    label: Text(AppLocalizations.of(context).relay)),
              ],
              emptySelectionAllowed: true,
              selected: deviceType.isEmpty ? const {} : {deviceType},
              onSelectionChanged: (value) =>
                  setState(() => deviceType = value.first),
            ),
            const SizedBox(height: 8),
            Text(switch (deviceType) {
              'beacon' => AppLocalizations.of(context).beaconModeDescription,
              'sensor' => AppLocalizations.of(context).sensorModeDescription,
              'relay' => AppLocalizations.of(context).relayModeDescription,
              _ => AppLocalizations.of(context).chooseDeviceMode,
            }),
          ],
        );
      case _ProvisionStep.deviceUser:
        return InfoCard(
          title: AppLocalizations.of(context).deviceUser,
          children: <Widget>[
            SettingsTextField(
              label: AppLocalizations.of(context).deviceUserName,
              value: userName,
              onChanged: (value) => setState(() => userName = value),
            ),
            DropdownSetting<ExampleMarker>(
              label: AppLocalizations.of(context).marker,
              value: marker,
              values: ExampleMarker.values,
              titleFor: (value) =>
                  value.localizedLabel(AppLocalizations.of(context)),
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
                child: Text(AppLocalizations.of(context).regenerateDeviceId),
              ),
            ),
          ],
        );
      case _ProvisionStep.network:
        return InfoCard(
          title: AppLocalizations.of(context).meshNetwork,
          children: <Widget>[
            DropdownSetting<String>(
              label: AppLocalizations.of(context).country,
              value: meshCountry,
              values: const <String>['US', 'JP', 'EU'],
              titleFor: (value) => value,
              onChanged: _setMeshCountry,
            ),
            DropdownSetting<int>(
              label: AppLocalizations.of(context).bandwidth,
              value: meshBandwidthMhz,
              values: halowBandwidthOptions(meshCountry),
              titleFor: (value) => '$value MHz',
              onChanged: _setMeshBandwidth,
            ),
            DropdownSetting<int>(
              label: AppLocalizations.of(context).frequency,
              value: meshFrequencyKhz,
              values: halowFrequenciesKhz(
                meshCountry,
                meshBandwidthMhz,
              ),
              titleFor: (value) => halowFrequencyLabel(meshCountry, value),
              onChanged: (value) => setState(() => meshFrequencyKhz = value),
            ),
            SettingsTextField(
                label: AppLocalizations.of(context).meshId,
                value: meshId,
                onChanged: (value) => setState(() => meshId = value)),
            SettingsTextField(
                label: AppLocalizations.of(context).passphrase,
                value: passphrase,
                obscureText: true,
                onChanged: (value) => setState(() => passphrase = value)),
            SettingsTextField(
                label: AppLocalizations.of(context).maxHop,
                value: maxHop,
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() => maxHop = value)),
            SettingsTextField(
                label: AppLocalizations.of(context).beaconInterval,
                value: beaconInterval,
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() => beaconInterval = value)),
          ],
        );
      case _ProvisionStep.relayWifi:
        final l10n = AppLocalizations.of(context);
        return InfoCard(
          title: l10n.relayWifi,
          children: <Widget>[
            const Text('SoftAP'),
            Text(l10n.softapProvisioningDescription),
            const SizedBox(height: 8),
            Text('SSID: ${meshId.trim()}'),
          ],
        );
      case _ProvisionStep.location:
        return InfoCard(
          title: AppLocalizations.of(context).deviceLocation,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).shareLocation),
              value: shareLocation,
              onChanged: (value) => setState(() => shareLocation = value),
            ),
            if (shareLocation) ...<Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context).useDeviceGps),
                subtitle:
                    Text(AppLocalizations.of(context).deviceGpsWakeDescription),
                value: deviceGpsEnabled,
                onChanged: (value) => setState(() => deviceGpsEnabled = value),
              ),
            ],
            if (shareLocation && !deviceGpsEnabled) ...<Widget>[
              SettingsTextField(
                  label: AppLocalizations.of(context).latitude,
                  value: latitude,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => latitude = value)),
              SettingsTextField(
                  label: AppLocalizations.of(context).longitude,
                  value: longitude,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => longitude = value)),
              OutlinedButton.icon(
                onPressed: _refreshLocation,
                icon: const Icon(Icons.my_location),
                label: Text(AppLocalizations.of(context).usePhoneLocation),
              ),
            ],
          ],
        );
      case _ProvisionStep.geoFence:
        return InfoCard(
          title: AppLocalizations.of(context).geoFence,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).enableGeoFence),
              value: geoFenceName.isNotEmpty,
              onChanged: (value) =>
                  setState(() => geoFenceName = value ? 'Geo fence' : ''),
            ),
            if (geoFenceName.isNotEmpty) ...<Widget>[
              SettingsTextField(
                  label: AppLocalizations.of(context).geoFenceName,
                  value: geoFenceName,
                  onChanged: (value) => setState(() => geoFenceName = value)),
              StepperSetting(
                  label: AppLocalizations.of(context).geoIndex,
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
          title: AppLocalizations.of(context).sensorDrivers,
          children: <Widget>[
            DropdownSetting<String>(
              label: AppLocalizations.of(context).uartConnector,
              value: uart.any((item) => item.key == uartI2cDriver)
                  ? uartI2cDriver
                  : '',
              values: <String>['', ...uart.map((item) => item.key)],
              titleFor: (key) => key.isEmpty
                  ? AppLocalizations.of(context).none
                  : uart.firstWhere((item) => item.key == key).label,
              onChanged: (value) => setState(() => uartI2cDriver = value),
            ),
            DropdownSetting<String>(
              label: AppLocalizations.of(context).rs485Connector,
              value: rs485.any((item) => item.key == rs485Driver)
                  ? rs485Driver
                  : '',
              values: <String>['', ...rs485.map((item) => item.key)],
              titleFor: (key) => key.isEmpty
                  ? AppLocalizations.of(context).none
                  : rs485.firstWhere((item) => item.key == key).label,
              onChanged: (value) => setState(() => rs485Driver = value),
            ),
          ],
        );
      case _ProvisionStep.sleepMode:
        return InfoCard(
          title: AppLocalizations.of(context).sleepMode,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).enableSleepMode),
              subtitle: Text(AppLocalizations.of(context).sleepModeDescription),
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

  String _uuid(int high, int low) {
    final hex = '${high.toUnsigned(64).toRadixString(16).padLeft(16, '0')}'
        '${low.toUnsigned(64).toRadixString(16).padLeft(16, '0')}';
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
