import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'edgez_mesh_sdk.dart';
import 'models.dart';
import 'proto/edgez_mesh.pb.dart' as proto;

class EdgezMeshState {
  EdgezMeshState({
    required this.connection,
    required this.status,
    required Map<String, EdgezBleDevice> bleDevices,
    required Map<int, EdgezMeshNode> nodes,
    required Map<int, List<EdgezSensorSample>> sensorSamples,
    required Map<int, List<EdgezConversationMessage>> conversations,
    required this.statusLine,
  })  : bleDevices = Map<String, EdgezBleDevice>.unmodifiable(bleDevices),
        nodes = Map<int, EdgezMeshNode>.unmodifiable(nodes),
        sensorSamples = _freezeSensorSamples(sensorSamples),
        conversations = _freezeConversations(conversations);

  factory EdgezMeshState.initial() {
    return EdgezMeshState(
      connection: EdgezConnectionType.none,
      status: null,
      bleDevices: const <String, EdgezBleDevice>{},
      nodes: const <int, EdgezMeshNode>{},
      sensorSamples: const <int, List<EdgezSensorSample>>{},
      conversations: const <int, List<EdgezConversationMessage>>{},
      statusLine: 'Connect with BLE, then save mesh settings.',
    );
  }

  final EdgezConnectionType connection;
  final EdgezMeshStatus? status;
  final Map<String, EdgezBleDevice> bleDevices;
  final Map<int, EdgezMeshNode> nodes;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final Map<int, List<EdgezConversationMessage>> conversations;
  final String statusLine;

  List<EdgezMeshNode> get sortedNodes {
    final sorted = nodes.values.toList()
      ..sort((a, b) => a.resolvedDisplayName
          .toLowerCase()
          .compareTo(b.resolvedDisplayName.toLowerCase()));
    return List<EdgezMeshNode>.unmodifiable(sorted);
  }

  List<EdgezBleDevice> get sortedBleDevices {
    final sorted = bleDevices.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return List<EdgezBleDevice>.unmodifiable(sorted);
  }

  EdgezMeshState copyWith({
    EdgezConnectionType? connection,
    EdgezMeshStatus? status,
    bool clearStatus = false,
    Map<String, EdgezBleDevice>? bleDevices,
    Map<int, EdgezMeshNode>? nodes,
    Map<int, List<EdgezSensorSample>>? sensorSamples,
    Map<int, List<EdgezConversationMessage>>? conversations,
    String? statusLine,
  }) {
    return EdgezMeshState(
      connection: connection ?? this.connection,
      status: clearStatus ? null : status ?? this.status,
      bleDevices: bleDevices ?? this.bleDevices,
      nodes: nodes ?? this.nodes,
      sensorSamples: sensorSamples ?? this.sensorSamples,
      conversations: conversations ?? this.conversations,
      statusLine: statusLine ?? this.statusLine,
    );
  }

  static Map<int, List<EdgezConversationMessage>> _freezeConversations(
    Map<int, List<EdgezConversationMessage>> source,
  ) {
    return Map<int, List<EdgezConversationMessage>>.unmodifiable(
      source.map(
        (nodeNum, messages) => MapEntry(
          nodeNum,
          List<EdgezConversationMessage>.unmodifiable(messages),
        ),
      ),
    );
  }

  static Map<int, List<EdgezSensorSample>> _freezeSensorSamples(
    Map<int, List<EdgezSensorSample>> source,
  ) {
    return Map<int, List<EdgezSensorSample>>.unmodifiable(
      source.map(
        (nodeNum, samples) => MapEntry(
          nodeNum,
          List<EdgezSensorSample>.unmodifiable(samples),
        ),
      ),
    );
  }
}

class EdgezMeshSession extends ChangeNotifier {
  EdgezMeshSession({EdgezMeshSdk? sdk}) : sdk = sdk ?? EdgezMeshSdk() {
    _subscription = this.sdk.events.listen(_handleEvent);
  }

  final EdgezMeshSdk sdk;
  late final StreamSubscription<EdgezMeshEvent> _subscription;
  EdgezMeshState _state = EdgezMeshState.initial();

  EdgezMeshState get state => _state;

  void restoreCachedMeshData({
    required Map<int, EdgezMeshNode> nodes,
    required Map<int, List<EdgezConversationMessage>> conversations,
    Map<int, List<EdgezSensorSample>> sensorSamples =
        const <int, List<EdgezSensorSample>>{},
  }) {
    _setState(
      _state.copyWith(
        nodes: nodes,
        sensorSamples: sensorSamples,
        conversations: conversations,
        statusLine: nodes.isEmpty
            ? _state.statusLine
            : 'Loaded ${nodes.length} saved node(s)',
      ),
    );
  }

  Future<void> startBleScan() async {
    try {
      await sdk.startBleScan();
      _setState(
        _state.copyWith(
          bleDevices: const <String, EdgezBleDevice>{},
          statusLine: 'BLE scan requested',
        ),
      );
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'BLE scan failed: $error'));
    }
  }

  Future<void> stopBleScan() async {
    try {
      await sdk.stopBleScan();
      _setState(_state.copyWith(statusLine: 'BLE scan stopped'));
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'BLE stop scan failed: $error'));
    }
  }

  Future<void> connectBle(String deviceId) async {
    try {
      await sdk.connectBle(deviceId);
      _setState(
        _state.copyWith(
          connection: EdgezConnectionType.ble,
          statusLine:
              'Connecting BLE ${_state.bleDevices[deviceId]?.label ?? deviceId}',
        ),
      );
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'BLE connect failed: $error'));
    }
  }

  Future<void> disconnect() async {
    await sdk.disconnect();
    _setState(
      EdgezMeshState.initial().copyWith(statusLine: 'Disconnected'),
    );
  }

  Future<void> initializeMesh(EdgezMeshConfig config) async {
    try {
      await sdk.initializeMesh(config);
      _setState(_state.copyWith(statusLine: 'User mesh settings sent'));
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Save settings failed: $error'));
    }
  }

  Future<void> sendDeviceSettings(Map<String, Object?> settings) async {
    _setState(_state.copyWith(statusLine: 'Device settings saved'));
    await sdk.sendDeviceSettings(settings);
  }

  Future<void> sendTextMessage({
    required int toNode,
    required String text,
    int maxHop = 0,
  }) async {
    if (!(_state.nodes[toNode]?.opensConversation ?? false)) {
      _setState(
        _state.copyWith(
          statusLine: 'Only user nodes can receive conversation messages',
        ),
      );
      return;
    }
    _appendMessage(
      EdgezConversationMessage(
        nodeNum: toNode,
        text: text,
        mine: true,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        status: 'Sent via ${_state.connection.name.toUpperCase()}',
      ),
      statusLine: 'Message queued',
    );
    await sdk.sendTextMessage(toNode: toNode, text: text, maxHop: maxHop);
  }

  void addVoicePlaceholder({required int toNode}) {
    if (!(_state.nodes[toNode]?.opensConversation ?? false)) {
      _setState(
        _state.copyWith(
          statusLine: 'Only user nodes can receive voice messages',
        ),
      );
      return;
    }
    _appendMessage(
      EdgezConversationMessage(
        nodeNum: toNode,
        text: 'Voice message',
        mine: true,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        status: 'Voice sent via ${_state.connection.name.toUpperCase()}',
      ),
    );
  }

  void removeNode(int nodeNum) {
    final nodes = Map<int, EdgezMeshNode>.of(_state.nodes)..remove(nodeNum);
    final sensorSamples =
        Map<int, List<EdgezSensorSample>>.of(_state.sensorSamples)
          ..remove(nodeNum);
    final conversations =
        Map<int, List<EdgezConversationMessage>>.of(_state.conversations)
          ..remove(nodeNum);
    _setState(
      _state.copyWith(
        nodes: nodes,
        sensorSamples: sensorSamples,
        conversations: conversations,
      ),
    );
  }

  void _handleEvent(EdgezMeshEvent event) {
    switch (event.type) {
      case EdgezMeshEventType.connection:
        _setState(_state.copyWith(connection: event.connection));
      case EdgezMeshEventType.bleDevice:
        final device = event.bleDevice;
        if (device == null || device.id.isEmpty) return;
        final devices = Map<String, EdgezBleDevice>.of(_state.bleDevices);
        devices[device.id] = device;
        _setState(
          _state.copyWith(
            bleDevices: devices,
            statusLine: 'Found ${device.label}',
          ),
        );
      case EdgezMeshEventType.packet:
        _handlePacket(event.packet);
      case EdgezMeshEventType.status:
        _setState(_state.copyWith(status: event.status));
      case EdgezMeshEventType.node:
        final node = event.node;
        if (node == null) return;
        final nodes = Map<int, EdgezMeshNode>.of(_state.nodes);
        final updated = node.mergeDiscovery(nodes[node.nodeNum]);
        nodes[node.nodeNum] = updated;
        _setState(
          _state.copyWith(
            nodes: nodes,
            statusLine: 'Beacon received from ${updated.resolvedDisplayName}',
          ),
        );
      case EdgezMeshEventType.message:
        final message = event.message;
        if (message == null) return;
        final nodes = Map<int, EdgezMeshNode>.of(_state.nodes);
        nodes.putIfAbsent(
          message.nodeNum,
          () => EdgezMeshNode(
            nodeNum: message.nodeNum,
            userUuid: '',
            displayName: 'Node ${message.nodeNum.toRadixString(16)}',
            route: _state.connection.name.toUpperCase(),
            lastSeenMs: message.timestampMs,
            marker: 'blue',
            deviceType: 'User',
          ),
        );
        _appendMessage(
          message,
          nodes: nodes,
          statusLine: 'Conversation message received',
        );
      case EdgezMeshEventType.log:
        _setState(_state.copyWith(statusLine: event.log));
    }
  }

  void _handlePacket(List<int> packetBytes) {
    if (packetBytes.isEmpty) return;
    final packet = _parseNetworkPacket(packetBytes);
    if (packet == null) return;

    if (packet.hasStatus()) {
      _setState(
        _state.copyWith(
          status: EdgezMeshStatus(
            supported: packet.status.supported,
            stackInitialized: packet.status.stackInitialized,
            meshMode: packet.status.meshMode,
            linkUp: packet.status.linkUp,
            routeReady: packet.status.routeReady,
            readyForReport: packet.status.readyForReport,
            meshId: packet.status.meshId,
            ipAddress: packet.status.ipAddr,
            gateway: packet.status.gateway,
            macAddress: packet.status.macAddress.toInt(),
          ),
        ),
      );
    }

    if (!packet.hasBeacon()) return;
    final beacon = _parseBeacon(packet.beacon);
    if (beacon == null) return;
    final nodeNum = packet.from.toInt();
    if (nodeNum == 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final previous = _state.nodes[nodeNum];
    final node = EdgezMeshNode(
      nodeNum: nodeNum,
      userUuid:
          _formatUuid(beacon.userIdHigh.toInt(), beacon.userIdLow.toInt()),
      displayName: _decodeBeaconUserName(beacon.userName),
      route: _state.connection.name.toUpperCase(),
      lastSeenMs: now,
      marker: _markerId(beacon.marker),
      latitude:
          beacon.hasAttitude() && beacon.attitude != 0 ? beacon.attitude : null,
      longitude: beacon.hasLongitude() && beacon.longitude != 0
          ? beacon.longitude
          : null,
      deviceType: _deviceTypeLabel(beacon.deviceType),
      geoFenceName: beacon.hasGeoFence() ? beacon.geoFence.name : '',
      geoIndex: beacon.hasGeoFence() ? beacon.geoFence.geoIndex : 0,
      sleeping: beacon.sleeping,
    ).mergeDiscovery(previous);

    final nodes = Map<int, EdgezMeshNode>.of(_state.nodes)..[nodeNum] = node;
    final sensorSamples =
        Map<int, List<EdgezSensorSample>>.of(_state.sensorSamples);
    final sensorData = _sensorData(beacon);
    if (sensorData != null) {
      sensorSamples[nodeNum] = <EdgezSensorSample>[
        ...(sensorSamples[nodeNum] ?? const <EdgezSensorSample>[]),
        EdgezSensorSample(nodeNum: nodeNum, timestampMs: now, data: sensorData),
      ];
    }

    _setState(
      _state.copyWith(
        nodes: nodes,
        sensorSamples: sensorSamples,
        statusLine: 'Beacon received from ${node.resolvedDisplayName}',
      ),
    );
  }

  proto.NetworkPacket? _parseNetworkPacket(List<int> bytes) {
    try {
      return proto.NetworkPacket.fromBuffer(bytes);
    } catch (_) {
      return null;
    }
  }

  proto.Beacon? _parseBeacon(String value) {
    if (value.isEmpty) return null;
    try {
      return proto.Beacon.fromBuffer(base64Decode(value));
    } catch (_) {
      try {
        return proto.Beacon.fromBuffer(utf8.encode(value));
      } catch (_) {
        return null;
      }
    }
  }

  EdgezSensorData? _sensorData(proto.Beacon beacon) {
    if (!beacon.hasSensorData()) return null;
    final data = EdgezSensorData(
      latitude:
          beacon.sensorData.latitude == 0 ? null : beacon.sensorData.latitude,
      longitude:
          beacon.sensorData.longitude == 0 ? null : beacon.sensorData.longitude,
      altitude:
          beacon.sensorData.altitude == 0 ? null : beacon.sensorData.altitude,
      temperature: beacon.sensorData.temperature == 0
          ? null
          : beacon.sensorData.temperature,
      humidity:
          beacon.sensorData.humidity == 0 ? null : beacon.sensorData.humidity,
      pressure:
          beacon.sensorData.pressure == 0 ? null : beacon.sensorData.pressure,
      vibrationAverage: beacon.sensorData.vibrationAverage == 0
          ? null
          : beacon.sensorData.vibrationAverage,
    );
    return data.hasAnyValue ? data : null;
  }

  String _formatUuid(int high, int low) {
    final highText = high.toRadixString(16).padLeft(16, '0');
    final lowText = low.toRadixString(16).padLeft(16, '0');
    return '${highText.substring(0, 8)}-${highText.substring(8, 12)}-${highText.substring(12, 16)}-'
        '${lowText.substring(0, 4)}-${lowText.substring(4, 16)}';
  }

  String _decodeBeaconUserName(String userName) {
    const separator = '|m=';
    final separatorIndex = userName.lastIndexOf(separator);
    if (separatorIndex < 0) return userName;
    return userName.substring(0, separatorIndex);
  }

  String _markerId(proto.MarkerColor marker) {
    return switch (marker) {
      proto.MarkerColor.MARKER_RED => 'red',
      proto.MarkerColor.MARKER_GREEN => 'green',
      proto.MarkerColor.MARKER_ORANGE => 'orange',
      proto.MarkerColor.MARKER_PURPLE ||
      proto.MarkerColor.MARKER_DEEP_PURPLE =>
        'purple',
      proto.MarkerColor.MARKER_GRAY ||
      proto.MarkerColor.MARKER_BLUE_GRAY =>
        'gray',
      proto.MarkerColor.MARKER_TEAL => 'teal',
      _ => 'blue',
    };
  }

  String _deviceTypeLabel(proto.DeviceType type) {
    return switch (type) {
      proto.DeviceType.DEVICE_TYPE_USER => 'User',
      proto.DeviceType.DEVICE_TYPE_GATEWAY => 'Gateway',
      proto.DeviceType.DEVICE_TYPE_BEACON => 'Beacon',
      proto.DeviceType.DEVICE_TYPE_SENSOR => 'Sensor',
      proto.DeviceType.DEVICE_TYPE_UNKNOWN => 'Unknown',
      _ => 'Unspecified',
    };
  }

  void _appendMessage(
    EdgezConversationMessage message, {
    Map<int, EdgezMeshNode>? nodes,
    String? statusLine,
  }) {
    final conversations =
        Map<int, List<EdgezConversationMessage>>.of(_state.conversations);
    conversations[message.nodeNum] = <EdgezConversationMessage>[
      ...(conversations[message.nodeNum] ?? const <EdgezConversationMessage>[]),
      message,
    ];
    _setState(
      _state.copyWith(
        nodes: nodes,
        conversations: conversations,
        statusLine: statusLine,
      ),
    );
  }

  void _setState(EdgezMeshState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
