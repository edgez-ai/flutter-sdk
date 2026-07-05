import 'dart:async';

import 'package:flutter/foundation.dart';

import 'edgez_mesh_sdk.dart';
import 'models.dart';

class EdgezMeshState {
  EdgezMeshState({
    required this.connection,
    required this.status,
    required Map<int, EdgezMeshNode> nodes,
    required Map<int, List<EdgezConversationMessage>> conversations,
    required this.statusLine,
  })  : nodes = Map<int, EdgezMeshNode>.unmodifiable(nodes),
        conversations = _freezeConversations(conversations);

  factory EdgezMeshState.initial() {
    return EdgezMeshState(
      connection: EdgezConnectionType.none,
      status: null,
      nodes: const <int, EdgezMeshNode>{},
      conversations: const <int, List<EdgezConversationMessage>>{},
      statusLine: 'Connect with BLE, then save mesh settings.',
    );
  }

  final EdgezConnectionType connection;
  final EdgezMeshStatus? status;
  final Map<int, EdgezMeshNode> nodes;
  final Map<int, List<EdgezConversationMessage>> conversations;
  final String statusLine;

  List<EdgezMeshNode> get sortedNodes {
    final sorted = nodes.values.toList()
      ..sort((a, b) => a.resolvedDisplayName
          .toLowerCase()
          .compareTo(b.resolvedDisplayName.toLowerCase()));
    return List<EdgezMeshNode>.unmodifiable(sorted);
  }

  EdgezMeshState copyWith({
    EdgezConnectionType? connection,
    EdgezMeshStatus? status,
    bool clearStatus = false,
    Map<int, EdgezMeshNode>? nodes,
    Map<int, List<EdgezConversationMessage>>? conversations,
    String? statusLine,
  }) {
    return EdgezMeshState(
      connection: connection ?? this.connection,
      status: clearStatus ? null : status ?? this.status,
      nodes: nodes ?? this.nodes,
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
}

class EdgezMeshSession extends ChangeNotifier {
  EdgezMeshSession({EdgezMeshSdk? sdk}) : sdk = sdk ?? EdgezMeshSdk() {
    _subscription = this.sdk.events.listen(_handleEvent);
  }

  final EdgezMeshSdk sdk;
  late final StreamSubscription<EdgezMeshEvent> _subscription;
  EdgezMeshState _state = EdgezMeshState.initial();

  EdgezMeshState get state => _state;

  Future<void> startBleScan() async {
    await sdk.startBleScan();
    _setState(
      _state.copyWith(
        connection: EdgezConnectionType.ble,
        statusLine: 'BLE scan requested',
      ),
    );
  }

  Future<void> disconnect() async {
    await sdk.disconnect();
    _setState(
      EdgezMeshState.initial().copyWith(statusLine: 'Disconnected'),
    );
  }

  Future<void> initializeMesh(EdgezMeshConfig config) async {
    await sdk.initializeMesh(config);
    _setState(_state.copyWith(statusLine: 'User mesh settings saved'));
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
    final conversations =
        Map<int, List<EdgezConversationMessage>>.of(_state.conversations)
          ..remove(nodeNum);
    _setState(_state.copyWith(nodes: nodes, conversations: conversations));
  }

  void _handleEvent(EdgezMeshEvent event) {
    switch (event.type) {
      case EdgezMeshEventType.connection:
        _setState(_state.copyWith(connection: event.connection));
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
