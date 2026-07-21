import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'conversation_screen.dart';
import 'debug_tab.dart';
import 'device_detail_screen.dart';
import 'example_database.dart';
import 'models.dart';
import 'nodes_tab.dart';
import 'settings_tab.dart';
import 'topology_screen.dart';

enum AppDestination {
  nodes('Nodes', Icons.hub_outlined, Icons.hub),
  debug('Debug', Icons.bug_report_outlined, Icons.bug_report),
  settings('Settings', Icons.bluetooth_connected_outlined,
      Icons.bluetooth_connected);

  const AppDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _otaManifestUrl = 'https://www.edgez.ai/api/ota/firmware';

class _OtaRelease {
  const _OtaRelease({
    required this.version,
    required this.size,
    required this.url,
  });

  final String version;
  final int size;
  final String url;
}

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
  AppDestination destination = AppDestination.nodes;
  int? selectedNodeNum;
  bool showTopology = false;
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
  bool bleAutoConnect = false;
  EdgezBleDevice? selectedBleDevice;
  _OtaRelease? otaRelease;
  bool otaCheckInProgress = false;
  String otaMessage = '';

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
    session.addListener(_persistSessionSnapshot);
    unawaited(_loadIdentityAndBleConfiguration());
    unawaited(_hydrateFromDatabase());
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
    });
    if (bleConfiguration.autoConnect && bleConfiguration.hasSelectedDevice) {
      await _connectBleDevice(bleConfiguration.deviceId);
    }
  }

  @override
  void dispose() {
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
    await session.sendDeviceSettings(
      EdgezDeviceSettings(
        deviceModeEnabled: deviceModeEnabled,
        meshId: deviceMeshId.trim(),
        shareLocation: deviceShareLocation,
        userName: deviceUserName.trim(),
        marker: deviceMarker.name,
        beaconIntervalSeconds: int.tryParse(deviceBeaconIntervalSeconds) ?? 30,
        maxHop: int.tryParse(deviceMaxHop) ?? 0,
        latitude: double.tryParse(deviceLatitude),
        longitude: double.tryParse(deviceLongitude),
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
    );
  }

  Future<void> _checkForOtaUpdate() async {
    if (otaCheckInProgress || session.state.otaInProgress) return;
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
      final release = _OtaRelease(
        version: json['version'] as String,
        size: json['size'] as int,
        url: json['url'] as String,
      );
      if (!mounted) return;
      setState(() {
        otaRelease = release;
        otaMessage = _isNewerFirmwareVersion(
          session.state.status?.firmwareVersion ?? '',
          release.version,
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
    if (release == null || session.state.otaInProgress) return;
    if (!await session.isOtaReady) {
      setState(() => otaMessage = 'Reconnect to a device with BLE OTA support');
      return;
    }
    setState(() => otaMessage = 'Downloading ${release.version}...');
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
      final image = await response.fold<List<int>>(
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
    }
  }

  bool _isNewerFirmwareVersion(String current, String available) {
    List<int> components(String value) => value
        .replaceFirst(RegExp('^v'), '')
        .split(RegExp(r'[.\-_]'))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final left = components(current);
    final right = components(available);
    if (left.isEmpty || right.isEmpty) return current != available;
    for (var index = 0; index < max(left.length, right.length); index++) {
      final currentPart = index < left.length ? left[index] : 0;
      final availablePart = index < right.length ? right[index] : 0;
      if (currentPart != availablePart) return availablePart > currentPart;
    }
    return false;
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
          AppDestination.debug => DebugScreen(
              activeConnection: meshState.connection,
              meshStatus: meshState.status,
              statusLine: meshState.statusLine,
              nodeCount: meshState.nodes.length,
              conversationCount: meshState.conversations.length,
              shareLocation: shareLocation,
              deviceModeEnabled: deviceModeEnabled,
              databaseReady: databaseReady,
            ),
          AppDestination.settings => SettingsScreen(
              activeConnection: meshState.connection,
              shareLocation: shareLocation,
              autoReplayReceivedVoice: autoReplayReceivedVoice,
              deviceModeEnabled: deviceModeEnabled,
              bleDevices: meshState.sortedBleDevices,
              selectedBleDevice: selectedBleDevice,
              meshStatus: meshState.status,
              bleAutoConnect: bleAutoConnect,
              statusLine: meshState.statusLine,
              otaAvailableVersion: otaRelease?.version,
              otaCheckInProgress: otaCheckInProgress,
              otaInProgress: meshState.otaInProgress,
              otaProgress: meshState.otaProgress,
              otaMessage: otaMessage,
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
              onCheckForOtaUpdate: _checkForOtaUpdate,
              onInstallOtaUpdate: _installOtaUpdate,
              onAbortOta: session.abortOta,
              onSaveAppSettings: _saveAppSettings,
              onRegenerateUserKeyPair: _regenerateUserKeyPair,
              onSaveDeviceSettings: _saveDeviceSettings,
              onShareLocationChanged: (value) =>
                  setState(() => shareLocation = value),
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
              onUserNameChanged: (value) => setState(() => userName = value),
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
              onDeviceShareLocationChanged: (value) =>
                  setState(() => deviceShareLocation = value),
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
          home: Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: AppDestination.values.indexOf(destination),
              onDestinationSelected: (index) => setState(() {
                destination = AppDestination.values[index];
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
