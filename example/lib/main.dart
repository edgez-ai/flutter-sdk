import 'dart:async';
import 'dart:math' as math;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const EdgezExampleApp());
}

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

enum ExampleDeviceType {
  unspecified('Unspecified', true),
  user('User', true),
  gateway('Gateway', false),
  beacon('Beacon', false),
  sensor('Sensor', false);

  const ExampleDeviceType(this.label, this.opensConversation);

  final String label;
  final bool opensConversation;
}

enum ExampleMarker {
  blue('Blue', Colors.blue),
  red('Red', Colors.red),
  green('Green', Colors.green),
  orange('Orange', Colors.orange),
  purple('Purple', Colors.deepPurple),
  teal('Teal', Colors.teal),
  gray('Gray', Colors.blueGrey);

  const ExampleMarker(this.label, this.color);

  final String label;
  final Color color;

  static ExampleMarker fromId(String id) {
    return ExampleMarker.values.firstWhere(
      (marker) => marker.name == id,
      orElse: () => ExampleMarker.blue,
    );
  }
}

class ExampleGeoFence {
  const ExampleGeoFence({
    required this.name,
    required this.marker,
    required this.alertCondition,
  });

  final String name;
  final ExampleMarker marker;
  final String alertCondition;
}

class ExampleSensorData {
  const ExampleSensorData({
    this.latitude,
    this.longitude,
    this.altitude,
    this.temperature,
    this.humidity,
    this.pressure,
    this.vibrationAverage,
  });

  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? temperature;
  final double? humidity;
  final double? pressure;
  final double? vibrationAverage;

  bool get hasAnyValue {
    return latitude != null ||
        longitude != null ||
        altitude != null ||
        temperature != null ||
        humidity != null ||
        pressure != null ||
        vibrationAverage != null;
  }
}

class ExampleSensorSample {
  const ExampleSensorSample({
    required this.timestampMs,
    required this.data,
  });

  final int timestampMs;
  final ExampleSensorData data;
}

class ExampleNode {
  const ExampleNode({
    required this.meshNode,
    required this.deviceType,
    required this.hasPublicKey,
    this.geoFence,
    this.geoIndex = 0,
    this.samples = const <ExampleSensorSample>[],
  });

  final EdgezMeshNode meshNode;
  final ExampleDeviceType deviceType;
  final bool hasPublicKey;
  final ExampleGeoFence? geoFence;
  final int geoIndex;
  final List<ExampleSensorSample> samples;

  int get nodeNum => meshNode.nodeNum;
  String get displayName => meshNode.displayName;
  String get nodeId => meshNode.nodeId;
  String get userId =>
      meshNode.userUuid.isNotEmpty ? meshNode.userUuid : nodeNum.toString();
  String get route => meshNode.route;
  bool get sleeping => meshNode.sleeping;
  ExampleMarker get marker => ExampleMarker.fromId(meshNode.marker);

  bool get hasLocation =>
      meshNode.latitude != null && meshNode.longitude != null;
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
              deviceType: _deviceTypeFromLabel(node.deviceType),
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

class NodesScreen extends StatelessWidget {
  const NodesScreen({
    required this.activeConnection,
    required this.status,
    required this.users,
    required this.onRemoveNode,
    required this.onOpenNode,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? status;
  final List<ExampleNode> users;
  final ValueChanged<ExampleNode> onRemoveNode;
  final ValueChanged<ExampleNode> onOpenNode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  child: Text('Nodes',
                      style: Theme.of(context).textTheme.headlineMedium)),
              HaLowMeshStatusIcon(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Interface: ${activeConnection.name.toUpperCase()}'),
          const SizedBox(height: 16),
          Text('Users / Nodes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (users.isEmpty) const Text('No HaLow users seen yet'),
          for (final user in users) ...<Widget>[
            Dismissible(
              key: ValueKey<int>(user.nodeNum),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text('Delete',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              onDismissed: (_) => onRemoveNode(user),
              child: NodeCard(user: user, onTap: () => onOpenNode(user)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class HaLowMeshStatusIcon extends StatelessWidget {
  const HaLowMeshStatusIcon({required this.status, super.key});

  final EdgezMeshStatus? status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      null => colorScheme.outline,
      final value when !value.supported => colorScheme.error,
      final value when value.isUsable => colorScheme.primary,
      _ => colorScheme.tertiary,
    };
    return Icon(Icons.hub, color: color);
  }
}

class NodeCard extends StatelessWidget {
  const NodeCard({required this.user, required this.onTap, super.key});

  final ExampleNode user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = user.marker.color;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(user.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: color)),
                        Text('Node ${user.nodeId}'),
                        Text('User ${user.userId}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Type ${user.deviceType.label}',
                            style: Theme.of(context).textTheme.bodySmall),
                        if (user.geoFence != null)
                          Text('Geofence ${user.geoFence!.name}',
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (user.sleeping)
                        Text('Sleeping',
                            style: Theme.of(context).textTheme.labelLarge),
                      Text(
                          'Last seen ${formatLastSeenAge(user.meshNode.lastSeenMs)}',
                          style: Theme.of(context).textTheme.labelLarge),
                      if (user.hasLocation)
                        Icon(Icons.location_on, color: color),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: <Widget>[
                  Text(user.displayName.split(' ').first),
                  Text(user.route),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.activeConnection,
    required this.user,
    required this.messages,
    required this.onBack,
    required this.onSendMessage,
    required this.onSendVoiceMessage,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final ExampleNode user;
  final List<EdgezConversationMessage> messages;
  final VoidCallback onBack;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onSendVoiceMessage;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController controller = TextEditingController();
  String status = '';
  bool recording = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.activeConnection != EdgezConnectionType.none &&
        widget.user.hasPublicKey &&
        controller.text.trim().isNotEmpty;
    final canSendVoice = widget.activeConnection != EdgezConnectionType.none;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextButton(onPressed: widget.onBack, child: const Text('Back')),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (widget.user.hasLocation)
                      Icon(Icons.location_on, color: widget.user.marker.color),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(widget.user.displayName,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('Node ${widget.user.nodeId}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('User ${widget.user.userId}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Marker ${widget.user.marker.label}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Type ${widget.user.deviceType.label}',
                            style: Theme.of(context).textTheme.bodySmall),
                        if (widget.user.geoFence != null)
                          Text('Geofence ${widget.user.geoFence!.name}',
                              style: Theme.of(context).textTheme.bodySmall),
                        if (widget.user.sleeping)
                          Text('Sleeping',
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.user.hasPublicKey
                    ? 'Encrypted with ECDH + AES-GCM'
                    : "Waiting for this user's public key",
                style: TextStyle(
                    color: widget.user.hasPublicKey
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: <Widget>[
                  if (widget.messages.isEmpty)
                    const Center(child: Text('No messages yet')),
                  for (final message in widget.messages)
                    ConversationBubble(message: message),
                ],
              ),
            ),
            if (status.isNotEmpty)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(status,
                      style: Theme.of(context).textTheme.bodySmall)),
            if (recording)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                      child: Text('Recording',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer))),
                ),
              ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Message', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canSend
                      ? () {
                          final text = controller.text.trim();
                          widget.onSendMessage(text);
                          controller.clear();
                          setState(() => status = 'Sent');
                        }
                      : null,
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onLongPressStart:
                  canSendVoice ? (_) => setState(() => recording = true) : null,
              onLongPressEnd: canSendVoice
                  ? (_) {
                      setState(() {
                        recording = false;
                        status = 'Voice sent';
                      });
                      widget.onSendVoiceMessage();
                    }
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: recording
                      ? Theme.of(context).colorScheme.error
                      : canSendVoice
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recording
                      ? 'Recording'
                      : canSendVoice
                          ? 'Hold to Talk'
                          : 'Connect to send voice',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: recording || canSendVoice
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationBubble extends StatelessWidget {
  const ConversationBubble({required this.message, super.key});

  final EdgezConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final isDelivered = message.status == 'Delivered';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: mine
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(message.text),
              if (message.status.isNotEmpty)
                Text(
                  isDelivered ? 'Delivered' : message.status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDelivered ? const Color(0xFF16803C) : null),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({
    required this.user,
    required this.samples,
    required this.onBack,
    super.key,
  });

  final ExampleNode user;
  final List<ExampleSensorSample> samples;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final latest = samples.lastOrNull?.data;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextButton(onPressed: onBack, child: const Text('Back')),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('Conversation · ${user.deviceType.label}',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(user.displayName),
                  Text('Node ${user.nodeId}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          DeviceSummaryCard(user: user),
          const SizedBox(height: 12),
          GeoFenceCard(geoFence: user.geoFence, geoIndex: user.geoIndex),
          const SizedBox(height: 12),
          SensorLatestCard(
              data: latest, timestampMs: samples.lastOrNull?.timestampMs),
          const SizedBox(height: 12),
          SensorChartCard(samples: samples),
        ],
      ),
    );
  }
}

class DeviceSummaryCard extends StatelessWidget {
  const DeviceSummaryCard({required this.user, super.key});

  final ExampleNode user;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Device',
      children: <Widget>[
        Text('Type ${user.deviceType.label}'),
        Text('Marker ${user.marker.label}'),
        Text('User ${user.userId}',
            style: Theme.of(context).textTheme.bodySmall),
        if (user.sleeping)
          Text('Sleeping', style: Theme.of(context).textTheme.bodySmall),
        if (user.hasLocation)
          Text(
              'Location ${formatCoordinate(user.meshNode.latitude)}, ${formatCoordinate(user.meshNode.longitude)}'),
      ],
    );
  }
}

class GeoFenceCard extends StatelessWidget {
  const GeoFenceCard(
      {required this.geoFence, required this.geoIndex, super.key});

  final ExampleGeoFence? geoFence;
  final int geoIndex;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Geo fence',
      children: geoFence == null
          ? const <Widget>[Text('None')]
          : <Widget>[
              Text(geoFence!.name),
              Text('${geoFence!.marker.label} · ${geoFence!.alertCondition}',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('Index $geoIndex',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
    );
  }
}

class SensorLatestCard extends StatelessWidget {
  const SensorLatestCard(
      {required this.data, required this.timestampMs, super.key});

  final ExampleSensorData? data;
  final int? timestampMs;

  @override
  Widget build(BuildContext context) {
    final current = data;
    return InfoCard(
      title: 'Sensor',
      children: current == null || !current.hasAnyValue
          ? const <Widget>[Text('No sensor data received yet')]
          : <Widget>[
              SensorValueRow(
                  label: 'Temperature', value: current.temperature, unit: 'C'),
              SensorValueRow(
                  label: 'Humidity', value: current.humidity, unit: '%'),
              SensorValueRow(
                  label: 'Pressure', value: current.pressure, unit: 'hPa'),
              SensorValueRow(
                  label: 'Pass-by score',
                  value: current.vibrationAverage,
                  unit: ''),
              SensorValueRow(
                  label: 'Altitude', value: current.altitude, unit: 'm'),
              if (current.latitude != null && current.longitude != null)
                Text(
                    'Position ${formatCoordinate(current.latitude)}, ${formatCoordinate(current.longitude)}'),
              if (timestampMs != null)
                Text('Updated ${formatLastSeenAge(timestampMs!)}',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
    );
  }
}

class SensorValueRow extends StatelessWidget {
  const SensorValueRow(
      {required this.label,
      required this.value,
      required this.unit,
      super.key});

  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label),
        Text(unit.isEmpty
            ? formatSensorValue(value!)
            : '${formatSensorValue(value!)} $unit'),
      ],
    );
  }
}

class SensorChartCard extends StatelessWidget {
  const SensorChartCard({required this.samples, super.key});

  final List<ExampleSensorSample> samples;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Sensor time series',
      children: samples.isEmpty
          ? const <Widget>[Text('No chartable sensor values in the last hour')]
          : <Widget>[
              SizedBox(
                  height: 160,
                  child: CustomPaint(
                      painter: SensorChartPainter(
                          samples, Theme.of(context).colorScheme))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  LegendDot(
                      color: Theme.of(context).colorScheme.primary,
                      label: 'Temperature C'),
                  LegendDot(
                      color: Theme.of(context).colorScheme.secondary,
                      label: 'Humidity %'),
                  LegendDot(
                      color: Theme.of(context).colorScheme.tertiary,
                      label: 'Pressure hPa'),
                  LegendDot(
                      color: Theme.of(context).colorScheme.outline,
                      label: 'Pass-by score'),
                ],
              ),
            ],
    );
  }
}

class SensorChartPainter extends CustomPainter {
  SensorChartPainter(this.samples, this.colors);

  final List<ExampleSensorSample> samples;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final border = Paint()
      ..color = colors.outlineVariant
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, border);
    final minTime = samples.first.timestampMs.toDouble();
    final maxTime = samples.last.timestampMs.toDouble();
    final values = samples.expand((sample) sync* {
      if (sample.data.temperature != null) yield sample.data.temperature!;
      if (sample.data.humidity != null) yield sample.data.humidity!;
      if (sample.data.pressure != null) yield sample.data.pressure! / 10;
      if (sample.data.vibrationAverage != null) {
        yield sample.data.vibrationAverage! * 20;
      }
    }).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    void drawSeries(
        Color color, double? Function(ExampleSensorSample sample) read) {
      final points = samples
          .map((sample) {
            final raw = read(sample);
            if (raw == null) return null;
            final x = maxTime == minTime
                ? 0.0
                : ((sample.timestampMs - minTime) / (maxTime - minTime)) *
                    size.width;
            final y = size.height -
                ((raw - minValue) /
                        ((maxValue - minValue).abs() < 0.001
                            ? 1
                            : maxValue - minValue)) *
                    size.height;
            return Offset(x, y);
          })
          .whereType<Offset>()
          .toList();
      if (points.length < 2) return;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      paint.color = color;
      canvas.drawPath(path, paint);
    }

    drawSeries(colors.primary, (sample) => sample.data.temperature);
    drawSeries(colors.secondary, (sample) => sample.data.humidity);
    drawSeries(
        colors.tertiary,
        (sample) =>
            sample.data.pressure == null ? null : sample.data.pressure! / 10);
    drawSeries(
        colors.outline,
        (sample) => sample.data.vibrationAverage == null
            ? null
            : sample.data.vibrationAverage! * 20);
  }

  @override
  bool shouldRepaint(covariant SensorChartPainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.colors != colors;
}

class LegendDot extends StatelessWidget {
  const LegendDot({required this.color, required this.label, super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.activeConnection,
    required this.shareLocation,
    required this.autoReplayReceivedVoice,
    required this.deviceModeEnabled,
    required this.statusLine,
    required this.meshCountry,
    required this.meshId,
    required this.passphrase,
    required this.maxHop,
    required this.beaconIntervalSeconds,
    required this.userName,
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
    required this.onConnectBle,
    required this.onDisconnect,
    required this.onSaveAppSettings,
    required this.onSaveDeviceSettings,
    required this.onShareLocationChanged,
    required this.onAutoReplayChanged,
    required this.onDeviceModeChanged,
    required this.onMeshCountryChanged,
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
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final bool shareLocation;
  final bool autoReplayReceivedVoice;
  final bool deviceModeEnabled;
  final String statusLine;
  final String meshCountry;
  final String meshId;
  final String passphrase;
  final String maxHop;
  final String beaconIntervalSeconds;
  final String userName;
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
  final VoidCallback onConnectBle;
  final VoidCallback onDisconnect;
  final FutureOr<void> Function() onSaveAppSettings;
  final FutureOr<void> Function() onSaveDeviceSettings;
  final ValueChanged<bool> onShareLocationChanged;
  final ValueChanged<bool> onAutoReplayChanged;
  final ValueChanged<bool> onDeviceModeChanged;
  final ValueChanged<String> onMeshCountryChanged;
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Connection',
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
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'App mesh settings',
            children: <Widget>[
              DropdownSetting<String>(
                  label: 'Country',
                  value: meshCountry,
                  values: const <String>['US', 'JP', 'EU'],
                  titleFor: (value) => value,
                  onChanged: onMeshCountryChanged),
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
            title: 'Device mode settings',
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Device mode'),
                value: deviceModeEnabled,
                onChanged: onDeviceModeChanged,
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
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                    onPressed: () =>
                        unawaited(Future<void>.value(onSaveDeviceSettings())),
                    child: const Text('Save device settings')),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
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

class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class DebugScreen extends StatelessWidget {
  const DebugScreen({
    required this.activeConnection,
    required this.meshStatus,
    required this.statusLine,
    required this.nodeCount,
    required this.conversationCount,
    required this.shareLocation,
    required this.deviceModeEnabled,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? meshStatus;
  final String statusLine;
  final int nodeCount;
  final int conversationCount;
  final bool shareLocation;
  final bool deviceModeEnabled;

  @override
  Widget build(BuildContext context) {
    final status = meshStatus;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Debug',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              HaLowMeshStatusIcon(status: status),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Transport',
            children: <Widget>[
              DebugValue(
                  label: 'Active connection',
                  value: activeConnection.name.toUpperCase()),
              DebugValue(
                  label: 'Status',
                  value: statusLine.isEmpty ? 'No status' : statusLine),
              DebugValue(label: 'Known nodes', value: nodeCount.toString()),
              DebugValue(
                  label: 'Conversations', value: conversationCount.toString()),
              DebugValue(
                  label: 'Share location',
                  value: shareLocation ? 'Enabled' : 'Disabled'),
              DebugValue(
                  label: 'Device mode',
                  value: deviceModeEnabled ? 'Enabled' : 'Disabled'),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'HaLow mesh',
            children: status == null
                ? const <Widget>[Text('No HaLow status received yet')]
                : <Widget>[
                    DebugValue(
                        label: 'Supported', value: status.supported.toString()),
                    DebugValue(
                        label: 'Initialized',
                        value: status.stackInitialized.toString()),
                    DebugValue(
                        label: 'Mesh mode', value: status.meshMode.toString()),
                    DebugValue(
                        label: 'Link up', value: status.linkUp.toString()),
                    DebugValue(
                        label: 'Route ready',
                        value: status.routeReady.toString()),
                    DebugValue(
                        label: 'Ready for report',
                        value: status.readyForReport.toString()),
                    DebugValue(
                        label: 'Mesh ID',
                        value: status.meshId.isEmpty ? 'none' : status.meshId),
                    DebugValue(
                        label: 'IP',
                        value: status.ipAddress.isEmpty
                            ? 'none'
                            : status.ipAddress),
                    DebugValue(
                        label: 'Gateway',
                        value:
                            status.gateway.isEmpty ? 'none' : status.gateway),
                    DebugValue(
                        label: 'MAC',
                        value: status.macAddress == 0
                            ? 'none'
                            : status.macAddress.toRadixString(16)),
                  ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'SDK events',
            children: <Widget>[
              Text(
                statusLine.isEmpty
                    ? 'Events from the BLE SDK will appear here as status text.'
                    : statusLine,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DebugValue extends StatelessWidget {
  const DebugValue({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

ExampleDeviceType _deviceTypeFromLabel(String label) {
  final normalized = label.toLowerCase();
  return ExampleDeviceType.values.firstWhere(
    (type) => type.label.toLowerCase() == normalized || type.name == normalized,
    orElse: () => ExampleDeviceType.unspecified,
  );
}

String formatLastSeenAge(int lastSeenMs) {
  if (lastSeenMs <= 0) return 'unknown';
  final elapsed = DateTime.now().millisecondsSinceEpoch - lastSeenMs;
  final seconds = math.max(0, elapsed ~/ 1000);
  if (seconds < 60) return 'just now';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}min';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}hour';
  final days = hours ~/ 24;
  if (days < 7) return '${days}day';
  final weeks = days ~/ 7;
  if (days < 30) return '${weeks}week';
  final months = days ~/ 30;
  if (days < 365) return '${months}month';
  final years = days ~/ 365;
  return '${years}year';
}

String formatCoordinate(double? value) {
  if (value == null) return 'unknown';
  return value.toStringAsFixed(5);
}

String formatSensorValue(double value) {
  return value.abs() >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

extension LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
