import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'conversation_screen.dart';
import 'dashboard_tab.dart';
import 'debug_tab.dart';
import 'device_detail_screen.dart';
import 'driver_catalog.dart';
import 'drivers_tab.dart';
import 'example_database.dart';
import 'models.dart';
import 'marketplace_driver_install.dart';
import 'nodes_tab.dart';
import 'provisioning_screen.dart';
import 'settings_tab.dart';
import 'topology_screen.dart';

enum AppDestination {
  dashboard('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  nodes('Nodes', Icons.hub_outlined, Icons.hub),
  drivers('Drivers', Icons.usb_outlined, Icons.usb),
  settings('Settings', Icons.bluetooth_connected_outlined,
      Icons.bluetooth_connected);

  const AppDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _otaManifestUrl = 'https://www.edgez.ai/api/ota/firmware';

class EdgezExampleApp extends StatefulWidget {
  const EdgezExampleApp({super.key});

  @override
  State<EdgezExampleApp> createState() => _EdgezExampleAppState();
}

class _EdgezExampleAppState extends State<EdgezExampleApp> {
  late final EdgezMeshSession session;
  late final ExampleDatabase database;
  late final EdgezIdentityStore identityStore;
  late final EdgezBleConfigurationStore bleConfigurationStore;
  late final EdgezDriverStore driverStore;
  late final AppLinks appLinks;
  StreamSubscription<Uri>? driverLinkSubscription;
  AppDestination destination = AppDestination.dashboard;
  int? selectedNodeNum;
  bool showTopology = false;
  bool showDebug = false;
  EdgezUserIdentity? userIdentity;
  bool databaseReady = false;
  bool persistenceEnabled = false;
  bool hydrationComplete = false;
  Timer? persistDebounce;
  bool persistInFlight = false;
  bool persistAgain = false;
  String lastPersistSignature = '';
  bool shareLocation = false;
  bool autoReplayReceivedVoice = false;
  bool deviceModeEnabled = false;
  bool provisionMode = false;
  List<ExampleDriver> drivers = ExampleDriverCatalog.bundled;
  MarketplaceDriverInstallRequest? pendingDriverInstall;
  bool bleAutoConnect = false;
  EdgezBleDevice? selectedBleDevice;
  EdgezOtaRelease? otaRelease;
  bool otaCheckInProgress = false;
  bool otaInstallInProgress = false;
  String otaMessage = '';
  String locationMessage = '';

  String meshCountry = 'US';
  String meshId = 'edgez';
  String passphrase = 'edgez123';
  String maxHop = '4';
  int meshBandwidthMhz = 1;
  int meshFrequencyKhz = 902500;
  String beaconIntervalSeconds = '30';
  String userName = 'Flutter Demo';
  ExampleMarker userMarker = ExampleMarker.blue;

  String deviceUserName = 'EdgeZ Device';
  ExampleMarker deviceMarker = ExampleMarker.green;
  String deviceMeshId = 'edgez';
  String deviceMaxHop = '4';
  String deviceBeaconIntervalSeconds = '30';
  bool deviceShareLocation = false;
  String deviceLatitude = '';
  String deviceLongitude = '';
  String deviceGeoFenceName = '';
  int deviceGeoIndex = 0;
  String uartI2cSensorType = '';
  String rs485SensorType = '';
  String deviceType = 'relay';
  String devicePassphrase = '';
  bool deviceUpstreamEnabled = false;
  String deviceUpstreamWifiSsid = '';
  String deviceUpstreamWifiPassphrase = '';
  String deviceBeaconMulticast = '';
  bool deviceSleepModeEnabled = false;

  @override
  void initState() {
    super.initState();
    session = EdgezMeshSession();
    database = ExampleDatabase();
    identityStore = EdgezIdentityStore();
    bleConfigurationStore = EdgezBleConfigurationStore();
    driverStore = EdgezDriverStore();
    appLinks = AppLinks();
    session.addListener(_persistSessionSnapshot);
    unawaited(_loadIdentityAndBleConfiguration());
    unawaited(_hydrateFromDatabase());
    unawaited(_loadInstalledDrivers());
    _listenForDriverLinks();
  }

  Future<void> _loadInstalledDrivers() async {
    try {
      final installed = await driverStore.load();
      final byKey = <String, ExampleDriver>{
        for (final driver in ExampleDriverCatalog.bundled) driver.key: driver,
        for (final bundle in installed)
          bundle.key: ExampleDriver.fromInstalled(bundle),
      };
      if (mounted) setState(() => drivers = byKey.values.toList());
    } catch (_) {
      // Driver storage is optional; bundled drivers remain available.
    }
  }

  void _listenForDriverLinks() {
    try {
      driverLinkSubscription = appLinks.uriLinkStream.listen(
        _handleDriverLink,
        onError: (_) {},
      );
    } catch (_) {
      // Deep-link services are unavailable in widget tests and some hosts.
    }
  }

  void _handleDriverLink(Uri uri) {
    final request = MarketplaceDriverInstallRequest.fromUri(uri);
    if (request == null || !mounted) return;
    setState(() {
      pendingDriverInstall = request;
      destination = AppDestination.drivers;
      provisionMode = false;
    });
  }

  void _driverInstallHandled() {
    setState(() => pendingDriverInstall = null);
  }

  Future<void> _openProvisioning() async {
    if (session.state.connection != EdgezConnectionType.none) {
      await session.disconnect();
    }
    session.beginProvisioning();
    if (mounted) setState(() => provisionMode = true);
  }

  void _closeProvisioning() {
    session.endProvisioning();
    setState(() {
      provisionMode = false;
      destination = AppDestination.nodes;
    });
    final selected = selectedBleDevice;
    if (bleAutoConnect && selected != null) {
      unawaited(_connectBleDevice(selected.id));
    }
  }

  Future<void> _loadIdentityAndBleConfiguration() async {
    final identity = await identityStore.getOrCreate();
    final bleConfiguration = await bleConfigurationStore.load();
    if (!mounted) return;
    setState(() {
      userIdentity = identity;
      userName = identity.name;
      selectedBleDevice = bleConfiguration.selectedDevice;
      bleAutoConnect = bleConfiguration.autoConnect;
      shareLocation = bleConfiguration.shareLocation;
    });
    if (bleConfiguration.autoConnect && bleConfiguration.hasSelectedDevice) {
      await _connectBleDevice(bleConfiguration.deviceId);
    }
  }

  @override
  void dispose() {
    unawaited(driverLinkSubscription?.cancel());
    persistDebounce?.cancel();
    persistenceEnabled = false;
    session.removeListener(_persistSessionSnapshot);
    session.dispose();
    unawaited(database.close());
    super.dispose();
  }

  Future<void> _hydrateFromDatabase() async {
    try {
      await database.open();
      final nodes = await database.loadNodes();
      final conversations = await database.loadConversations();
      final samples = <int, List<EdgezSensorSample>>{};
      for (final nodeNum in nodes.keys) {
        samples[nodeNum] = await database.loadSensorSamples(nodeNum);
      }
      session.restoreCachedMeshData(
        nodes: nodes,
        conversations: conversations,
        sensorSamples: samples,
      );
      lastPersistSignature = _persistenceSignature(session.state);
      if (!mounted) return;
      setState(() {
        databaseReady = true;
        persistenceEnabled = true;
        hydrationComplete = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        databaseReady = false;
        persistenceEnabled = false;
        hydrationComplete = true;
      });
    }
  }

  void _persistSessionSnapshot() {
    if (!hydrationComplete || !persistenceEnabled) return;
    final signature = _persistenceSignature(session.state);
    if (signature == lastPersistSignature) return;
    persistDebounce?.cancel();
    persistDebounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_persistLatestSessionSnapshot()),
    );
  }

  Future<void> _persistLatestSessionSnapshot() async {
    if (!hydrationComplete || !persistenceEnabled) return;
    if (persistInFlight) {
      persistAgain = true;
      return;
    }

    persistInFlight = true;
    try {
      do {
        persistAgain = false;
        final state = session.state;
        final signature = _persistenceSignature(state);
        if (signature != lastPersistSignature) {
          await database.persistStateSnapshot(state);
          lastPersistSignature = signature;
        }
      } while (persistAgain && persistenceEnabled);
    } catch (_) {
      if (mounted) {
        setState(() => databaseReady = false);
      }
    } finally {
      persistInFlight = false;
    }
  }

  String _persistenceSignature(EdgezMeshState state) {
    final buffer = StringBuffer();
    final nodes = state.nodes.values.toList()
      ..sort((a, b) => a.nodeNum.compareTo(b.nodeNum));
    for (final node in nodes) {
      buffer
        ..write(node.nodeNum)
        ..write('|')
        ..write(node.userUuid)
        ..write('|')
        ..write(node.displayName)
        ..write('|')
        ..write(node.route)
        ..write('|')
        ..write(node.lastSeenMs)
        ..write('|')
        ..write(node.marker)
        ..write('|')
        ..write(node.latitude)
        ..write('|')
        ..write(node.longitude)
        ..write('|')
        ..write(node.deviceType)
        ..write('|')
        ..write(node.geoFenceName)
        ..write('|')
        ..write(node.geoIndex)
        ..write('|')
        ..write(node.sleeping)
        ..write(';');
    }
    final conversations = state.conversations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in conversations) {
      buffer
        ..write('c')
        ..write(entry.key)
        ..write(':');
      for (final message in entry.value) {
        buffer
          ..write(message.timestampMs)
          ..write('|')
          ..write(message.mine)
          ..write('|')
          ..write(message.text)
          ..write('|')
          ..write(message.status)
          ..write('|')
          ..write(message.messageUuid)
          ..write(';');
      }
    }
    return buffer.toString();
  }

  Future<void> _connectBle() async {
    await session.startBleScan();
  }

  Future<void> _stopBleScan() async {
    await session.stopBleScan();
  }

  Future<void> _connectBleDevice(String deviceId) async {
    // Match the Android flow: make the current mesh configuration available
    // before BLE service discovery emits its ready event.
    await _saveAppSettings();
    await session.connectBle(deviceId);
  }

  Future<void> _disconnect() async {
    await session.disconnect();
    setState(() {
      selectedNodeNum = null;
      showTopology = false;
    });
  }

  Future<void> _saveAppSettings() async {
    final parsedMaxHop = int.tryParse(maxHop) ?? 0;
    final identity = await identityStore.updateName(userName);
    final location = shareLocation ? await _getBestKnownLocation() : null;
    if (mounted) {
      setState(() {
        userIdentity = identity;
        userName = identity.name;
      });
    }
    await session.initializeMesh(
      EdgezMeshConfig(
        countryCode: meshCountry,
        meshId: meshId.trim(),
        passphrase: passphrase,
        maxHop: parsedMaxHop,
        meshBandwidthMhz: meshBandwidthMhz,
        meshFrequencyKhz: meshFrequencyKhz,
        beacon: EdgezBeaconConfig(
          intervalSeconds: int.tryParse(beaconIntervalSeconds) ?? 30,
          marker: userMarker.name,
          shareLocation: shareLocation,
          latitude: location?.latitude,
          longitude: location?.longitude,
          locationTimestampMs: location?.timestampMs ?? 0,
        ),
        identity: EdgezUserIdentity(
          userUuid: identity.userUuid,
          userIdHigh: identity.userIdHigh,
          userIdLow: identity.userIdLow,
          name: identity.name,
          privateKey: identity.privateKey,
          publicKey: identity.publicKey,
        ),
      ),
    );
  }

  Future<void> _regenerateUserKeyPair() async {
    final identity = await identityStore.regenerateKeyPair();
    if (!mounted) return;
    setState(() => userIdentity = identity);
  }

  Future<void> _saveDeviceSettings() async {
    if (deviceShareLocation) await _refreshDeviceLocation();
    final latitude = double.tryParse(deviceLatitude);
    final longitude = double.tryParse(deviceLongitude);
    if (deviceShareLocation && (latitude == null || longitude == null)) {
      throw StateError('No phone location is available for the device');
    }
    final scripts = <EdgezSensorScriptConfig>[];
    for (final key in <String>[uartI2cSensorType, rs485SensorType]) {
      if (key.isEmpty) continue;
      final driver = drivers.where((item) => item.key == key).firstOrNull;
      if (driver != null) scripts.add(await driver.loadScript());
    }
    await session.sendDeviceSettings(
      EdgezDeviceSettings(
        deviceModeEnabled: deviceModeEnabled,
        meshId: deviceMeshId.trim(),
        shareLocation: deviceShareLocation,
        userName: deviceUserName.trim(),
        marker: deviceMarker.name,
        beaconIntervalSeconds: int.tryParse(deviceBeaconIntervalSeconds) ?? 30,
        maxHop: int.tryParse(deviceMaxHop) ?? 0,
        latitude: deviceShareLocation ? latitude : null,
        longitude: deviceShareLocation ? longitude : null,
        geoFenceName: deviceGeoFenceName.trim(),
        geoIndex: deviceGeoIndex,
        uartI2cSensorType: uartI2cSensorType,
        rs485SensorType: rs485SensorType,
        passphrase: devicePassphrase,
        upstreamWifiSsid:
            deviceUpstreamEnabled ? deviceUpstreamWifiSsid.trim() : '',
        upstreamWifiPassphrase:
            deviceUpstreamEnabled ? deviceUpstreamWifiPassphrase : '',
        beaconUnicast: deviceUpstreamEnabled
            ? _parseIpv4Address(deviceBeaconMulticast)
            : 0,
        deviceType: deviceType,
        sleepModeEnabled: deviceSleepModeEnabled,
      ),
      scripts: scripts,
    );
  }

  Future<void> _refreshDeviceLocation() async {
    final location = await _getBestKnownLocation();
    if (location == null || !mounted) return;
    setState(() {
      deviceLatitude = location.latitude.toStringAsFixed(6);
      deviceLongitude = location.longitude.toStringAsFixed(6);
    });
  }

  Future<EdgezLocation?> _getBestKnownLocation() async {
    try {
      final location = await session.sdk.getBestKnownLocation();
      if (mounted) {
        setState(() {
          locationMessage = location == null
              ? 'No phone location is available yet'
              : 'Phone location: ${location.latitude.toStringAsFixed(6)}, '
                  '${location.longitude.toStringAsFixed(6)}';
        });
      }
      return location;
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          locationMessage = 'Location support was added to the native plugin. '
              'Fully stop and run the app again (hot reload is not enough).';
        });
      }
      return null;
    } catch (error) {
      if (mounted) {
        setState(() => locationMessage = 'Location unavailable: $error');
      }
      return null;
    }
  }

  void _setShareLocation(bool value) {
    setState(() => shareLocation = value);
    unawaited(bleConfigurationStore.setShareLocation(value));
    if (value) unawaited(_getBestKnownLocation());
  }

  void _setDeviceShareLocation(bool value) {
    setState(() => deviceShareLocation = value);
    if (value) unawaited(_refreshDeviceLocation());
  }

  Future<void> _checkForOtaUpdate() async {
    if (otaCheckInProgress ||
        otaInstallInProgress ||
        session.state.otaInProgress) {
      return;
    }
    setState(() {
      otaCheckInProgress = true;
      otaMessage = 'Checking for firmware updates...';
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(_otaManifestUrl));
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Firmware check failed: HTTP ${response.statusCode}');
      }
      final json = jsonDecode(await utf8.decoder.bind(response).join())
          as Map<String, dynamic>;
      final release = EdgezOtaRelease.fromJson(json);
      if (!mounted) return;
      setState(() {
        otaRelease = release;
        otaMessage = release.isNewerThan(
          session.state.status?.firmwareVersion ?? '',
        )
            ? 'Update available: ${release.version}'
            : 'Your firmware is up to date';
      });
    } catch (error) {
      if (mounted) setState(() => otaMessage = '$error');
    } finally {
      client.close(force: true);
      if (mounted) setState(() => otaCheckInProgress = false);
    }
  }

  Future<void> _installOtaUpdate() async {
    final release = otaRelease;
    if (release == null ||
        otaInstallInProgress ||
        session.state.otaInProgress) {
      return;
    }
    if (!session.state.otaReady) {
      setState(() => otaMessage = 'Reconnect to a device with BLE OTA support');
      return;
    }
    setState(() {
      otaInstallInProgress = true;
      otaMessage = 'Downloading ${release.version}...';
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(release.url));
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
            'Firmware download failed: HTTP ${response.statusCode}');
      }
      final image =
          await response.timeout(const Duration(seconds: 30)).fold<List<int>>(
        <int>[],
        (bytes, chunk) => bytes..addAll(chunk),
      );
      if (image.length != release.size) {
        throw StateError(
          'Firmware size mismatch: ${image.length}/${release.size}',
        );
      }
      await session.performOta(image);
      if (mounted) {
        setState(
            () => otaMessage = 'Firmware uploaded. The device is restarting.');
      }
    } catch (error) {
      if (mounted) setState(() => otaMessage = '$error');
    } finally {
      client.close(force: true);
      if (mounted) setState(() => otaInstallInProgress = false);
    }
  }

  void _openNode(EdgezMeshNode node) {
    setState(() => selectedNodeNum = node.nodeNum);
  }

  void _removeNode(EdgezMeshNode node) {
    session.removeNode(node.nodeNum);
    if (persistenceEnabled) {
      unawaited(_deletePersistedNode(node.nodeNum));
    }
    if (selectedNodeNum == node.nodeNum) {
      setState(() => selectedNodeNum = null);
    }
  }

  Future<void> _deletePersistedNode(int nodeNum) async {
    persistDebounce?.cancel();
    while (persistInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!persistenceEnabled) return;
    await database.deleteNode(nodeNum);
    lastPersistSignature = _persistenceSignature(session.state);
  }

  void _sendMessage(String text) {
    final nodeNum = selectedNodeNum;
    if (nodeNum == null) return;
    session.sendTextMessage(
      toNode: nodeNum,
      text: text,
      maxHop: int.tryParse(maxHop) ?? 0,
    );
  }

  Future<bool> _startVoiceMessage() {
    return session.startVoiceMessage();
  }

  Future<void> _stopVoiceMessage(bool send) async {
    final nodeNum = selectedNodeNum;
    if (!send || nodeNum == null) {
      await session.cancelVoiceMessage();
      return;
    }
    await session.finishVoiceMessage(
      toNode: nodeNum,
      send: send,
      maxHop: int.tryParse(maxHop) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final meshState = session.state;
        final selected =
            selectedNodeNum == null ? null : meshState.nodes[selectedNodeNum!];
        final body = switch (destination) {
          AppDestination.dashboard => selected == null
              ? DashboardScreen(
                  activeConnection: meshState.connection,
                  status: meshState.status,
                  users: meshState.sortedNodes,
                  sensorSamples: meshState.sensorSamples,
                  onOpenProvisioning: _openProvisioning,
                  onOpenNode: _openNode,
                )
              : selected.opensConversation
                  ? ConversationScreen(
                      activeConnection: meshState.connection,
                      user: selected,
                      messages: meshState.conversations[selected.nodeNum] ??
                          const <EdgezConversationMessage>[],
                      sensorSamples:
                          meshState.sensorSamples[selected.nodeNum] ??
                              const <EdgezSensorSample>[],
                      onBack: () => setState(() => selectedNodeNum = null),
                      onSendMessage: _sendMessage,
                      onStartVoiceMessage: _startVoiceMessage,
                      onStopVoiceMessage: _stopVoiceMessage,
                      onReplayVoiceMessage: session.playVoiceMessage,
                      callState: meshState.voiceCall,
                      onStartCall: () =>
                          session.startVoiceCall(selected.nodeNum),
                      onAcceptCall: session.acceptVoiceCall,
                      onEndCall: session.endVoiceCall,
                    )
                  : DeviceDetailScreen(
                      user: selected,
                      samples: meshState.sensorSamples[selected.nodeNum] ??
                          const <EdgezSensorSample>[],
                      onBack: () => setState(() => selectedNodeNum = null),
                    ),
          AppDestination.nodes => showTopology
              ? TopologyScreen(
                  users: meshState.sortedNodes,
                  links: meshState.topologyLinks,
                  onBack: () => setState(() => showTopology = false),
                )
              : selected == null
                  ? NodesScreen(
                      activeConnection: meshState.connection,
                      status: meshState.status,
                      users: meshState.sortedNodes,
                      sensorSamples: meshState.sensorSamples,
                      onOpenTopology: () => setState(() => showTopology = true),
                      onRemoveNode: _removeNode,
                      onOpenNode: _openNode,
                    )
                  : selected.opensConversation
                      ? ConversationScreen(
                          activeConnection: meshState.connection,
                          user: selected,
                          messages: meshState.conversations[selected.nodeNum] ??
                              const <EdgezConversationMessage>[],
                          sensorSamples:
                              meshState.sensorSamples[selected.nodeNum] ??
                                  const <EdgezSensorSample>[],
                          onBack: () => setState(() => selectedNodeNum = null),
                          onSendMessage: _sendMessage,
                          onStartVoiceMessage: _startVoiceMessage,
                          onStopVoiceMessage: _stopVoiceMessage,
                          onReplayVoiceMessage: session.playVoiceMessage,
                          callState: meshState.voiceCall,
                          onStartCall: () =>
                              session.startVoiceCall(selected.nodeNum),
                          onAcceptCall: session.acceptVoiceCall,
                          onEndCall: session.endVoiceCall,
                        )
                      : DeviceDetailScreen(
                          user: selected,
                          samples: meshState.sensorSamples[selected.nodeNum] ??
                              const <EdgezSensorSample>[],
                          onBack: () => setState(() => selectedNodeNum = null),
                        ),
          AppDestination.drivers => DriversScreen(
              drivers: drivers,
              driverStore: driverStore,
              installRequest: pendingDriverInstall,
              onInstallHandled: _driverInstallHandled,
              onInstalled: _loadInstalledDrivers,
            ),
          AppDestination.settings => showDebug
              ? DebugScreen(
                  activeConnection: meshState.connection,
                  meshStatus: meshState.status,
                  statusLine: meshState.statusLine,
                  nodeCount: meshState.nodes.length,
                  conversationCount: meshState.conversations.length,
                  shareLocation: shareLocation,
                  deviceModeEnabled: deviceModeEnabled,
                  databaseReady: databaseReady,
                  onClose: () => setState(() => showDebug = false),
                )
              : SettingsScreen(
                  activeConnection: meshState.connection,
                  shareLocation: shareLocation,
                  autoReplayReceivedVoice: autoReplayReceivedVoice,
                  deviceModeEnabled: deviceModeEnabled,
                  bleDevices: meshState.sortedBleDevices,
                  drivers: drivers,
                  selectedBleDevice: selectedBleDevice,
                  meshStatus: meshState.status,
                  bleAutoConnect: bleAutoConnect,
                  statusLine: meshState.statusLine,
                  otaUpdateAvailable: otaRelease?.isNewerThan(
                        meshState.status?.firmwareVersion ?? '',
                      ) ??
                      false,
                  otaReady: meshState.otaReady,
                  otaCheckInProgress: otaCheckInProgress,
                  otaInProgress:
                      otaInstallInProgress || meshState.otaInProgress,
                  otaProgress:
                      meshState.otaInProgress ? meshState.otaProgress : 0,
                  otaMessage: meshState.otaInProgress && otaRelease != null
                      ? 'Installing ${otaRelease!.version}: '
                          '${(meshState.otaProgress * 100).floor()}%'
                      : otaMessage,
                  locationMessage: locationMessage,
                  meshCountry: meshCountry,
                  meshId: meshId,
                  passphrase: passphrase,
                  maxHop: maxHop,
                  meshBandwidthMhz: meshBandwidthMhz,
                  meshFrequencyKhz: meshFrequencyKhz,
                  beaconIntervalSeconds: beaconIntervalSeconds,
                  userName: userName,
                  userIdentity: userIdentity,
                  userMarker: userMarker,
                  deviceUserName: deviceUserName,
                  deviceMarker: deviceMarker,
                  deviceMeshId: deviceMeshId,
                  deviceMaxHop: deviceMaxHop,
                  deviceBeaconIntervalSeconds: deviceBeaconIntervalSeconds,
                  deviceShareLocation: deviceShareLocation,
                  deviceLatitude: deviceLatitude,
                  deviceLongitude: deviceLongitude,
                  deviceGeoFenceName: deviceGeoFenceName,
                  deviceGeoIndex: deviceGeoIndex,
                  uartI2cSensorType: uartI2cSensorType,
                  rs485SensorType: rs485SensorType,
                  deviceType: deviceType,
                  devicePassphrase: devicePassphrase,
                  deviceUpstreamEnabled: deviceUpstreamEnabled,
                  deviceUpstreamWifiSsid: deviceUpstreamWifiSsid,
                  deviceUpstreamWifiPassphrase: deviceUpstreamWifiPassphrase,
                  deviceBeaconMulticast: deviceBeaconMulticast,
                  deviceSleepModeEnabled: deviceSleepModeEnabled,
                  onConnectBle: _connectBle,
                  onStopBleScan: _stopBleScan,
                  onConnectBleDevice: _connectBleDevice,
                  onSelectBleDevice: (device) {
                    setState(() => selectedBleDevice = device);
                    unawaited(bleConfigurationStore.saveSelectedDevice(device));
                  },
                  onBleAutoConnectChanged: (value) {
                    setState(() => bleAutoConnect = value);
                    unawaited(bleConfigurationStore.setAutoConnect(value));
                  },
                  onDisconnect: _disconnect,
                  onOpenDebug: () => setState(() => showDebug = true),
                  onCheckForOtaUpdate: _checkForOtaUpdate,
                  onInstallOtaUpdate: _installOtaUpdate,
                  onSaveAppSettings: _saveAppSettings,
                  onRegenerateUserKeyPair: _regenerateUserKeyPair,
                  onSaveDeviceSettings: _saveDeviceSettings,
                  onShareLocationChanged: _setShareLocation,
                  onAutoReplayChanged: (value) =>
                      setState(() => autoReplayReceivedVoice = value),
                  onDeviceModeChanged: (value) =>
                      setState(() => deviceModeEnabled = value),
                  onMeshCountryChanged: (value) => setState(() {
                    meshCountry = value;
                    final bandwidths = halowBandwidthOptions(value);
                    if (!bandwidths.contains(meshBandwidthMhz)) {
                      meshBandwidthMhz = bandwidths.first;
                    }
                    final frequencies =
                        halowFrequenciesKhz(value, meshBandwidthMhz);
                    if (!frequencies.contains(meshFrequencyKhz)) {
                      meshFrequencyKhz = frequencies.first;
                    }
                  }),
                  onMeshBandwidthChanged: (value) => setState(() {
                    meshBandwidthMhz = value;
                    final frequencies = halowFrequenciesKhz(meshCountry, value);
                    if (!frequencies.contains(meshFrequencyKhz)) {
                      meshFrequencyKhz = frequencies.first;
                    }
                  }),
                  onMeshFrequencyChanged: (value) =>
                      setState(() => meshFrequencyKhz = value),
                  onMeshIdChanged: (value) => setState(() => meshId = value),
                  onPassphraseChanged: (value) =>
                      setState(() => passphrase = value),
                  onMaxHopChanged: (value) => setState(() => maxHop = value),
                  onBeaconIntervalChanged: (value) =>
                      setState(() => beaconIntervalSeconds = value),
                  onUserNameChanged: (value) =>
                      setState(() => userName = value),
                  onUserMarkerChanged: (value) =>
                      setState(() => userMarker = value),
                  onDeviceUserNameChanged: (value) =>
                      setState(() => deviceUserName = value),
                  onDeviceMarkerChanged: (value) =>
                      setState(() => deviceMarker = value),
                  onDeviceMeshIdChanged: (value) =>
                      setState(() => deviceMeshId = value),
                  onDeviceMaxHopChanged: (value) =>
                      setState(() => deviceMaxHop = value),
                  onDeviceBeaconIntervalChanged: (value) =>
                      setState(() => deviceBeaconIntervalSeconds = value),
                  onDeviceShareLocationChanged: _setDeviceShareLocation,
                  onRefreshDeviceLocation: _refreshDeviceLocation,
                  onDeviceLatitudeChanged: (value) =>
                      setState(() => deviceLatitude = value),
                  onDeviceLongitudeChanged: (value) =>
                      setState(() => deviceLongitude = value),
                  onDeviceGeoFenceNameChanged: (value) =>
                      setState(() => deviceGeoFenceName = value),
                  onDeviceGeoIndexChanged: (value) =>
                      setState(() => deviceGeoIndex = value),
                  onUartI2cSensorChanged: (value) =>
                      setState(() => uartI2cSensorType = value),
                  onRs485SensorChanged: (value) =>
                      setState(() => rs485SensorType = value),
                  onDeviceTypeChanged: (value) =>
                      setState(() => deviceType = value),
                  onDevicePassphraseChanged: (value) =>
                      setState(() => devicePassphrase = value),
                  onDeviceUpstreamEnabledChanged: (value) =>
                      setState(() => deviceUpstreamEnabled = value),
                  onDeviceUpstreamWifiSsidChanged: (value) =>
                      setState(() => deviceUpstreamWifiSsid = value),
                  onDeviceUpstreamWifiPassphraseChanged: (value) =>
                      setState(() => deviceUpstreamWifiPassphrase = value),
                  onDeviceBeaconMulticastChanged: (value) =>
                      setState(() => deviceBeaconMulticast = value),
                  onDeviceSleepModeChanged: (value) =>
                      setState(() => deviceSleepModeEnabled = value),
                ),
        };

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            useMaterial3: true,
            cardTheme: const CardThemeData(margin: EdgeInsets.zero),
          ),
          home: provisionMode
              ? ProvisioningScreen(
                  session: session,
                  drivers: drivers,
                  excludedBleDeviceId: selectedBleDevice?.id,
                  onCancel: _closeProvisioning,
                  onComplete: _closeProvisioning,
                )
              : Scaffold(
                  body: body,
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: AppDestination.values.indexOf(destination),
                    onDestinationSelected: (index) => setState(() {
                      destination = AppDestination.values[index];
                      showDebug = false;
                      if (destination != AppDestination.nodes) {
                        selectedNodeNum = null;
                        showTopology = false;
                      }
                    }),
                    destinations: AppDestination.values.map((item) {
                      return NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  int _parseIpv4Address(String value) {
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
}
