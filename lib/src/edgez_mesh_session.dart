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
  EdgezMeshConfig? _lastMeshConfig;
  var _bleReady = false;
  var _initInFlight = false;
  var _beaconSendInFlight = false;
  String? _lastInitKey;
  Timer? _beaconTimer;
  final Map<String, _PendingVoiceMessage> _pendingVoiceMessages =
      <String, _PendingVoiceMessage>{};

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
      _bleReady = false;
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
    _bleReady = false;
    _lastInitKey = null;
    _stopBeaconLoop();
    _setState(
      EdgezMeshState.initial().copyWith(statusLine: 'Disconnected'),
    );
  }

  Future<void> initializeMesh(EdgezMeshConfig config) async {
    _lastMeshConfig = config;
    await _sendInitIfReady(force: true);
  }

  Future<void> sendDeviceSettings(EdgezDeviceSettings settings) async {
    final identity = _lastMeshConfig?.identity;
    try {
      await sdk.sendDeviceSettings(settings: settings, identity: identity);
      _setState(_state.copyWith(statusLine: 'Device settings sent'));
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Device settings failed: $error'));
    }
  }

  Future<void> sendTextMessage({
    required int toNode,
    required String text,
    int maxHop = 0,
  }) async {
    final node = _state.nodes[toNode];
    if (!(node?.opensConversation ?? false)) {
      _setState(
        _state.copyWith(
          statusLine: 'Only user nodes can receive conversation messages',
        ),
      );
      return;
    }
    final pendingUuid =
        'pending-${DateTime.now().microsecondsSinceEpoch}-$toNode';
    _appendMessage(
      EdgezConversationMessage(
        nodeNum: toNode,
        text: text,
        mine: true,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        messageUuid: pendingUuid,
        status: 'Queued',
      ),
      statusLine: 'Message queued',
    );

    final config = _lastMeshConfig;
    final fromNode = _state.status?.macAddress ?? 0;
    if (config == null || fromNode == 0) {
      _replaceMessage(
        pendingUuid,
        status: 'Failed: save settings and wait for mesh status',
        statusLine: 'Save settings and wait for mesh status',
      );
      return;
    }
    try {
      final messageUuid = await sdk.sendTextMessage(
        config: config,
        toNode: node!,
        fromNode: fromNode,
        text: text,
        maxHop: maxHop,
      );
      _replaceMessage(
        pendingUuid,
        messageUuid: messageUuid,
        status: 'Sent via ${_state.connection.name.toUpperCase()}',
        statusLine: 'Message sent',
      );
    } catch (error) {
      _replaceMessage(
        pendingUuid,
        status: 'Failed: $error',
        statusLine: 'Message send failed: $error',
      );
    }
  }

  Future<void> sendVoiceMessage({
    required int toNode,
    required List<int> bytes,
    required int durationMs,
    required int codec,
    int maxHop = 0,
  }) async {
    final node = _state.nodes[toNode];
    if (!(node?.opensConversation ?? false)) {
      _setState(
        _state.copyWith(
          statusLine: 'Only user nodes can receive voice messages',
        ),
      );
      return;
    }
    final pendingUuid =
        'pending-voice-${DateTime.now().microsecondsSinceEpoch}-$toNode';
    _appendMessage(
      EdgezConversationMessage(
        nodeNum: toNode,
        text: 'Voice message',
        mine: true,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        messageUuid: pendingUuid,
        status: 'Queued',
        voiceBytes: bytes,
        voiceCodec: codec,
        durationMs: durationMs,
      ),
      statusLine: 'Voice message queued',
    );
    final config = _lastMeshConfig;
    final fromNode = _state.status?.macAddress ?? 0;
    if (config == null || fromNode == 0) {
      _replaceMessage(
        pendingUuid,
        status: 'Failed: save settings and wait for mesh status',
        statusLine: 'Save settings and wait for mesh status',
      );
      return;
    }
    try {
      final messageUuid = await sdk.sendVoiceMessage(
        config: config,
        toNode: node!,
        fromNode: fromNode,
        bytes: bytes,
        durationMs: durationMs,
        codec: codec,
        maxHop: maxHop,
      );
      _replaceMessage(
        pendingUuid,
        messageUuid: messageUuid,
        status: 'Voice sent via ${_state.connection.name.toUpperCase()}',
        statusLine: 'Voice message sent',
      );
    } catch (error) {
      _replaceMessage(
        pendingUuid,
        status: 'Failed: $error',
        statusLine: 'Voice send failed: $error',
      );
    }
  }

  @Deprecated('Use startVoiceMessage instead.')
  Future<bool> startVoiceRecording() async {
    return startVoiceMessage();
  }

  Future<bool> startVoiceMessage() async {
    try {
      await sdk.startVoiceRecording();
      _setState(_state.copyWith(statusLine: 'Recording voice message'));
      return true;
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Voice recording failed: $error'));
      return false;
    }
  }

  @Deprecated('Use cancelVoiceMessage instead.')
  Future<void> cancelVoiceRecording() async {
    return cancelVoiceMessage();
  }

  Future<void> cancelVoiceMessage() async {
    try {
      await sdk.stopVoiceRecording(send: false);
      _setState(_state.copyWith(statusLine: 'Voice recording cancelled'));
    } catch (error) {
      _setState(
          _state.copyWith(statusLine: 'Voice recording cancel failed: $error'));
    }
  }

  @Deprecated('Use finishVoiceMessage instead.')
  Future<void> stopAndSendVoiceMessage({
    required int toNode,
    int maxHop = 0,
  }) async {
    return finishVoiceMessage(toNode: toNode, send: true, maxHop: maxHop);
  }

  Future<void> finishVoiceMessage({
    required int toNode,
    bool send = true,
    int maxHop = 0,
  }) async {
    if (!send) {
      await cancelVoiceMessage();
      return;
    }
    final recording = await sdk.stopVoiceRecording();
    if (recording == null || recording.bytes.isEmpty) {
      _setState(_state.copyWith(statusLine: 'Voice recording was too short'));
      return;
    }
    await sendVoiceMessage(
      toNode: toNode,
      bytes: recording.bytes,
      durationMs: recording.durationMs,
      codec: recording.codec,
      maxHop: maxHop,
    );
  }

  Future<void> playVoiceMessage(EdgezConversationMessage message) async {
    try {
      await sdk.playVoiceMessage(message);
      _setState(_state.copyWith(statusLine: 'Playing voice message'));
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Voice replay failed: $error'));
    }
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
        if (event.connection == EdgezConnectionType.none) {
          _bleReady = false;
          _lastInitKey = null;
        }
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
      case EdgezMeshEventType.ready:
        _bleReady = true;
        _setState(_state.copyWith(statusLine: 'BLE control service ready'));
        unawaited(_sendInitIfReady());
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

    if (packet.hasDeviceSettings()) {
      _setState(_state.copyWith(statusLine: 'Device settings received'));
    }

    if (packet.hasPayload() ||
        packet.operation == proto.Operation.ACKNOWLEDGE) {
      unawaited(_handleConversationPacket(packet));
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
      publicKey: beacon.userPublicKey,
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

  Future<void> _handleConversationPacket(proto.NetworkPacket packet) async {
    if (packet.operation == proto.Operation.ACKNOWLEDGE) {
      _markMessageDelivered(
        _formatUuid(packet.messageIdHigh.toInt(), packet.messageIdLow.toInt()),
      );
      return;
    }
    if (!packet.hasPayload()) return;
    if (packet.mime != proto.Mime.MIME_TEXT &&
        packet.mime != proto.Mime.MIME_VOICE) {
      return;
    }
    final config = _lastMeshConfig;
    final fromNode = packet.from.toInt();
    final toNode = packet.to.toInt();
    if (config == null || fromNode == 0) return;

    final sender = _state.nodes[fromNode];
    final now = DateTime.now().millisecondsSinceEpoch;
    final messageUuid =
        _formatUuid(packet.messageIdHigh.toInt(), packet.messageIdLow.toInt());
    String? text;
    String status = '';
    _CompletedVoiceMessage? completedVoice;
    if (sender == null) {
      text = 'Unable to decrypt message';
      status = 'Sender public key is missing';
    } else if (packet.mime == proto.Mime.MIME_TEXT) {
      try {
        text = await sdk.decryptTextMessage(
          config: config,
          sender: sender,
          fromNode: fromNode,
          toNode: toNode,
          payload: packet.payload,
        );
      } catch (error) {
        status = error.toString();
        text = 'Unable to decrypt message';
      }
    } else {
      EdgezVoiceChunk? chunk;
      try {
        chunk = await sdk.decryptVoiceChunk(
          config: config,
          sender: sender,
          fromNode: fromNode,
          toNode: toNode,
          payload: packet.payload,
        );
      } catch (error) {
        status = error.toString();
      }
      if (chunk == null) {
        text = 'Unable to decrypt voice message';
      } else {
        completedVoice = _storeVoiceChunk(fromNode, chunk);
        if (completedVoice == null) return;
        text = 'Voice message';
      }
    }

    final nodes = Map<int, EdgezMeshNode>.of(_state.nodes);
    nodes.putIfAbsent(
      fromNode,
      () => EdgezMeshNode(
        nodeNum: fromNode,
        userUuid: _formatUuid(packet.userHigh.toInt(), packet.userLow.toInt()),
        displayName: 'Node ${fromNode.toRadixString(16)}',
        route: _state.connection.name.toUpperCase(),
        lastSeenMs: now,
        marker: 'blue',
        deviceType: 'User',
      ),
    );
    _appendMessage(
      EdgezConversationMessage(
        nodeNum: fromNode,
        text: text ?? 'Voice message',
        mine: false,
        timestampMs: now,
        messageUuid: messageUuid,
        status: status,
        voiceBytes: completedVoice?.bytes ?? const <int>[],
        voiceCodec: completedVoice?.codec ?? 0,
        durationMs: completedVoice?.durationMs ?? 0,
      ),
      nodes: nodes,
      statusLine: 'Conversation message received',
    );

    final localNode = _state.status?.macAddress ?? 0;
    if (localNode != 0 &&
        (packet.messageIdHigh.toInt() != 0 ||
            packet.messageIdLow.toInt() != 0)) {
      unawaited(
        sdk.sendConversationAck(
          config: config,
          fromNode: localNode,
          toNode: fromNode,
          messageIdHigh: packet.messageIdHigh.toInt(),
          messageIdLow: packet.messageIdLow.toInt(),
          maxHop: config.maxHop,
        ),
      );
    }
  }

  _CompletedVoiceMessage? _storeVoiceChunk(int nodeNum, EdgezVoiceChunk chunk) {
    final key = '$nodeNum:${chunk.groupId}';
    final pending = _pendingVoiceMessages.putIfAbsent(
      key,
      () => _PendingVoiceMessage(
        totalChunks: chunk.totalChunks,
        durationMs: chunk.durationMs,
        codec: chunk.codec,
      ),
    );
    pending.put(chunk.index, chunk.audio);
    if (!pending.complete) return null;
    _pendingVoiceMessages.remove(key);
    return pending.completed();
  }

  void _markMessageDelivered(String messageUuid) {
    if (messageUuid.isEmpty) return;
    _replaceMessage(
      messageUuid,
      status: 'Delivered',
      statusLine: 'Message delivered',
      onlyMine: true,
    );
  }

  void _replaceMessage(
    String currentMessageUuid, {
    String? messageUuid,
    String? status,
    String? statusLine,
    bool onlyMine = false,
  }) {
    if (currentMessageUuid.isEmpty) return;
    final conversations =
        Map<int, List<EdgezConversationMessage>>.of(_state.conversations);
    var changed = false;
    for (final entry in conversations.entries) {
      final updated = entry.value.map<EdgezConversationMessage>((message) {
        if ((onlyMine && !message.mine) ||
            message.messageUuid != currentMessageUuid) {
          return message;
        }
        changed = true;
        return EdgezConversationMessage(
          nodeNum: message.nodeNum,
          text: message.text,
          mine: message.mine,
          timestampMs: message.timestampMs,
          messageUuid: messageUuid ?? message.messageUuid,
          status: status ?? message.status,
          voiceBytes: message.voiceBytes,
          voiceCodec: message.voiceCodec,
          durationMs: message.durationMs,
        );
      }).toList(growable: false);
      conversations[entry.key] = updated;
    }
    if (changed) {
      _setState(
        _state.copyWith(
          conversations: conversations,
          statusLine: statusLine,
        ),
      );
    }
  }

  Future<void> _sendInitIfReady({bool force = false}) async {
    final config = _lastMeshConfig;
    if (config == null) {
      _setState(
          _state.copyWith(statusLine: 'Save settings before device init'));
      return;
    }
    if (!_bleReady) {
      _setState(
        _state.copyWith(
          statusLine: _state.connection == EdgezConnectionType.ble
              ? 'Settings saved; waiting for BLE control service'
              : 'Settings saved; connect BLE to initialize device',
        ),
      );
      return;
    }
    final initKey = _initKey(config);
    if (!force && _lastInitKey == initKey) return;
    if (_initInFlight) return;

    _initInFlight = true;
    try {
      await sdk.initializeMesh(config);
      _lastInitKey = initKey;
      _setState(_state.copyWith(statusLine: 'User mesh settings sent'));
      await sdk.requestDeviceSettings(identity: config.identity);
      _setState(_state.copyWith(statusLine: 'Device settings requested'));
      _startBeaconLoop();
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Device init failed: $error'));
    } finally {
      _initInFlight = false;
    }
  }

  void _startBeaconLoop() {
    _stopBeaconLoop();
    final config = _lastMeshConfig;
    if (config == null || !_bleReady) return;
    unawaited(_sendBeaconIfReady());
    _beaconTimer = Timer.periodic(
      Duration(seconds: config.beacon.normalizedIntervalSeconds),
      (_) => unawaited(_sendBeaconIfReady()),
    );
  }

  void _stopBeaconLoop() {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _beaconSendInFlight = false;
  }

  Future<void> _sendBeaconIfReady() async {
    final config = _lastMeshConfig;
    if (config == null || !_bleReady || _beaconSendInFlight) return;
    if (_state.connection != EdgezConnectionType.ble) return;
    final status = _state.status;
    if (status != null &&
        (!status.supported || !status.stackInitialized || !status.meshMode)) {
      return;
    }

    _beaconSendInFlight = true;
    try {
      await sdk.sendBeacon(config);
      _setState(_state.copyWith(statusLine: 'Beacon sent'));
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Beacon send failed: $error'));
    } finally {
      _beaconSendInFlight = false;
    }
  }

  String _initKey(EdgezMeshConfig config) {
    return [
      config.countryCode.toUpperCase(),
      config.meshId,
      config.passphrase,
      config.maxHop,
      config.identity.userUuid,
      config.identity.userIdHigh,
      config.identity.userIdLow,
      config.identity.name,
      config.identity.publicKey.join(','),
    ].join('|');
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
    final highText = _hex64(high);
    final lowText = _hex64(low);
    return '${highText.substring(0, 8)}-${highText.substring(8, 12)}-${highText.substring(12, 16)}-'
        '${lowText.substring(0, 4)}-${lowText.substring(4, 16)}';
  }

  String _hex64(int value) {
    final unsigned = value < 0
        ? BigInt.from(value) + (BigInt.one << 64)
        : BigInt.from(value);
    return unsigned.toRadixString(16).padLeft(16, '0');
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
    _stopBeaconLoop();
    _pendingVoiceMessages.clear();
    _subscription.cancel();
    super.dispose();
  }
}

class _PendingVoiceMessage {
  _PendingVoiceMessage({
    required int totalChunks,
    required this.durationMs,
    required this.codec,
  }) : chunks = List<List<int>?>.filled(totalChunks, null);

  final int durationMs;
  final int codec;
  final List<List<int>?> chunks;

  void put(int index, List<int> audio) {
    if (index >= 0 && index < chunks.length) {
      chunks[index] = List<int>.from(audio);
    }
  }

  bool get complete => chunks.every((chunk) => chunk != null);

  _CompletedVoiceMessage completed() {
    return _CompletedVoiceMessage(
      bytes: <int>[
        for (final chunk in chunks) ...?chunk,
      ],
      codec: codec,
      durationMs: durationMs,
    );
  }
}

class _CompletedVoiceMessage {
  const _CompletedVoiceMessage({
    required this.bytes,
    required this.codec,
    required this.durationMs,
  });

  final List<int> bytes;
  final int codec;
  final int durationMs;
}
