import 'dart:async';
import 'dart:math' as math;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'conversation_screen.dart';
import 'debug_tab.dart';
import 'device_detail_screen.dart';
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
  final EdgezMeshSdk sdk = EdgezMeshSdk();
  final Map<int, ExampleNode> nodes = <int, ExampleNode>{};
  final Map<int, List<EdgezConversationMessage>> conversations =
      <int, List<EdgezConversationMessage>>{};

  StreamSubscription<EdgezMeshEvent>? subscription;
  AppDestination destination = AppDestination.nodes;
  EdgezConnectionType connection = EdgezConnectionType.none;
  EdgezMeshStatus? meshStatus;
  ExampleNode? selectedNode;
  String statusLine = 'Connect with BLE, then save mesh settings.';
  bool shareLocation = false;
  bool autoReplayReceivedVoice = false;
  bool deviceModeEnabled = false;

  String meshCountry = 'EU';
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
    subscription = sdk.events.listen(_handleEvent);
    _seedExampleNodes();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  void _handleEvent(EdgezMeshEvent event) {
    setState(() {
      switch (event.type) {
        case EdgezMeshEventType.connection:
          connection = event.connection;
        case EdgezMeshEventType.status:
          meshStatus = event.status;
        case EdgezMeshEventType.node:
          final node = event.node;
          if (node != null) {
            nodes[node.nodeNum] = ExampleNode(
              meshNode: node,
              deviceType: deviceTypeFromLabel(node.deviceType),
              hasPublicKey: true,
              geoFence: node.geoFenceName.isEmpty
                  ? null
                  : ExampleGeoFence(
                      name: node.geoFenceName,
                      marker: ExampleMarker.fromId(node.marker),
                      alertCondition: 'Enter',
                    ),
              geoIndex: node.geoIndex,
            );
          }
        case EdgezMeshEventType.message:
          final message = event.message;
          if (message != null) {
            conversations[message.nodeNum] = <EdgezConversationMessage>[
              ...(conversations[message.nodeNum] ??
                  const <EdgezConversationMessage>[]),
              message,
            ];
          }
        case EdgezMeshEventType.log:
          statusLine = event.log;
      }
    });
  }

  Future<void> _connectBle() async {
    await sdk.startBleScan();
    setState(() {
      connection = EdgezConnectionType.ble;
      statusLine = 'BLE scan requested';
    });
  }

  Future<void> _disconnect() async {
    await sdk.disconnect();
    setState(() {
      connection = EdgezConnectionType.none;
      meshStatus = null;
      statusLine = 'Disconnected';
    });
  }

  Future<void> _saveAppSettings() async {
    final parsedMaxHop = int.tryParse(maxHop) ?? 0;
    await sdk.initializeMesh(
      EdgezMeshConfig(
        countryCode: meshCountry,
        meshId: meshId.trim(),
        passphrase: passphrase,
        maxHop: parsedMaxHop,
        identity: EdgezUserIdentity(
          userIdHigh: 0,
          userIdLow: 1,
          name: userName.trim().isEmpty ? 'Flutter Demo' : userName.trim(),
          publicKey: const <int>[],
        ),
      ),
    );
    setState(() => statusLine = 'Settings saved');
  }

  Future<void> _saveDeviceSettings() async {
    setState(() => statusLine = 'Device settings saved');
    await sdk.sendDeviceSettings(<String, Object?>{
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

  void _openNode(ExampleNode node) {
    setState(() => selectedNode = node);
  }

  void _removeNode(ExampleNode node) {
    setState(() {
      nodes.remove(node.nodeNum);
      conversations.remove(node.nodeNum);
      if (selectedNode?.nodeNum == node.nodeNum) selectedNode = null;
    });
  }

  void _sendMessage(String text) {
    final node = selectedNode;
    if (node == null) return;
    final message = EdgezConversationMessage(
      nodeNum: node.nodeNum,
      text: text,
      mine: true,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      status: 'Sent via ${connection.name.toUpperCase()}',
    );
    setState(() {
      conversations[node.nodeNum] = <EdgezConversationMessage>[
        ...(conversations[node.nodeNum] ?? const <EdgezConversationMessage>[]),
        message,
      ];
      statusLine = 'Message queued';
    });
    unawaited(sdk.sendTextMessage(
        toNode: node.nodeNum, text: text, maxHop: int.tryParse(maxHop) ?? 0));
  }

  void _sendVoicePlaceholder() {
    final node = selectedNode;
    if (node == null) return;
    final message = EdgezConversationMessage(
      nodeNum: node.nodeNum,
      text: 'Voice message',
      mine: true,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      status: 'Voice sent via ${connection.name.toUpperCase()}',
    );
    setState(() {
      conversations[node.nodeNum] = <EdgezConversationMessage>[
        ...(conversations[node.nodeNum] ?? const <EdgezConversationMessage>[]),
        message,
      ];
    });
  }

  void _seedExampleNodes() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const fence = ExampleGeoFence(
      name: 'North ridge',
      marker: ExampleMarker.green,
      alertCondition: 'Enter',
    );
    nodes[0x84f70311aa01] = ExampleNode(
      meshNode: EdgezMeshNode(
        nodeNum: 0x84f70311aa01,
        userUuid: 'a1010000-0000-0000-0000-000000000001',
        displayName: 'Jason',
        route: 'BLE',
        lastSeenMs: now - 45 * 1000,
        marker: ExampleMarker.blue.name,
        latitude: 59.3293,
        longitude: 18.0686,
        deviceType: ExampleDeviceType.user.label,
        geoFenceName: fence.name,
        geoIndex: 1,
      ),
      deviceType: ExampleDeviceType.user,
      hasPublicKey: true,
      geoFence: fence,
      geoIndex: 1,
    );
    nodes[0x84f70311aa02] = ExampleNode(
      meshNode: EdgezMeshNode(
        nodeNum: 0x84f70311aa02,
        userUuid: 'a1010000-0000-0000-0000-000000000002',
        displayName: 'Trail sensor',
        route: 'BLE',
        lastSeenMs: now - 9 * 60 * 1000,
        marker: ExampleMarker.green.name,
        latitude: 59.3310,
        longitude: 18.0710,
        deviceType: ExampleDeviceType.sensor.label,
        geoFenceName: fence.name,
        geoIndex: 2,
        sleeping: true,
      ),
      deviceType: ExampleDeviceType.sensor,
      hasPublicKey: false,
      geoFence: fence,
      geoIndex: 2,
      samples: _demoSensorSamples(now),
    );
    conversations[0x84f70311aa01] = <EdgezConversationMessage>[
      EdgezConversationMessage(
        nodeNum: 0x84f70311aa01,
        text: 'Mesh link is up.',
        mine: false,
        timestampMs: now - 8 * 60 * 1000,
      ),
      EdgezConversationMessage(
        nodeNum: 0x84f70311aa01,
        text: 'Copy.',
        mine: true,
        timestampMs: now - 7 * 60 * 1000,
        status: 'Delivered',
      ),
    ];
  }

  List<ExampleSensorSample> _demoSensorSamples(int now) {
    return List<ExampleSensorSample>.generate(12, (index) {
      final age = (11 - index) * 5 * 60 * 1000;
      return ExampleSensorSample(
        timestampMs: now - age,
        data: ExampleSensorData(
          temperature: 18.0 + math.sin(index / 2) * 2.5,
          humidity: 55 + index * 0.8,
          pressure: 1005 + math.cos(index / 3) * 5,
          vibrationAverage: index.isEven ? 0.2 + index / 20 : 0.1,
          altitude: 42,
          latitude: 59.3310,
          longitude: 18.0710,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedNodes = nodes.values.toList()
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final selected = selectedNode;
    final body = switch (destination) {
      AppDestination.nodes => selected == null
          ? NodesScreen(
              activeConnection: connection,
              status: meshStatus,
              users: sortedNodes,
              onRemoveNode: _removeNode,
              onOpenNode: _openNode,
            )
          : selected.deviceType.opensConversation
              ? ConversationScreen(
                  activeConnection: connection,
                  user: selected,
                  messages: conversations[selected.nodeNum] ??
                      const <EdgezConversationMessage>[],
                  onBack: () => setState(() => selectedNode = null),
                  onSendMessage: _sendMessage,
                  onSendVoiceMessage: _sendVoicePlaceholder,
                )
              : DeviceDetailScreen(
                  user: selected,
                  samples: selected.samples,
                  onBack: () => setState(() => selectedNode = null),
                ),
      AppDestination.debug => DebugScreen(
          activeConnection: connection,
          meshStatus: meshStatus,
          statusLine: statusLine,
          nodeCount: nodes.length,
          conversationCount: conversations.length,
          shareLocation: shareLocation,
          deviceModeEnabled: deviceModeEnabled,
        ),
      AppDestination.settings => SettingsScreen(
          activeConnection: connection,
          shareLocation: shareLocation,
          autoReplayReceivedVoice: autoReplayReceivedVoice,
          deviceModeEnabled: deviceModeEnabled,
          statusLine: statusLine,
          meshCountry: meshCountry,
          meshId: meshId,
          passphrase: passphrase,
          maxHop: maxHop,
          beaconIntervalSeconds: beaconIntervalSeconds,
          userName: userName,
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
          onDisconnect: _disconnect,
          onSaveAppSettings: _saveAppSettings,
          onSaveDeviceSettings: _saveDeviceSettings,
          onShareLocationChanged: (value) =>
              setState(() => shareLocation = value),
          onAutoReplayChanged: (value) =>
              setState(() => autoReplayReceivedVoice = value),
          onDeviceModeChanged: (value) =>
              setState(() => deviceModeEnabled = value),
          onMeshCountryChanged: (value) => setState(() => meshCountry = value),
          onMeshIdChanged: (value) => setState(() => meshId = value),
          onPassphraseChanged: (value) => setState(() => passphrase = value),
          onMaxHopChanged: (value) => setState(() => maxHop = value),
          onBeaconIntervalChanged: (value) =>
              setState(() => beaconIntervalSeconds = value),
          onUserNameChanged: (value) => setState(() => userName = value),
          onUserMarkerChanged: (value) => setState(() => userMarker = value),
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
            if (destination != AppDestination.nodes) selectedNode = null;
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
  }
}

ExampleDeviceType deviceTypeFromLabel(String label) {
  final normalized = label.toLowerCase();
  return ExampleDeviceType.values.firstWhere(
    (type) => type.label.toLowerCase() == normalized || type.name == normalized,
    orElse: () => ExampleDeviceType.unspecified,
  );
}
