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
  late final EdgezMeshSession session;
  AppDestination destination = AppDestination.nodes;
  int? selectedNodeNum;
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
    session = EdgezMeshSession();
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  Future<void> _connectBle() async {
    await session.startBleScan();
  }

  Future<void> _disconnect() async {
    await session.disconnect();
    setState(() => selectedNodeNum = null);
  }

  Future<void> _saveAppSettings() async {
    final parsedMaxHop = int.tryParse(maxHop) ?? 0;
    await session.initializeMesh(
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
    if (selectedNodeNum == node.nodeNum) {
      setState(() => selectedNodeNum = null);
    }
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

  void _sendVoicePlaceholder() {
    final nodeNum = selectedNodeNum;
    if (nodeNum == null) return;
    session.addVoicePlaceholder(toNode: nodeNum);
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
                      onSendVoiceMessage: _sendVoicePlaceholder,
                    )
                  : DeviceDetailScreen(
                      user: selected,
                      samples: const <ExampleSensorSample>[],
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
            ),
          AppDestination.settings => SettingsScreen(
              activeConnection: meshState.connection,
              shareLocation: shareLocation,
              autoReplayReceivedVoice: autoReplayReceivedVoice,
              deviceModeEnabled: deviceModeEnabled,
              statusLine: meshState.statusLine,
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
