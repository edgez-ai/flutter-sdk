import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'conversation_screen.dart';
import 'debug_tab.dart';
import 'device_detail_screen.dart';
import 'example_database.dart';
import 'models.dart';
import 'nodes_tab.dart';
import 'settings_tab.dart';

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

class EdgezExampleApp extends StatefulWidget {
  const EdgezExampleApp({super.key});

  @override
  State<EdgezExampleApp> createState() => _EdgezExampleAppState();
}

class _EdgezExampleAppState extends State<EdgezExampleApp> {
  late final EdgezMeshSession session;
  late final ExampleDatabase database;
  late final EdgezIdentityStore identityStore;
  AppDestination destination = AppDestination.nodes;
  int? selectedNodeNum;
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

  String meshCountry = 'US';
  String meshId = 'edgez';
  String passphrase = '';
  String maxHop = '4';
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

  @override
  void initState() {
    super.initState();
    session = EdgezMeshSession();
    database = ExampleDatabase();
    identityStore = EdgezIdentityStore();
    session.addListener(_persistSessionSnapshot);
    unawaited(_loadIdentity());
    unawaited(_hydrateFromDatabase());
  }

  Future<void> _loadIdentity() async {
    final identity = await identityStore.getOrCreate();
    if (!mounted) return;
    setState(() {
      userIdentity = identity;
      userName = identity.name;
    });
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
    await session.connectBle(deviceId);
  }

  Future<void> _disconnect() async {
    await session.disconnect();
    setState(() => selectedNodeNum = null);
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
    await session.sendDeviceSettings(<String, Object?>{
      'deviceModeEnabled': deviceModeEnabled,
      'meshId': deviceMeshId,
      'shareLocation': deviceShareLocation,
      'userName': deviceUserName,
      'marker': deviceMarker.name,
      'beaconIntervalSeconds': int.tryParse(deviceBeaconIntervalSeconds) ?? 0,
      'maxHop': int.tryParse(deviceMaxHop) ?? 0,
      'latitude': double.tryParse(deviceLatitude),
      'longitude': double.tryParse(deviceLongitude),
      'geoFenceName': deviceGeoFenceName,
      'geoIndex': deviceGeoIndex,
      'uartI2cSensorType': uartI2cSensorType,
      'rs485SensorType': rs485SensorType,
    });
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
    return session.startVoiceRecording();
  }

  Future<void> _stopVoiceMessage(bool send) async {
    final nodeNum = selectedNodeNum;
    if (!send || nodeNum == null) {
      await session.cancelVoiceRecording();
      return;
    }
    await session.stopAndSendVoiceMessage(
      toNode: nodeNum,
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
          AppDestination.nodes => selected == null
              ? NodesScreen(
                  activeConnection: meshState.connection,
                  status: meshState.status,
                  users: meshState.sortedNodes,
                  sensorSamples: meshState.sensorSamples,
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
              statusLine: meshState.statusLine,
              meshCountry: meshCountry,
              meshId: meshId,
              passphrase: passphrase,
              maxHop: maxHop,
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
              onConnectBle: _connectBle,
              onStopBleScan: _stopBleScan,
              onConnectBleDevice: _connectBleDevice,
              onDisconnect: _disconnect,
              onSaveAppSettings: _saveAppSettings,
              onRegenerateUserKeyPair: _regenerateUserKeyPair,
              onSaveDeviceSettings: _saveDeviceSettings,
              onShareLocationChanged: (value) =>
                  setState(() => shareLocation = value),
              onAutoReplayChanged: (value) =>
                  setState(() => autoReplayReceivedVoice = value),
              onDeviceModeChanged: (value) =>
                  setState(() => deviceModeEnabled = value),
              onMeshCountryChanged: (value) =>
                  setState(() => meshCountry = value),
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
                if (destination != AppDestination.nodes) selectedNodeNum = null;
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
}
