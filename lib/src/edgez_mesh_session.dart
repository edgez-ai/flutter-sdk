import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'edgez_mesh_sdk.dart';
import 'edgez_device_log_store.dart';
import 'models.dart';
import 'proto/edgez_mesh.pb.dart' as proto;

typedef EdgezIncomingMessageCallback = void Function(
  EdgezConversationMessage message,
  EdgezMeshNode sender,
);

typedef EdgezIncomingCallCallback = void Function(
  EdgezVoiceCallState call,
  EdgezMeshNode caller,
);

class EdgezLinkStats {
  const EdgezLinkStats({
    required this.bitsPerSecond,
    required this.packetLossPercent,
    required this.receivedPackets,
    required this.expectedPackets,
    required this.updatedAtMs,
  });

  final double bitsPerSecond;
  final double packetLossPercent;
  final int receivedPackets;
  final int expectedPackets;
  final int updatedAtMs;
}

class EdgezUsbLinkStats {
  const EdgezUsbLinkStats({
    this.sentPings = 0,
    this.receivedPings = 0,
    this.receivedPongs = 0,
    this.timeouts = 0,
    this.rttMs = 0,
  });

  final int sentPings;
  final int receivedPings;
  final int receivedPongs;
  final int timeouts;
  final int rttMs;

  bool get bidirectional => receivedPings > 0 && receivedPongs > 0;
}

class EdgezMeshState {
  EdgezMeshState({
    required this.connection,
    required this.status,
    required Map<String, EdgezBleDevice> bleDevices,
    required Map<int, EdgezMeshNode> nodes,
    required Map<int, List<EdgezSensorSample>> sensorSamples,
    required List<EdgezTopologyLink> topologyLinks,
    required List<EdgezBatmanRoute> routingTable,
    required Map<int, List<EdgezConversationMessage>> conversations,
    required Map<int, EdgezLinkStats> linkStats,
    required this.otaInProgress,
    required this.otaReady,
    required this.otaSentBytes,
    required this.otaTotalBytes,
    required this.voiceCall,
    required this.statusLine,
    required this.bleReady,
    this.debugLogs = const <String>[],
    this.usbLinkStats = const EdgezUsbLinkStats(),
    this.sharedLinkStats,
    this.bleConnecting = false,
    this.deviceSettings,
    this.selfLocation,
    this.routingTableLoading = false,
  })  : bleDevices = Map<String, EdgezBleDevice>.unmodifiable(bleDevices),
        nodes = Map<int, EdgezMeshNode>.unmodifiable(nodes),
        sensorSamples = _freezeSensorSamples(sensorSamples),
        topologyLinks = List<EdgezTopologyLink>.unmodifiable(topologyLinks),
        routingTable = List<EdgezBatmanRoute>.unmodifiable(routingTable),
        conversations = _freezeConversations(conversations),
        linkStats = Map<int, EdgezLinkStats>.unmodifiable(linkStats);

  factory EdgezMeshState.initial() {
    final publicChannels = <int, EdgezMeshNode>{
      for (final node in EdgezPublicChannels.nodes) node.nodeNum: node,
    };
    return EdgezMeshState(
      connection: EdgezConnectionType.none,
      status: null,
      bleDevices: const <String, EdgezBleDevice>{},
      nodes: publicChannels,
      sensorSamples: const <int, List<EdgezSensorSample>>{},
      topologyLinks: const <EdgezTopologyLink>[],
      routingTable: const <EdgezBatmanRoute>[],
      conversations: const <int, List<EdgezConversationMessage>>{},
      linkStats: const <int, EdgezLinkStats>{},
      otaInProgress: false,
      otaReady: false,
      otaSentBytes: 0,
      otaTotalBytes: 0,
      voiceCall: const EdgezVoiceCallState(),
      statusLine: 'Connect with BLE, then save mesh settings.',
      bleReady: false,
      usbLinkStats: const EdgezUsbLinkStats(),
      bleConnecting: false,
    );
  }

  final EdgezConnectionType connection;
  final EdgezMeshStatus? status;
  final Map<String, EdgezBleDevice> bleDevices;
  final Map<int, EdgezMeshNode> nodes;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final List<EdgezTopologyLink> topologyLinks;
  final List<EdgezBatmanRoute> routingTable;
  final Map<int, List<EdgezConversationMessage>> conversations;
  final Map<int, EdgezLinkStats> linkStats;
  final bool otaInProgress;
  final bool otaReady;
  final int otaSentBytes;
  final int otaTotalBytes;
  final EdgezVoiceCallState voiceCall;
  final String statusLine;
  final bool bleReady;

  /// Most recent transport and firmware-console lines, bounded by the session.
  final List<String> debugLogs;
  final EdgezUsbLinkStats usbLinkStats;
  final EdgezLinkStats? sharedLinkStats;
  final bool bleConnecting;
  final EdgezDeviceSettings? deviceSettings;
  final EdgezLocation? selfLocation;
  final bool routingTableLoading;

  double get otaProgress =>
      otaTotalBytes <= 0 ? 0 : otaSentBytes / otaTotalBytes;

  List<EdgezMeshNode> get sortedNodes {
    final sorted = nodes.values.toList()
      ..sort((a, b) => a.resolvedDisplayName
          .toLowerCase()
          .compareTo(b.resolvedDisplayName.toLowerCase()));
    return List<EdgezMeshNode>.unmodifiable(sorted);
  }

  EdgezMeshNode? nodeByNum(int nodeNum) =>
      nodes[nodeNum] ?? EdgezPublicChannels.nodeForNodeNum(nodeNum);

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
    List<EdgezTopologyLink>? topologyLinks,
    List<EdgezBatmanRoute>? routingTable,
    Map<int, List<EdgezConversationMessage>>? conversations,
    Map<int, EdgezLinkStats>? linkStats,
    bool? otaInProgress,
    bool? otaReady,
    int? otaSentBytes,
    int? otaTotalBytes,
    EdgezVoiceCallState? voiceCall,
    String? statusLine,
    bool? bleReady,
    List<String>? debugLogs,
    EdgezUsbLinkStats? usbLinkStats,
    EdgezLinkStats? sharedLinkStats,
    bool? bleConnecting,
    EdgezDeviceSettings? deviceSettings,
    bool clearDeviceSettings = false,
    EdgezLocation? selfLocation,
    bool clearSelfLocation = false,
    bool? routingTableLoading,
  }) {
    return EdgezMeshState(
      connection: connection ?? this.connection,
      status: clearStatus ? null : status ?? this.status,
      bleDevices: bleDevices ?? this.bleDevices,
      nodes: nodes ?? this.nodes,
      sensorSamples: sensorSamples ?? this.sensorSamples,
      topologyLinks: topologyLinks ?? this.topologyLinks,
      routingTable: routingTable ?? this.routingTable,
      conversations: conversations ?? this.conversations,
      linkStats: linkStats ?? this.linkStats,
      otaInProgress: otaInProgress ?? this.otaInProgress,
      otaReady: otaReady ?? this.otaReady,
      otaSentBytes: otaSentBytes ?? this.otaSentBytes,
      otaTotalBytes: otaTotalBytes ?? this.otaTotalBytes,
      voiceCall: voiceCall ?? this.voiceCall,
      statusLine: statusLine ?? this.statusLine,
      bleReady: bleReady ?? this.bleReady,
      debugLogs: List<String>.unmodifiable(debugLogs ?? this.debugLogs),
      usbLinkStats: usbLinkStats ?? this.usbLinkStats,
      sharedLinkStats: sharedLinkStats ?? this.sharedLinkStats,
      bleConnecting: bleConnecting ?? this.bleConnecting,
      deviceSettings:
          clearDeviceSettings ? null : deviceSettings ?? this.deviceSettings,
      selfLocation:
          clearSelfLocation ? null : selfLocation ?? this.selfLocation,
      routingTableLoading: routingTableLoading ?? this.routingTableLoading,
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
  EdgezMeshSession({
    EdgezMeshSdk? sdk,
    this.onIncomingMessage,
    this.onIncomingCall,
    this.deviceLogStore,
    this.speedTestInactivityTimeout = const Duration(seconds: 30),
    this.speedTestReliableDelivery = false,
    this.deviceStatusTimeout = const Duration(seconds: 8),
    this.halowBootRetryDelay = const Duration(seconds: 3),
  }) : sdk = sdk ?? EdgezMeshSdk() {
    _subscription = this.sdk.events.listen(_handleEvent);
  }

  final EdgezMeshSdk sdk;
  final EdgezIncomingMessageCallback? onIncomingMessage;
  final EdgezIncomingCallCallback? onIncomingCall;
  final EdgezDeviceLogStore? deviceLogStore;
  final Duration speedTestInactivityTimeout;
  final bool speedTestReliableDelivery;
  final Duration deviceStatusTimeout;
  final Duration halowBootRetryDelay;
  late final StreamSubscription<EdgezMeshEvent> _subscription;
  EdgezMeshState _state = EdgezMeshState.initial();
  // Device logs share the BLE realtime characteristic with voice and speed
  // traffic. Keep streaming opt-in so an idle connection stays idle.
  EdgezDeviceLogLevel _appLogLevel = EdgezDeviceLogLevel.none;
  EdgezMeshConfig? _lastMeshConfig;
  var _bleReady = false;
  Timer? _deviceStatusTimeout;
  Timer? _halowBootRetryTimer;
  Timer? _routingTableTimeout;
  Timer? _locationUpdateTimer;
  Duration? _locationUpdateInterval;
  Timer? _voiceCallTimeout;
  var _provisioning = false;
  var _initInFlight = false;
  var _initRetryRequested = false;
  var _bleRecoveryInFlight = false;
  var _bleStatusReconnectAttempts = 0;
  String? _lastBleDeviceId;
  var _locationUpdateInFlight = false;
  var _publicChannelSyncInFlight = false;
  String? _lastInitKey;
  var _voiceCallSequence = 1;
  Future<void> _voiceFramePipeline = Future<void>.value();
  var _voiceAudioSendInFlight = false;
  List<int>? _pendingVoiceAudio;
  final Map<String, _PendingVoiceMessage> _pendingVoiceMessages =
      <String, _PendingVoiceMessage>{};
  final Map<String, _PendingSpeedTest> _pendingSpeedTests =
      <String, _PendingSpeedTest>{};
  final Map<String, _OutgoingSpeedTest> _outgoingSpeedTests =
      <String, _OutgoingSpeedTest>{};
  final Map<int, _BatmanPathMetric> _batmanPaths = <int, _BatmanPathMetric>{};
  final _TransportTrafficMeter _trafficMeter = _TransportTrafficMeter();
  int? _transportMonotonicToEpochOffsetUs;
  static const Set<String> _knownMarkerIds = <String>{
    'default',
    'red',
    'blue',
    'purple',
    'yellow',
    'pink',
    'brown',
    'green',
    'orange',
    'deep_purple',
    'light_blue',
    'cyan',
    'teal',
    'lime',
    'deep_orange',
    'gray',
    'blue_gray',
  };

  EdgezMeshState get state => _state;

  /// Restores the retained firmware log window from the optional log store.
  Future<void> restoreDeviceLogs() async {
    final store = deviceLogStore;
    if (store == null) return;
    try {
      final logs = await store.load();
      _setState(_state.copyWith(debugLogs: logs));
    } catch (_) {
      // Log persistence must never prevent a session from starting.
    }
  }

  /// Clears both the retained UI window and all rotated log files.
  Future<void> pruneDeviceLogs() async {
    // Clear the visible cache before yielding. Any new event received after
    // this point is appended behind the serialized file clear and is retained.
    _setState(_state.copyWith(debugLogs: const <String>[]));
    await deviceLogStore?.clear();
  }

  void beginProvisioning() {
    _provisioning = true;
  }

  void endProvisioning() {
    _provisioning = false;
  }

  static const _callMagic = <int>[0x45, 0x56, 0x43, 0x32];
  static const _callInvite = 1;
  static const _callAccept = 2;
  static const _callEnd = 3;
  static const _callAudio = 4;

  void restoreCachedMeshData({
    required Map<int, EdgezMeshNode> nodes,
    required Map<int, List<EdgezConversationMessage>> conversations,
    Map<int, List<EdgezSensorSample>> sensorSamples =
        const <int, List<EdgezSensorSample>>{},
  }) {
    final mergedNodes = <int, EdgezMeshNode>{
      for (final channel in EdgezPublicChannels.nodes) channel.nodeNum: channel,
      ...nodes,
    };
    _setState(
      _state.copyWith(
        nodes: mergedNodes,
        sensorSamples: sensorSamples,
        conversations: conversations,
        statusLine: nodes.isEmpty
            ? _state.statusLine
            : 'Loaded ${nodes.length} saved node(s)',
      ),
    );
    if (_bleReady) unawaited(_syncPublicChannelsIfNeeded(_state.status));
  }

  Set<int> get enabledPublicChannels => <int>{
        for (final port in EdgezPublicChannels.talkgroupPorts)
          if (_state.nodes[port]?.enabled ?? true) port,
      };

  Future<void> setPublicChannelEnabled(int port, bool enabled) async {
    if (!EdgezPublicChannels.isChannelNodeNum(port)) {
      throw ArgumentError.value(port, 'port', 'Unsupported public channel');
    }
    final nodes = Map<int, EdgezMeshNode>.of(_state.nodes);
    final current = nodes[port] ?? EdgezPublicChannels.nodeForNodeNum(port)!;
    nodes[port] = current.copyWith(enabled: enabled);
    _setState(_state.copyWith(
      nodes: nodes,
      statusLine:
          '${current.resolvedDisplayName} ${enabled ? 'enabled' : 'disabled'}',
    ));
    if (_lastMeshConfig != null) {
      _lastMeshConfig = _lastMeshConfig!
          .copyWith(enabledPublicChannels: enabledPublicChannels);
    }
    if (_bleReady && _state.connection != EdgezConnectionType.none) {
      await _syncPublicChannelsIfNeeded(_state.status, force: true);
    }
  }

  Future<void> _syncPublicChannelsIfNeeded(EdgezMeshStatus? status,
      {bool force = false}) async {
    if (_publicChannelSyncInFlight ||
        !_bleReady ||
        _state.connection == EdgezConnectionType.none) return;
    final desired = EdgezPublicChannels.maskForPorts(enabledPublicChannels);
    if (!force &&
        (status == null ||
            !status.supportsPublicChannelMask ||
            status.publicChannelMask == desired)) return;
    _publicChannelSyncInFlight = true;
    try {
      await sdk.updatePublicChannels(enabledPublicChannels);
    } finally {
      _publicChannelSyncInFlight = false;
    }
  }

  /// Stores a voice transcript on its conversation message so later
  /// translations can reuse text without decoding the audio again.
  void updateConversationMessageTranscript(
    EdgezConversationMessage target, {
    required String transcript,
    required String language,
  }) {
    if (transcript.trim().isEmpty) return;
    final messages = _state.conversations[target.nodeNum];
    if (messages == null) return;
    var changed = false;
    final updated = messages.map((message) {
      final sameMessage = target.messageUuid.isNotEmpty
          ? message.messageUuid == target.messageUuid
          : message.timestampMs == target.timestampMs &&
              message.mine == target.mine;
      if (!sameMessage) return message;
      changed = true;
      return message.copyWith(
        transcript: transcript.trim(),
        transcriptLanguage: language,
      );
    }).toList(growable: false);
    if (!changed) return;
    final conversations =
        Map<int, List<EdgezConversationMessage>>.of(_state.conversations)
          ..[target.nodeNum] = updated;
    _setState(_state.copyWith(conversations: conversations));
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

  Future<bool> get isOtaReady => sdk.isOtaReady();

  Future<void> performOta(List<int> firmwareImage) async {
    _setState(
      _state.copyWith(
        otaInProgress: true,
        otaSentBytes: 0,
        otaTotalBytes: firmwareImage.length,
        statusLine: 'Starting firmware update',
      ),
    );
    try {
      final message = await sdk.performOta(firmwareImage);
      _setState(
        _state.copyWith(
          otaInProgress: false,
          otaSentBytes: firmwareImage.length,
          otaTotalBytes: firmwareImage.length,
          statusLine: message,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          otaInProgress: false,
          statusLine: 'Firmware update failed: $error',
        ),
      );
      rethrow;
    }
  }

  Future<void> abortOta() async {
    await sdk.abortOta();
    _setState(
      _state.copyWith(
        otaInProgress: false,
        statusLine: 'Firmware update cancelled',
      ),
    );
  }

  Future<void> startVoiceCall(int peerNodeNum) async {
    if (!_state.voiceCall.isIdle) {
      throw StateError('A voice call is already in progress');
    }
    final peer = _state.nodeByNum(peerNodeNum);
    if (peer == null || !peer.opensConversation) {
      throw StateError('Voice-call peer is unavailable');
    }
    if (!await sdk.requestMicrophonePermission()) {
      throw StateError('Microphone permission denied');
    }
    if (peer.isPublicChannel) {
      final channelCall = EdgezVoiceCallState(
        peerNodeNum: peerNodeNum,
        callId: peerNodeNum,
        phase: EdgezVoiceCallPhase.active,
      );
      _setState(
        _state.copyWith(
          voiceCall: channelCall,
          statusLine: 'Joined ${peer.resolvedDisplayName}',
        ),
      );
      try {
        await sdk.startOpenManetComms(peerNodeNum);
      } catch (_) {
        _setState(_state.copyWith(voiceCall: const EdgezVoiceCallState()));
        rethrow;
      }
      return;
    }
    final callId = Random.secure().nextInt(0x7fffffff) |
        (Random.secure().nextInt(0x7fffffff) << 31);
    _voiceCallSequence = 1;
    final outgoingCall = EdgezVoiceCallState(
      peerNodeNum: peerNodeNum,
      callId: callId,
      phase: EdgezVoiceCallPhase.outgoing,
    );
    _setState(
      _state.copyWith(
        voiceCall: outgoingCall,
        statusLine: 'Calling ${peer.resolvedDisplayName}',
      ),
    );
    _scheduleVoiceCallTimeout(outgoingCall);
    try {
      await _sendVoiceCallPacket(_callInvite);
    } catch (_) {
      await _resetVoiceCall();
      rethrow;
    }
  }

  Future<void> acceptVoiceCall() async {
    if (_state.voiceCall.phase != EdgezVoiceCallPhase.incoming) {
      throw StateError('No incoming voice call');
    }
    await _sendVoiceCallPacket(_callAccept);
    _voiceCallTimeout?.cancel();
    _setState(
      _state.copyWith(
        voiceCall: EdgezVoiceCallState(
          peerNodeNum: _state.voiceCall.peerNodeNum,
          callId: _state.voiceCall.callId,
          phase: EdgezVoiceCallPhase.active,
        ),
        statusLine: 'Voice call active',
      ),
    );
  }

  Future<void> endVoiceCall() async {
    Future<void>? endFrame;
    final peerNodeNum = _state.voiceCall.peerNodeNum;
    final isChannel = peerNodeNum != null &&
        EdgezPublicChannels.isChannelNodeNum(peerNodeNum);
    if (!_state.voiceCall.isIdle && !isChannel) {
      endFrame = _sendVoiceCallPacket(_callEnd);
    }
    await _resetVoiceCall();
    if (endFrame != null) {
      unawaited(endFrame.catchError((_) {}));
    }
  }

  Future<void> setVoiceTransmit(bool enabled) async {
    final peerNodeNum = _state.voiceCall.peerNodeNum;
    if (!_state.voiceCall.isActive || peerNodeNum == null) {
      throw StateError('No realtime voice session is active');
    }
    if (EdgezPublicChannels.isChannelNodeNum(peerNodeNum)) {
      await sdk.setOpenManetTransmit(enabled);
    } else if (enabled) {
      await sdk.startLiveVoiceAudio();
    } else {
      await sdk.stopLiveVoiceCapture();
    }
  }

  Future<void> _resetVoiceCall({String statusLine = 'Voice call ended'}) async {
    final peerNodeNum = _state.voiceCall.peerNodeNum;
    final isChannel = peerNodeNum != null &&
        EdgezPublicChannels.isChannelNodeNum(peerNodeNum);
    _voiceCallTimeout?.cancel();
    _pendingVoiceAudio = null;
    if (isChannel) {
      await sdk.stopOpenManetComms();
    } else if (peerNodeNum != null) {
      await sdk.stopLiveVoiceAudio();
    }
    _setState(
      _state.copyWith(
        voiceCall: const EdgezVoiceCallState(),
        statusLine: statusLine,
      ),
    );
  }

  void _scheduleVoiceCallTimeout(EdgezVoiceCallState pendingCall) {
    _voiceCallTimeout?.cancel();
    _voiceCallTimeout = Timer(const Duration(seconds: 60), () {
      final current = _state.voiceCall;
      if (current.callId == pendingCall.callId &&
          current.peerNodeNum == pendingCall.peerNodeNum &&
          (current.phase == EdgezVoiceCallPhase.incoming ||
              current.phase == EdgezVoiceCallPhase.outgoing)) {
        unawaited(_resetVoiceCall(statusLine: 'Voice call timed out'));
      }
    });
  }

  Future<void> _sendVoiceCallPacket(int type,
      [List<int> audio = const []]) async {
    final call = _state.voiceCall;
    final config = _lastMeshConfig;
    final peer =
        call.peerNodeNum == null ? null : _state.nodeByNum(call.peerNodeNum!);
    final fromNode = _state.status?.macAddress ?? 0;
    if (config == null || peer == null || fromNode == 0) {
      throw StateError('Voice-call mesh identity is unavailable');
    }
    final sequence = _voiceCallSequence++;
    final packet = _encodeVoiceCallPacket(
      type: type,
      callId: call.callId,
      sequence: sequence,
      audio: audio,
    );
    await sdk.sendVoiceCallFrame(
      config: config,
      toNode: peer,
      fromNode: fromNode,
      plaintext: packet,
      sequence: sequence,
      maxHop: config.maxHop,
    );
  }

  void _queueVoiceAudio(List<int> audio) {
    _pendingVoiceAudio = List<int>.from(audio);
    if (_voiceAudioSendInFlight) return;
    _voiceAudioSendInFlight = true;
    unawaited(_drainVoiceAudio());
  }

  Future<void> _drainVoiceAudio() async {
    try {
      while (_state.voiceCall.isActive && _pendingVoiceAudio != null) {
        final audio = _pendingVoiceAudio!;
        _pendingVoiceAudio = null;
        await _sendVoiceCallPacket(_callAudio, audio);
        final peerNode = _state.voiceCall.peerNodeNum;
        if (peerNode != null) {
          final pacing = _realtimePathProfile(
            peerNode,
            0,
          ).voicePacingDelay;
          if (pacing > Duration.zero) {
            await Future<void>.delayed(pacing);
          }
        }
      }
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Voice audio send failed: $error'));
    } finally {
      _voiceAudioSendInFlight = false;
      if (_state.voiceCall.isActive && _pendingVoiceAudio != null) {
        _queueVoiceAudio(_pendingVoiceAudio!);
      }
    }
  }

  Future<void> connectBle(String deviceId) async {
    _deviceStatusTimeout?.cancel();
    _halowBootRetryTimer?.cancel();
    _halowBootRetryTimer = null;
    _lastBleDeviceId = deviceId;
    _bleStatusReconnectAttempts = 0;
    // SDK release authorization lives in firmware RAM. A reconnect may follow
    // a device reset, so the init/auth packet must be sent again even when the
    // saved mesh configuration itself has not changed.
    _lastInitKey = null;
    _recordAppDiagnostic(
      EdgezDeviceLogLevel.debug,
      'BLE reconnect requested device=$deviceId previous=${_state.connection.name}',
    );
    // A session owns exactly one physical transport. Close USB (or a previous
    // BLE link) before Android starts a new BLE connection.
    if (_state.connection != EdgezConnectionType.none) {
      await sdk.disconnect();
      _bleReady = false;
    }
    _setState(
      _state.copyWith(
        bleConnecting: true,
        clearStatus: true,
        clearDeviceSettings: true,
        statusLine:
            'Starting BLE connection to ${_state.bleDevices[deviceId]?.label ?? deviceId}',
      ),
    );
    try {
      await sdk.connectBle(deviceId);
      _bleReady = false;
      _setState(
        _state.copyWith(
          bleReady: false,
          statusLine: 'BLE connection requested; waiting for Android',
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          bleConnecting: false,
          statusLine: 'BLE connect failed: $error',
        ),
      );
    }
  }

  Future<void> connectUsb(EdgezUsbDevice device) async {
    _deviceStatusTimeout?.cancel();
    // Opening a CP2102 commonly resets the ESP32. Never reuse initialization
    // deduplication state from BLE or an earlier USB connection.
    _lastInitKey = null;
    _recordAppDiagnostic(
      EdgezDeviceLogLevel.debug,
      'USB reconnect requested device=${device.id} previous=${_state.connection.name}',
    );
    // Do not leave a GATT connection alive while opening the USB serial port.
    if (_state.connection != EdgezConnectionType.none) {
      await sdk.disconnect();
    }
    await sdk.stopBleScan();
    _bleReady = false;
    _setState(
      _state.copyWith(
        clearStatus: true,
        clearDeviceSettings: true,
        bleReady: false,
        statusLine: 'Connecting USB to ${device.label}',
      ),
    );
    try {
      await sdk.connectUsb(device.id);
      _setState(
        _state.copyWith(
          statusLine: 'USB connection requested; waiting for device',
        ),
      );
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'USB connect failed: $error'));
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _routingTableTimeout?.cancel();
    await sdk.disconnect();
    await deviceLogStore?.flush();
    _deviceStatusTimeout?.cancel();
    _stopLocationTracking();
    _bleReady = false;
    _lastInitKey = null;
    // Nodes, conversations, samples, and measured peer links are cached app
    // data, not properties of the physical transport. Keep them available so
    // a disconnect/reconnect does not empty the example UI while rediscovery
    // is still in progress.
    final retainedState = _state;
    _setState(
      EdgezMeshState.initial().copyWith(
        bleDevices: retainedState.bleDevices,
        nodes: retainedState.nodes,
        sensorSamples: retainedState.sensorSamples,
        topologyLinks: retainedState.topologyLinks,
        routingTable: retainedState.routingTable,
        conversations: retainedState.conversations,
        linkStats: retainedState.linkStats,
        sharedLinkStats: retainedState.sharedLinkStats,
        statusLine: 'Disconnected',
        debugLogs: retainedState.debugLogs,
      ),
    );
  }

  Future<void> setDeviceLogLevel(EdgezDeviceLogLevel level) {
    _appLogLevel = level;
    return sdk.setDeviceLogLevel(level);
  }

  Future<void> requestRoutingTable() async {
    final fromNode = _state.status?.macAddress ?? 0;
    if (_state.connection == EdgezConnectionType.none || fromNode == 0) {
      throw StateError('Connect to a device before requesting routes');
    }
    _setState(
      _state.copyWith(
        routingTableLoading: true,
        statusLine: 'Requesting BATMAN routing table',
      ),
    );
    try {
      await sdk.requestRoutingTable(fromNode: fromNode);
      _routingTableTimeout?.cancel();
      _routingTableTimeout = Timer(const Duration(seconds: 8), () {
        if (!_state.routingTableLoading) return;
        _setState(
          _state.copyWith(
            routingTableLoading: false,
            statusLine: 'Routing table request timed out',
          ),
        );
      });
    } catch (error) {
      _setState(
        _state.copyWith(
          routingTableLoading: false,
          statusLine: 'Routing table request failed: $error',
        ),
      );
      rethrow;
    }
  }

  Future<void> configureLogLevel(EdgezDeviceLogLevel level) {
    _appLogLevel = level;
    return sdk.configureDeviceLogLevel(level);
  }

  Future<void> _applyConfiguredDeviceLogLevel() async {
    try {
      await sdk.setDeviceLogLevel(_appLogLevel);
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.debug,
        'Applied device log level=${_appLogLevel.name} after transport ready',
      );
    } catch (error) {
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.warning,
        'Unable to apply device log level after transport ready: $error',
      );
    }
  }

  Future<void> initializeMesh(EdgezMeshConfig config) async {
    config = config.copyWith(enabledPublicChannels: enabledPublicChannels);
    _lastMeshConfig = config;
    if (!config.beacon.shareLocation) _stopLocationTracking();
    await _sendInitIfReady(force: true);
    if (config.beacon.shareLocation) {
      _updateLocationTrackingForStatus(_state.status);
    }
  }

  /// Requests a current phone fix and broadcasts it through the connected
  /// EdgeZ device. Returns false when sharing/link state/location is invalid.
  Future<bool> refreshSharedLocation() async {
    final config = _lastMeshConfig;
    if (config == null ||
        !config.beacon.shareLocation ||
        !_bleReady ||
        _state.connection == EdgezConnectionType.none ||
        _locationUpdateInFlight) {
      return false;
    }
    final status = _state.status;
    if (status == null || !status.meshMode || !status.isUsable) {
      return false;
    }

    _locationUpdateInFlight = true;
    try {
      final location = await sdk.getBestKnownLocation();
      if (location == null || !_isValidSharedLocation(location)) return false;
      await sdk.sendLocationUpdate(location: location);
      return true;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'edgez_flutter_sdk',
          context: ErrorDescription('while refreshing shared location'),
        ),
      );
      return false;
    } finally {
      _locationUpdateInFlight = false;
    }
  }

  Future<void> authorizeSession() async {
    if (!_bleReady || _state.connection == EdgezConnectionType.none) {
      throw StateError('Device control transport is not ready');
    }
    _setState(
      _state.copyWith(
        clearStatus: true,
        statusLine: 'Checking device license',
      ),
    );
    await sdk.authorizeSession();
  }

  Future<void> requestDeviceSettings() async {
    await sdk.requestDeviceSettings();
    _setState(_state.copyWith(statusLine: 'Device settings requested'));
  }

  Future<void> sendDeviceSettings(
    EdgezDeviceSettings settings, {
    EdgezUserIdentity? identity,
    List<EdgezSensorScriptConfig> scripts = const <EdgezSensorScriptConfig>[],
  }) async {
    final settingsIdentity = identity ?? _lastMeshConfig?.identity;
    try {
      await sdk.sendDeviceSettings(
        settings: settings,
        identity: settingsIdentity,
      );
      for (final script in scripts) {
        await sdk.sendSensorScript(script);
      }
      _setState(_state.copyWith(
        statusLine: scripts.isEmpty
            ? 'Device settings sent'
            : 'Device settings and ${scripts.length} driver(s) sent',
      ));
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Device settings failed: $error'));
      rethrow;
    }
  }

  Future<void> setDeviceGpsEnabled(bool enabled) async {
    final settings = _state.deviceSettings;
    if (settings == null) {
      throw StateError('Read device settings before changing device GPS');
    }
    EdgezUserIdentity? identity;
    if (settings.userIdHigh != 0 ||
        settings.userIdLow != 0 ||
        settings.userPublicKey.isNotEmpty ||
        settings.userPrivateKey.isNotEmpty) {
      identity = EdgezUserIdentity(
        userIdHigh: settings.userIdHigh,
        userIdLow: settings.userIdLow,
        name: settings.userName,
        publicKey: settings.userPublicKey,
        privateKey: settings.userPrivateKey,
      );
    }
    await sendDeviceSettings(
      settings.copyWith(deviceGpsEnabled: enabled),
      identity: identity,
    );
  }

  Future<void> sendTextMessage({
    required int toNode,
    required String text,
    int maxHop = 0,
  }) async {
    final node = _state.nodeByNum(toNode);
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
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.warning,
        'Conversation send blocked to=$toNode: mesh config=${config != null} local=0x${fromNode.toRadixString(16)}',
      );
      _replaceMessage(
        pendingUuid,
        status: 'Failed: save settings and wait for mesh status',
        statusLine: 'Save settings and wait for mesh status',
      );
      return;
    }
    try {
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.debug,
        'Conversation send start to=0x${toNode.toRadixString(16)} bytes=${text.length} hop=$maxHop transport=${_state.connection.name}',
      );
      final messageUuid = await sdk.sendTextMessage(
        config: config,
        toNode: node!,
        fromNode: fromNode,
        text: text,
        maxHop: maxHop,
        onPacketSent: (packetBytes, sequence) => _recordTransportTraffic(
          byteCount: packetBytes,
          streamKey: 'conversation-tx:$pendingUuid',
          sequence: sequence,
          receivedAtUs: 0,
        ),
      );
      _replaceMessage(
        pendingUuid,
        messageUuid: messageUuid,
        status: 'Sent via ${_state.connection.name.toUpperCase()}',
        statusLine: 'Message sent',
      );
    } catch (error) {
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.error,
        'Conversation send failed to=0x${toNode.toRadixString(16)} error=$error',
      );
      _replaceMessage(
        pendingUuid,
        status: 'Failed: $error',
        statusLine: 'Message send failed: $error',
      );
      rethrow;
    }
  }

  Future<void> sendVoiceMessage({
    required int toNode,
    required List<int> bytes,
    required int durationMs,
    required int codec,
    int maxHop = 0,
  }) async {
    final node = _state.nodeByNum(toNode);
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
        onPacketSent: (packetBytes, sequence) => _recordTransportTraffic(
          byteCount: packetBytes,
          streamKey: 'voice-message-tx:$pendingUuid',
          sequence: sequence,
          receivedAtUs: 0,
        ),
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

  Future<void> sendSpeedTest({
    required int toNode,
    int totalBytes = EdgezMeshSdk.speedTestBytes,
    int hop = 0,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final node = _state.nodeByNum(toNode);
    final fromNode = _state.status?.macAddress ?? 0;
    if (!(node?.opensConversation ?? false) || fromNode == 0) {
      throw StateError('Save settings and wait for a reachable user node');
    }
    if (hop < 0 || hop > 3) {
      throw ArgumentError.value(hop, 'hop', 'Must be between 0 and 3');
    }
    _setState(_state.copyWith(statusLine: 'Sending link measurement'));
    final pathProfile = _realtimePathProfile(toNode, hop);
    String? outgoingKey;
    try {
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.debug,
        'Speed test start to=0x${toNode.toRadixString(16)} bytes=$totalBytes hop=$hop transport=${_state.connection.name}',
      );
      await sdk.sendSpeedTest(
        toNode: toNode,
        fromNode: fromNode,
        totalBytes: totalBytes,
        hop: hop,
        drainBatchChunks: pathProfile.speedDrainBatchChunks,
        pacingDelay: pathProfile.speedPacingDelay,
        onProgress: onProgress,
        onTransferStarted: (transferId, bytes, chunks) {
          if (!speedTestReliableDelivery) return;
          outgoingKey = '$toNode:$transferId';
          final outgoing = _OutgoingSpeedTest(
            totalBytes: bytes,
            totalChunks: chunks,
            hop: hop,
          );
          outgoing.expiry = Timer(const Duration(minutes: 2), () {
            _outgoingSpeedTests.remove(outgoingKey)?.expiry?.cancel();
          });
          _outgoingSpeedTests[outgoingKey!] = outgoing;
        },
        onPacketSent: (packetBytes, sequence) => _recordTransportTraffic(
          byteCount: packetBytes,
          streamKey: 'speed-tx:$fromNode:$toNode',
          sequence: sequence,
          receivedAtUs: 0,
        ),
      );
      _setState(_state.copyWith(statusLine: 'Link measurement sent'));
    } catch (error) {
      _outgoingSpeedTests.remove(outgoingKey)?.expiry?.cancel();
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.error,
        'Speed test send failed to=0x${toNode.toRadixString(16)} error=$error',
      );
      _setState(_state.copyWith(statusLine: 'Link measurement failed: $error'));
      rethrow;
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

  Future<Uint8List> decodeVoiceMessageToWav(
    EdgezConversationMessage message,
  ) {
    return sdk.decodeVoiceMessageToWav(message);
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
        _deviceStatusTimeout?.cancel();
        if (event.connection == EdgezConnectionType.none) {
          _halowBootRetryTimer?.cancel();
          _halowBootRetryTimer = null;
          _bleReady = false;
          _lastInitKey = null;
          _stopLocationTracking();
          if (!_state.voiceCall.isIdle) {
            unawaited(sdk.stopLiveVoiceAudio());
            unawaited(sdk.stopOpenManetComms());
          }
        }
        _setState(
          _state.copyWith(
            connection: event.connection,
            bleConnecting: false,
            bleReady: event.connection == EdgezConnectionType.none
                ? false
                : _state.bleReady,
            otaReady: event.connection == EdgezConnectionType.none
                ? false
                : _state.otaReady,
            voiceCall: event.connection == EdgezConnectionType.none
                ? const EdgezVoiceCallState()
                : _state.voiceCall,
            statusLine: switch (event.connection) {
              EdgezConnectionType.ble =>
                'BLE link connected; setting up control channel',
              EdgezConnectionType.usb => 'USB high-speed link connected',
              EdgezConnectionType.none => 'Device disconnected',
            },
          ),
        );
        _recordAppDiagnostic(
          event.connection == EdgezConnectionType.none
              ? EdgezDeviceLogLevel.warning
              : EdgezDeviceLogLevel.debug,
          'Transport state=${event.connection.name} ready=$_bleReady initReset=${_lastInitKey == null}',
        );
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
        _handlePacket(event.packet, receivedAtUs: event.receivedAtUs);
      case EdgezMeshEventType.ready:
        _bleReady = true;
        _setState(_state.copyWith(
          statusLine: _state.connection == EdgezConnectionType.usb
              ? 'USB protocol ready; initializing mesh'
              : 'BLE control channel ready; requesting device status',
          bleReady: true,
          clearStatus: true,
        ));
        _recordAppDiagnostic(
          EdgezDeviceLogLevel.debug,
          'Transport ready=${_state.connection.name}; reinitializing mesh=${!_provisioning}',
        );
        unawaited(_refreshOtaReadiness());
        // USB receives this level in the nonce handshake; BLE has no handshake
        // payload, so send LG2 when either control stream becomes writable.
        unawaited(_applyConfiguredDeviceLogLevel());
        if (!_provisioning) {
          if (_state.connection == EdgezConnectionType.usb) {
            unawaited(_authorizeAndInitializeUsb());
          } else {
            // A fast native reconnect does not always expose the intermediate
            // disconnected event to Dart. Always resend the idempotent INIT
            // when a fresh BLE control channel becomes writable.
            unawaited(_sendInitIfReady(force: true));
          }
        }
      case EdgezMeshEventType.status:
        _deviceStatusTimeout?.cancel();
        final nodes = Map<int, EdgezMeshNode>.of(_state.nodes);
        final localNode = event.status?.macAddress ?? 0;
        if (localNode != 0) nodes.remove(localNode);
        _setState(
          _state.copyWith(
            status: event.status,
            nodes: nodes,
            statusLine: 'Device status received',
          ),
        );
        _updateLocationTrackingForStatus(event.status);
        _recoverHalowBootFromStatus(event.status);
      case EdgezMeshEventType.node:
        final node = event.node;
        if (node == null) return;
        final localNode = _state.status?.macAddress ?? 0;
        if (localNode != 0 && node.nodeNum == localNode) return;
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
        _recordTransportTraffic(
          byteCount: message.voiceBytes.isNotEmpty
              ? message.voiceBytes.length
              : utf8.encode(message.text).length,
          streamKey: null,
          sequence: null,
          receivedAtUs: message.timestampMs * 1000,
        );
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
        if (!message.mine) {
          _dispatchIncomingMessage(message, nodes[message.nodeNum]!);
        }
      case EdgezMeshEventType.voiceFrame:
        // BLE notifications are ordered. Keep decrypt + playback ordered too:
        // allowing asynchronous decryptions to overtake one another turns valid
        // 40 ms ADPCM frames into audible clicks and noise.
        _voiceFramePipeline = _voiceFramePipeline.then(
          (_) => _handleVoiceCallFrame(event.packet),
        );
      case EdgezMeshEventType.speedTestFrame:
        if (event.packet.length <= 6) return;
        var fromNode = 0;
        for (var index = 0; index < 6; index++) {
          fromNode = (fromNode << 8) | event.packet[index];
        }
        _handleSpeedTestFrame(
          fromNode,
          event.packet.sublist(6),
          receivedAtUs: event.receivedAtUs,
        );
      case EdgezMeshEventType.usbLinkStats:
        _setState(
          _state.copyWith(
            usbLinkStats: EdgezUsbLinkStats(
              sentPings: event.usbSentPings,
              receivedPings: event.usbReceivedPings,
              receivedPongs: event.usbReceivedPongs,
              timeouts: event.usbTimeouts,
              rttMs: event.usbRttMs,
            ),
          ),
        );
      case EdgezMeshEventType.voiceAudio:
        if (_state.voiceCall.isActive && event.packet.isNotEmpty) {
          _queueVoiceAudio(event.packet);
        }
      case EdgezMeshEventType.openManetComms:
        if (EdgezPublicChannels.isChannelNodeNum(event.talkgroupPort)) {
          final channel =
              EdgezPublicChannels.nodeForNodeNum(event.talkgroupPort)!;
          _setState(
            _state.copyWith(
              statusLine: 'Receiving ${channel.resolvedDisplayName}',
            ),
          );
        }
      case EdgezMeshEventType.otaProgress:
        _setState(
          _state.copyWith(
            otaInProgress: true,
            otaSentBytes: event.sentBytes,
            otaTotalBytes: event.totalBytes,
            statusLine: event.totalBytes <= 0
                ? 'Installing firmware'
                : 'Installing firmware: '
                    '${(event.progress * 100).floor()}%',
          ),
        );
      case EdgezMeshEventType.log:
        // Preserve a combined timeline: firmware records arrive as FW-tagged
        // events and transport/SDK diagnostics are explicitly APP-tagged.
        final timestamp = DateTime.now().toIso8601String().substring(11, 23);
        final source =
            event.log.startsWith('FW:') || event.log.startsWith('APP:')
                ? event.log
                : 'APP: ${event.log}';
        if (!source.startsWith('FW:') &&
            _appLogLevel.wireValue < _appEventLevel(event.log).wireValue) {
          _setState(_state.copyWith(statusLine: event.log));
          return;
        }
        final logs = List<String>.of(_state.debugLogs)
          ..add('$timestamp $source');
        if (logs.length > 500) {
          logs.removeRange(0, logs.length - 500);
        }
        _setState(_state.copyWith(statusLine: event.log, debugLogs: logs));
        final store = deviceLogStore;
        if (store != null) {
          unawaited(
            store
                .append(logs.last, configuredLevel: _appLogLevel)
                .catchError((_) {}),
          );
        }
    }
  }

  EdgezDeviceLogLevel _appEventLevel(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('error') || normalized.contains('failed')) {
      return EdgezDeviceLogLevel.error;
    }
    if (normalized.contains('warning') || normalized.contains('timeout')) {
      return EdgezDeviceLogLevel.warning;
    }
    return EdgezDeviceLogLevel.debug;
  }

  void _recordAppDiagnostic(EdgezDeviceLogLevel level, String message) {
    if (_appLogLevel.wireValue < level.wireValue) return;
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final logs = List<String>.of(_state.debugLogs)
      ..add('$timestamp APP: $message');
    if (logs.length > 500) {
      logs.removeRange(0, logs.length - 500);
    }
    _setState(_state.copyWith(debugLogs: logs));
    final store = deviceLogStore;
    if (store != null) {
      unawaited(
        store
            .append(logs.last, configuredLevel: _appLogLevel)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _refreshOtaReadiness() async {
    try {
      final ready = await sdk.isOtaReady();
      if (_state.connection == EdgezConnectionType.ble) {
        _setState(_state.copyWith(otaReady: ready));
      }
    } catch (_) {
      if (_state.connection == EdgezConnectionType.ble) {
        _setState(_state.copyWith(otaReady: false));
      }
    }
  }

  void _handlePacket(List<int> packetBytes, {required int receivedAtUs}) {
    if (packetBytes.isEmpty) return;
    final packet = _parseNetworkPacket(packetBytes);
    if (packet == null) return;
    _recordTransportTraffic(
      byteCount: packetBytes.length,
      streamKey: packet.hasMsg()
          ? 'protobuf:${packet.from}:${packet.msg.messageIdHigh}:'
              '${packet.msg.messageIdLow}'
          : null,
      sequence: packet.hasMsg() ? packet.msg.sequence : null,
      receivedAtUs: receivedAtUs,
    );

    if (packet.hasStatus()) {
      _deviceStatusTimeout?.cancel();
      final localNode = packet.status.macAddress.toInt();
      final nodes = Map<int, EdgezMeshNode>.of(_state.nodes)..remove(localNode);
      final status = EdgezMeshStatus(
        supported: packet.status.supported,
        stackInitialized: packet.status.stackInitialized,
        meshMode: packet.status.meshMode,
        linkUp: packet.status.linkUp,
        routeReady: packet.status.routeReady,
        readyForReport: packet.status.readyForReport,
        meshId: packet.status.meshId,
        ipAddress: packet.status.ipAddr,
        gateway: packet.status.gateway,
        macAddress: localNode,
        licenseStatus: EdgezLicenseStatus.fromWire(
          packet.status.licenseStatus.value,
        ),
        firmwareVersion: packet.status.firmwareVersion,
        publicChannelMask: packet.status.publicChannelMask,
        supportsPublicChannelMask: packet.status.hasPublicChannelMask(),
      );
      _setState(
        _state.copyWith(
          statusLine: 'Device status received',
          status: status,
          nodes: nodes,
        ),
      );
      _updateLocationTrackingForStatus(status);
      unawaited(_syncPublicChannelsIfNeeded(status));
      _recoverHalowBootFromStatus(status);
    }

    if (packet.hasDeviceSettings()) {
      final settings = packet.deviceSettings;
      _setState(_state.copyWith(
        statusLine: 'Device settings received',
        deviceSettings: EdgezDeviceSettings(
          deviceModeEnabled: settings.deviceModeEnabled,
          meshId: settings.meshId,
          shareLocation: settings.shareLocation,
          userName: settings.userName,
          marker: _markerId(settings.marker),
          beaconIntervalSeconds: settings.beaconIntervalSeconds,
          maxHop: settings.maxHop,
          latitude: settings.hasLatitude() ? settings.latitude : null,
          longitude: settings.hasLongitude() ? settings.longitude : null,
          geoFenceName: settings.hasGeoFence() ? settings.geoFence.name : '',
          geoIndex: settings.geoIndex,
          uartI2cSensorType: settings.uartI2cSensorType,
          rs485SensorType: settings.rs485SensorType,
          passphrase: settings.passphrase,
          upstreamWifiSsid: settings.upstreamWifiSsid,
          upstreamWifiPassphrase: settings.upstreamWifiPassphrase,
          beaconUnicast: settings.beaconUnicast.toInt(),
          deviceType: _deviceTypeLabel(settings.deviceType).toLowerCase(),
          sleepModeEnabled: settings.sleepModeEnabled,
          deviceGpsEnabled: settings.deviceGpsEnabled,
          meshFrequencyKhz: settings.meshFrequencyKhz,
          meshBandwidthMhz: settings.meshBandwidthMhz,
          userIdHigh: settings.userIdHigh.toInt(),
          userIdLow: settings.userIdLow.toInt(),
          userPublicKey: settings.userPublicKey,
          userPrivateKey: settings.userPrivateKey,
        ),
      ));
      if (settings.deviceGpsEnabled) {
        _stopLocationTracking();
      } else {
        _updateLocationTrackingForStatus(_state.status);
      }
    }

    if (packet.hasRoutingTable()) {
      _handleRoutingTable(packet);
    }

    if (packet.hasReport()) {
      _handleTopologyReport(packet);
    }

    if (packet.hasMsg() || packet.operation == proto.Operation.ACKNOWLEDGE) {
      unawaited(_handleConversationPacket(packet));
    }

    if (packet.hasBeacon()) {
      _handleBeacon(packet, packet.beacon);
    } else if (packet.hasPayload()) {
      unawaited(_handleLegacyBeaconPacket(packet));
    }
  }

  void _handleTopologyReport(proto.NetworkPacket packet) {
    final reporter = packet.from.toInt();
    if (reporter == 0) return;
    final localNode = _state.status?.macAddress ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const windowMs = 5 * 60 * 1000;
    final latestByPair = <String, EdgezTopologyLink>{};
    final sensorSamples =
        Map<int, List<EdgezSensorSample>>.of(_state.sensorSamples);
    final nodes = Map<int, EdgezMeshNode>.of(_state.nodes);
    for (final link in _state.topologyLinks) {
      if (link.lastSeenMs >= now - windowMs) {
        latestByPair[link.undirectedKey] = link;
      }
    }
    for (final peer in packet.report.peers) {
      final peerNode = peer.id.toInt();
      if (peerNode == 0 || (localNode != 0 && peerNode == localNode)) continue;
      final sensorData = _sensorData(peer.sensorData);
      if (sensorData != null) {
        sensorSamples[peerNode] = <EdgezSensorSample>[
          ...(sensorSamples[peerNode] ?? const <EdgezSensorSample>[]),
          EdgezSensorSample(
            nodeNum: peerNode,
            timestampMs: now,
            data: sensorData,
          ),
        ];
        if (sensorData.latitude != null && sensorData.longitude != null) {
          nodes[peerNode] = _nodeWithSensorLocation(
            nodeNum: peerNode,
            previous: nodes[peerNode],
            sensorData: sensorData,
            timestampMs: now,
          );
        }
      }
      if (peerNode == reporter) continue;
      final link = EdgezTopologyLink(
        reporterNodeNum: reporter,
        peerNodeNum: peerNode,
        encodedRssi: peer.rssi > 0 ? peer.rssi : 1000,
        lastSeenMs: now,
        routeTq: peer.routeTq,
        routeHops: peer.routeHops,
      );
      latestByPair[link.undirectedKey] = link;
    }
    final links = latestByPair.values.toList()
      ..sort((left, right) => right.lastSeenMs.compareTo(left.lastSeenMs));
    _setState(
      _state.copyWith(
        topologyLinks: links,
        sensorSamples: sensorSamples,
        nodes: nodes,
        statusLine: 'Topology report received',
      ),
    );
  }

  void _handleRoutingTable(proto.NetworkPacket packet) {
    if (packet.operation != proto.Operation.RESPONSE) return;
    _routingTableTimeout?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch;
    final routes = <EdgezBatmanRoute>[];
    _batmanPaths.clear();
    for (final entry in packet.routingTable.routes) {
      final destination = entry.destination.toInt();
      final nextHop = entry.nextHop.toInt();
      if (destination == 0 || nextHop == 0) continue;
      routes.add(
        EdgezBatmanRoute(
          destinationNodeNum: destination,
          nextHopNodeNum: nextHop,
          tq: entry.tq,
          hops: entry.hops,
          ageMs: entry.ageMs,
        ),
      );
      if (entry.tq > 0 && entry.hops > 0) {
        _batmanPaths[destination] = _BatmanPathMetric(
          tq: entry.tq,
          hops: entry.hops,
          updatedAtMs: now,
        );
      }
    }
    routes.sort((left, right) {
      final hopOrder = left.hops.compareTo(right.hops);
      return hopOrder != 0 ? hopOrder : right.tq.compareTo(left.tq);
    });
    _setState(
      _state.copyWith(
        routingTable: routes,
        routingTableLoading: false,
        statusLine: 'BATMAN routing table received (${routes.length} routes)',
      ),
    );
  }

  Future<void> _handleLegacyBeaconPacket(proto.NetworkPacket packet) async {
    final beacon = await sdk.decodeBeaconPayload(
      packet.payload,
      passphrase: _lastMeshConfig?.passphrase ?? '',
    );
    if (beacon != null) _handleBeacon(packet, beacon);
  }

  void _handleBeacon(proto.NetworkPacket packet, proto.Beacon beacon) {
    final nodeNum = packet.from.toInt();
    if (nodeNum == 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final decodedUser = _decodeBeaconUserName(
      beacon.userName,
      _markerId(beacon.marker),
    );
    if (beacon.userIdHigh.toInt() == 0 &&
        beacon.userIdLow.toInt() == 0 &&
        decodedUser.name.trim().isEmpty &&
        beacon.userPublicKey.isEmpty) {
      return;
    }
    final userUuid =
        _formatUuid(beacon.userIdHigh.toInt(), beacon.userIdLow.toInt());
    final localIdentity = _lastMeshConfig?.identity;
    final localNode = _state.status?.macAddress;
    final isLocalIdentity = localIdentity != null &&
        ((localIdentity.userUuid.isNotEmpty &&
                localIdentity.userUuid == userUuid) ||
            ((localIdentity.userIdHigh != 0 || localIdentity.userIdLow != 0) &&
                localIdentity.userIdHigh == beacon.userIdHigh.toInt() &&
                localIdentity.userIdLow == beacon.userIdLow.toInt()));
    if ((localNode != null && localNode != 0 && localNode == nodeNum) ||
        isLocalIdentity) {
      final sensorData = _sensorData(beacon.sensorData);
      final latitude = sensorData?.latitude ??
          (beacon.hasLatitude() ? beacon.latitude : null);
      final longitude = sensorData?.longitude ??
          (beacon.hasLongitude() ? beacon.longitude : null);
      if (latitude != null &&
          longitude != null &&
          latitude.isFinite &&
          longitude.isFinite &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180 &&
          (latitude != 0 || longitude != 0)) {
        _setState(_state.copyWith(
          selfLocation: EdgezLocation(
            latitude: latitude,
            longitude: longitude,
            timestampMs: now,
          ),
          statusLine: 'Device GPS location received',
        ));
      }
      return;
    }

    MapEntry<int, EdgezMeshNode>? previousEntry;
    for (final entry in _state.nodes.entries) {
      if (entry.key == nodeNum ||
          (userUuid.isNotEmpty && entry.value.userUuid == userUuid)) {
        previousEntry = entry;
        break;
      }
    }
    final previous = previousEntry?.value;
    final nextDeviceType = _deviceTypeLabel(beacon.deviceType);
    final hasGeoFence = beacon.hasGeoFence();
    final hasBeaconLocation = beacon.hasLatitude() &&
        beacon.hasLongitude() &&
        beacon.latitude.isFinite &&
        beacon.longitude.isFinite &&
        beacon.latitude >= -90 &&
        beacon.latitude <= 90 &&
        beacon.longitude >= -180 &&
        beacon.longitude <= 180 &&
        (beacon.latitude != 0 || beacon.longitude != 0);
    final node = EdgezMeshNode(
      nodeNum: nodeNum,
      userUuid: userUuid,
      displayName: decodedUser.name,
      route: _state.connection.name.toUpperCase(),
      lastSeenMs: now,
      marker: decodedUser.marker,
      publicKey: beacon.userPublicKey,
      latitude: hasBeaconLocation ? beacon.latitude : null,
      longitude: hasBeaconLocation ? beacon.longitude : null,
      deviceType: nextDeviceType == 'Unspecified'
          ? previous?.deviceType ?? nextDeviceType
          : nextDeviceType,
      geoFenceName:
          hasGeoFence ? beacon.geoFence.name : previous?.geoFenceName ?? '',
      geoIndex:
          hasGeoFence ? beacon.geoFence.geoIndex : previous?.geoIndex ?? 0,
      channelNumber: beacon.channelNumber,
      sleeping: beacon.sleeping,
    ).mergeDiscovery(previous);

    final nodes = Map<int, EdgezMeshNode>.of(_state.nodes);
    if (previousEntry != null && previousEntry.key != nodeNum) {
      nodes.remove(previousEntry.key);
    }
    nodes[nodeNum] = node;
    final sensorSamples =
        Map<int, List<EdgezSensorSample>>.of(_state.sensorSamples);
    if (previousEntry != null && previousEntry.key != nodeNum) {
      final previousSamples = sensorSamples.remove(previousEntry.key);
      if (previousSamples != null && sensorSamples[nodeNum] == null) {
        sensorSamples[nodeNum] = previousSamples;
      }
    }
    final sensorData = _sensorData(beacon.sensorData);
    if (sensorData != null) {
      sensorSamples[nodeNum] = <EdgezSensorSample>[
        ...(sensorSamples[nodeNum] ?? const <EdgezSensorSample>[]),
        EdgezSensorSample(nodeNum: nodeNum, timestampMs: now, data: sensorData),
      ];
      if (sensorData.latitude != null && sensorData.longitude != null) {
        nodes[nodeNum] = _nodeWithSensorLocation(
          nodeNum: nodeNum,
          previous: nodes[nodeNum],
          sensorData: sensorData,
          timestampMs: now,
        );
      }
    }

    _setState(
      _state.copyWith(
        nodes: nodes,
        sensorSamples: sensorSamples,
        statusLine: 'Beacon received from ${node.resolvedDisplayName}',
      ),
    );
  }

  EdgezMeshNode _nodeWithSensorLocation({
    required int nodeNum,
    required EdgezMeshNode? previous,
    required EdgezSensorData sensorData,
    required int timestampMs,
  }) {
    return EdgezMeshNode(
      nodeNum: nodeNum,
      userUuid: previous?.userUuid ?? '',
      displayName: previous?.displayName ?? '',
      route: previous?.route ?? 'HALOW',
      lastSeenMs: timestampMs,
      marker: previous?.marker ?? 'blue',
      publicKey: previous?.publicKey ?? const <int>[],
      latitude: sensorData.latitude,
      longitude: sensorData.longitude,
      deviceType: previous?.deviceType ?? 'Unknown',
      geoFenceName: previous?.geoFenceName ?? '',
      geoIndex: previous?.geoIndex ?? 0,
      channelNumber: previous?.channelNumber ?? 0,
      sleeping: previous?.sleeping ?? false,
    );
  }

  Future<void> _handleConversationPacket(proto.NetworkPacket packet) async {
    if (packet.operation == proto.Operation.ACKNOWLEDGE) {
      if (!packet.hasMsg()) return;
      _markMessageDelivered(
        _formatUuid(
          packet.msg.messageIdHigh.toInt(),
          packet.msg.messageIdLow.toInt(),
        ),
      );
      return;
    }
    if (!packet.hasMsg()) return;
    final message = packet.msg;
    if (message.mime == proto.Mime.MIME_BINARY) {
      _handleSpeedTestFrame(
        packet.from.toInt(),
        message.payload,
        receivedAtUs: 0,
        countTransportTraffic: false,
      );
      return;
    }
    if (message.mime != proto.Mime.MIME_TEXT &&
        message.mime != proto.Mime.MIME_VOICE) {
      return;
    }
    final config = _lastMeshConfig;
    final fromNode = packet.from.toInt();
    final toNode = packet.to.toInt();
    if (config == null || fromNode == 0) return;

    final sender = _state.nodes[fromNode];
    final publicChannel = EdgezPublicChannels.nodeForNodeNum(toNode);
    final now = DateTime.now().millisecondsSinceEpoch;
    final messageUuid = _formatUuid(
        message.messageIdHigh.toInt(), message.messageIdLow.toInt());
    String? text;
    String status = '';
    _CompletedVoiceMessage? completedVoice;
    if (publicChannel != null && message.mime == proto.Mime.MIME_TEXT) {
      try {
        text = sdk.decodePublicChannelText(message.payload);
      } catch (error) {
        status = error.toString();
        text = 'Unable to decode channel message';
      }
    } else if (publicChannel != null && message.mime == proto.Mime.MIME_VOICE) {
      EdgezVoiceChunk? chunk;
      try {
        chunk = sdk.decodePublicChannelVoiceChunk(message.payload);
      } catch (error) {
        status = error.toString();
      }
      if (chunk == null) {
        text = 'Unable to decode channel voice message';
      } else {
        completedVoice = _storeVoiceChunk(fromNode, chunk);
        if (completedVoice == null) return;
        text = 'Voice message';
      }
    } else if (sender == null) {
      text = 'Unable to decrypt message';
      status = 'Sender public key is missing';
    } else if (message.mime == proto.Mime.MIME_TEXT) {
      try {
        text = await sdk.decryptTextMessage(
          config: config,
          sender: sender,
          fromNode: fromNode,
          toNode: toNode,
          payload: message.payload,
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
          payload: message.payload,
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
        userUuid: '',
        displayName: 'Node ${fromNode.toRadixString(16)}',
        route: _state.connection.name.toUpperCase(),
        lastSeenMs: now,
        marker: 'blue',
        deviceType: 'User',
      ),
    );
    final conversationNode = publicChannel?.nodeNum ?? fromNode;
    final incomingMessage = EdgezConversationMessage(
      nodeNum: conversationNode,
      text: text,
      mine: false,
      timestampMs: now,
      messageUuid: messageUuid,
      status: status,
      voiceBytes: completedVoice?.bytes ?? const <int>[],
      voiceCodec: completedVoice?.codec ?? 0,
      durationMs: completedVoice?.durationMs ?? 0,
    );
    _appendMessage(
      incomingMessage,
      nodes: nodes,
      statusLine: 'Conversation message received',
    );
    _dispatchIncomingMessage(
      incomingMessage,
      publicChannel ?? nodes[fromNode]!,
    );

    final localNode = _state.status?.macAddress ?? 0;
    if (publicChannel == null &&
        localNode != 0 &&
        (message.messageIdHigh.toInt() != 0 ||
            message.messageIdLow.toInt() != 0)) {
      unawaited(
        sdk.sendConversationAck(
          config: config,
          fromNode: localNode,
          toNode: fromNode,
          messageIdHigh: message.messageIdHigh.toInt(),
          messageIdLow: message.messageIdLow.toInt(),
          maxHop: config.maxHop,
        ),
      );
    }
  }

  void _handleSpeedTestFrame(
    int fromNode,
    List<int> payload, {
    required int receivedAtUs,
    bool countTransportTraffic = true,
  }) {
    if (fromNode == 0) return;
    final frame = EdgezSpeedTestFrame.tryDecode(payload);
    if (frame == null) return;
    if (countTransportTraffic) {
      _recordTransportTraffic(
        byteCount: payload.length + 6,
        streamKey: frame.type == EdgezSpeedTestFrameType.data
            ? 'speed:$fromNode:${frame.transferId}'
            : null,
        sequence: frame.type == EdgezSpeedTestFrameType.data
            ? frame.chunkIndex
            : null,
        receivedAtUs: receivedAtUs,
      );
    }
    final key = '$fromNode:${frame.transferId}';
    if (frame.type == EdgezSpeedTestFrameType.repairRequest) {
      if (!speedTestReliableDelivery) return;
      final outgoing = _outgoingSpeedTests[key];
      if (outgoing == null ||
          outgoing.totalBytes != frame.totalBytes ||
          outgoing.totalChunks != frame.totalChunks) {
        _recordAppDiagnostic(
          EdgezDeviceLogLevel.warning,
          'Speed repair ignored from=0x${fromNode.toRadixString(16)} transfer=${frame.transferId}',
        );
        return;
      }
      outgoing.repairPipeline = outgoing.repairPipeline.then((_) async {
        await sdk.resendSpeedTestChunks(
          toNode: fromNode,
          hop: outgoing.hop,
          request: frame,
        );
      }).catchError((Object error) {
        _recordAppDiagnostic(
          EdgezDeviceLogLevel.warning,
          'Speed repair send failed transfer=${frame.transferId}: $error',
        );
      });
      return;
    }
    if (frame.type == EdgezSpeedTestFrameType.complete) {
      if (!speedTestReliableDelivery) return;
      _outgoingSpeedTests.remove(key)?.expiry?.cancel();
      return;
    }
    late final _PendingSpeedTest pending;
    if (frame.type == EdgezSpeedTestFrameType.start) {
      _pendingSpeedTests.remove(key)?.timer?.cancel();
      pending = _PendingSpeedTest(
        transferId: frame.transferId,
        totalBytes: frame.totalBytes,
        totalChunks: frame.totalChunks,
      );
      _pendingSpeedTests[key] = pending;
    } else {
      final existing = _pendingSpeedTests[key];
      if (existing == null) {
        _recordAppDiagnostic(
          EdgezDeviceLogLevel.warning,
          'Speed RX orphan type=${frame.type.name} from=0x${fromNode.toRadixString(16)} transfer=${frame.transferId}',
        );
        return;
      }
      pending = existing;
    }
    if (pending.totalBytes != frame.totalBytes ||
        pending.totalChunks != frame.totalChunks) {
      return;
    }
    if (frame.type == EdgezSpeedTestFrameType.data) {
      pending.put(
        frame.chunkIndex,
        frame.data.length,
        receivedAtUs > 0 ? receivedAtUs : DateTime.now().microsecondsSinceEpoch,
      );
      if (pending.shouldPublish) {
        _publishLinkStats(fromNode, pending, finalResult: false);
      }
    }
    if (frame.type == EdgezSpeedTestFrameType.end) {
      pending.endReceived = true;
      pending.repairDeadline = DateTime.now().add(speedTestInactivityTimeout);
    }
    pending.timer?.cancel();
    if (pending.endReceived && pending.complete) {
      _finishSpeedTest(key, fromNode);
      return;
    }
    if (pending.endReceived) {
      if (speedTestReliableDelivery) {
        _scheduleSpeedRepair(key, fromNode, pending);
      } else {
        // Best-effort measurements publish the loss they observed. Allow a
        // short reordering window after END, but never request retransmission.
        const maximumBestEffortReorderWindow = Duration(seconds: 2);
        final reorderWindow =
            speedTestInactivityTimeout < maximumBestEffortReorderWindow
                ? speedTestInactivityTimeout
                : maximumBestEffortReorderWindow;
        pending.timer = Timer(
          reorderWindow,
          () => _finishSpeedTest(key, fromNode),
        );
      }
    } else {
      // START can precede DATA by minutes while the radio queue drains. A
      // pre-END timeout is cleanup only and must never create a false 0/100
      // result or allow a later orphan END to create a second result.
      pending.timer = Timer(const Duration(minutes: 10), () {
        final stale = _pendingSpeedTests.remove(key);
        stale?.timer?.cancel();
        _recordAppDiagnostic(
          EdgezDeviceLogLevel.warning,
          'Speed RX discarded stale pre-END transfer=${frame.transferId} from=0x${fromNode.toRadixString(16)}',
        );
      });
    }
  }

  void _scheduleSpeedRepair(
    String key,
    int fromNode,
    _PendingSpeedTest pending,
  ) {
    pending.timer?.cancel();
    final deadline = pending.repairDeadline ??
        DateTime.now().add(speedTestInactivityTimeout);
    pending.repairDeadline = deadline;
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _finishSpeedTest(key, fromNode);
      return;
    }
    pending.repairAttempts++;
    unawaited(_sendSpeedRepairRequests(fromNode, pending));
    const retryInterval = Duration(seconds: 3);
    final delay = remaining < retryInterval ? remaining : retryInterval;
    pending.timer = Timer(delay, () {
      if (pending.complete) {
        _finishSpeedTest(key, fromNode);
      } else {
        _scheduleSpeedRepair(key, fromNode, pending);
      }
    });
  }

  Future<void> _sendSpeedRepairRequests(
    int fromNode,
    _PendingSpeedTest pending,
  ) async {
    const chunksPerBitmap = 448 * 8;
    final hop = _lastMeshConfig?.maxHop ?? 0;
    try {
      var segment = 0;
      for (var base = 0; base < pending.totalChunks; base += chunksPerBitmap) {
        final covered = min(chunksPerBitmap, pending.totalChunks - base);
        final bitmap = Uint8List((covered + 7) ~/ 8);
        var missing = false;
        for (var offset = 0; offset < covered; offset++) {
          if (pending.chunks.contains(base + offset)) continue;
          bitmap[offset ~/ 8] |= 1 << (offset & 7);
          missing = true;
        }
        if (!missing) continue;
        await sdk.sendSpeedTestRepairRequest(
          toNode: fromNode,
          hop: hop,
          sequence:
              pending.totalChunks + 3 + pending.repairAttempts * 16 + segment,
          frame: EdgezSpeedTestFrame.repairRequest(
            transferId: pending.transferId,
            totalBytes: pending.totalBytes,
            totalChunks: pending.totalChunks,
            baseChunk: base,
            missingBitmap: bitmap,
          ),
        );
        segment++;
      }
    } catch (error) {
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.warning,
        'Speed repair request failed transfer=${pending.transferId}: $error',
      );
    }
  }

  void _finishSpeedTest(String key, int fromNode) {
    final pending = _pendingSpeedTests.remove(key);
    if (pending == null) return;
    pending.timer?.cancel();
    if (speedTestReliableDelivery && pending.complete) {
      unawaited(
        sdk
            .sendSpeedTestComplete(
          toNode: fromNode,
          hop: _lastMeshConfig?.maxHop ?? 0,
          frame: EdgezSpeedTestFrame.complete(
            transferId: pending.transferId,
            totalBytes: pending.totalBytes,
            totalChunks: pending.totalChunks,
          ),
        )
            .catchError((Object error) {
          _recordAppDiagnostic(
            EdgezDeviceLogLevel.warning,
            'Speed completion ACK failed transfer=${pending.transferId}: $error',
          );
        }),
      );
    }
    _publishLinkStats(fromNode, pending, finalResult: true);
  }

  _RealtimePathProfile _realtimePathProfile(
    int targetNode,
    int requestedHops,
  ) {
    // A zero-hop request is explicitly direct. Let the bounded native BLE/USB
    // queue provide back-pressure instead of draining every two frames; the
    // latter serializes Flutter with the GATT callback and caps throughput.
    if (requestedHops == 0) {
      return const _RealtimePathProfile(6, Duration.zero, Duration.zero);
    }
    final localNode = _state.status?.macAddress ?? 0;
    final selected = localNode == 0 ? null : _batmanPaths[targetNode];
    final age = selected == null
        ? const Duration(days: 1)
        : Duration(
            milliseconds:
                DateTime.now().millisecondsSinceEpoch - selected.updatedAtMs,
          );
    final hops = requestedHops > 0 ? requestedHops : (selected?.hops ?? 0);
    final tq = age <= const Duration(seconds: 15) ? (selected?.tq ?? 0) : 0;

    if (tq >= 208 && hops <= 1) {
      return const _RealtimePathProfile(6, Duration.zero, Duration.zero);
    }
    if (tq >= 160 && hops <= 2) {
      return const _RealtimePathProfile(
        4,
        Duration(milliseconds: 2),
        Duration(milliseconds: 5),
      );
    }
    if (tq >= 112 || (tq == 0 && hops <= 1)) {
      return const _RealtimePathProfile(
        2,
        Duration(milliseconds: 6),
        Duration(milliseconds: 15),
      );
    }
    return const _RealtimePathProfile(
      1,
      Duration(milliseconds: 12),
      Duration(milliseconds: 30),
    );
  }

  void _recordTransportTraffic({
    required int byteCount,
    required String? streamKey,
    required int? sequence,
    required int receivedAtUs,
  }) {
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    // Native BLE/USB callbacks use an elapsed-realtime clock so packet timing
    // is captured before Flutter event batching. Translate that clock into the
    // Unix domain required by shared state and SQLite without losing deltas.
    final observationUs = receivedAtUs <= 0
        ? nowUs
        : receivedAtUs < 1000000000000000
            ? receivedAtUs +
                (_transportMonotonicToEpochOffsetUs ??= nowUs - receivedAtUs)
            : receivedAtUs;
    final snapshot = _trafficMeter.record(
      byteCount: byteCount,
      streamKey: streamKey,
      sequence: sequence,
      receivedAtUs: observationUs,
    );
    if (snapshot != null) {
      _setState(_state.copyWith(sharedLinkStats: snapshot));
    }
  }

  void _publishLinkStats(
    int fromNode,
    _PendingSpeedTest pending, {
    required bool finalResult,
  }) {
    final elapsedUs = max(1, pending.elapsedMicroseconds);
    final rawBitsPerSecond = pending.receivedBytes * 8 * 1000000 / elapsedUs;
    final expectedPackets = finalResult
        ? pending.totalChunks
        : max(1, pending.highestChunkIndex + 1);
    final lost = max(0, expectedPackets - pending.receivedChunks);
    final rawLossPercent = lost * 100 / expectedPackets;
    final now = DateTime.now().millisecondsSinceEpoch;
    pending.lastPublishedMs = now;
    final linkStats = Map<int, EdgezLinkStats>.of(_state.linkStats);
    final testStats = EdgezLinkStats(
      bitsPerSecond: rawBitsPerSecond,
      packetLossPercent: rawLossPercent,
      receivedPackets: pending.receivedChunks,
      expectedPackets: expectedPackets,
      updatedAtMs: now,
    );
    linkStats[fromNode] = testStats;
    _setState(
      _state.copyWith(
        linkStats: linkStats,
        sharedLinkStats: _state.sharedLinkStats,
      ),
    );
    if (finalResult) {
      if (_state.connection == EdgezConnectionType.usb) {
        unawaited(sdk.reportUsbPacketLoss(rawLossPercent));
      }
      unawaited(_sendSpeedTestResult(fromNode, testStats));
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.debug,
        'Speed result from=0x${fromNode.toRadixString(16)} bps=${rawBitsPerSecond.toStringAsFixed(0)} loss=${rawLossPercent.toStringAsFixed(2)}% received=${pending.receivedChunks}/$expectedPackets bytes=${pending.receivedBytes}',
      );
    }
  }

  Future<void> _sendSpeedTestResult(
    int senderNodeNum,
    EdgezLinkStats stats,
  ) async {
    final config = _lastMeshConfig;
    final sender = _state.nodes[senderNodeNum];
    final localNode = _state.status?.macAddress ?? 0;
    if (config == null || sender == null || localNode == 0) {
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.warning,
        'Speed result reply skipped: conversation identity unavailable',
      );
      return;
    }
    final text = 'Speed test result\n'
        'Average speed: ${_formatSpeedTestBitRate(stats.bitsPerSecond)}\n'
        'Packet loss: ${stats.packetLossPercent.toStringAsFixed(2)}%';
    final pendingUuid = 'speed-result-${stats.updatedAtMs}-$senderNodeNum';
    _appendMessage(
      EdgezConversationMessage(
        nodeNum: senderNodeNum,
        text: text,
        mine: true,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        messageUuid: pendingUuid,
        status: 'Queued',
      ),
      statusLine: 'Speed test result queued',
    );
    try {
      final messageUuid = await sdk.sendTextMessage(
        config: config,
        toNode: sender,
        fromNode: localNode,
        text: text,
        maxHop: config.maxHop,
        onPacketSent: (packetBytes, sequence) => _recordTransportTraffic(
          byteCount: packetBytes,
          streamKey: 'speed-result-tx:$senderNodeNum:${stats.updatedAtMs}',
          sequence: sequence,
          receivedAtUs: 0,
        ),
      );
      _replaceMessage(
        pendingUuid,
        messageUuid: messageUuid,
        status: 'Sent via ${_state.connection.name.toUpperCase()}',
        statusLine: 'Speed test result sent',
      );
    } catch (error) {
      _replaceMessage(
        pendingUuid,
        status: 'Failed: $error',
        statusLine: 'Speed test result failed: $error',
      );
      _recordAppDiagnostic(
        EdgezDeviceLogLevel.error,
        'Speed result reply failed: $error',
      );
    }
  }

  String _formatSpeedTestBitRate(double bitsPerSecond) {
    if (bitsPerSecond >= 1000000) {
      return '${(bitsPerSecond / 1000000).toStringAsFixed(2)} Mbps';
    }
    return '${(bitsPerSecond / 1000).toStringAsFixed(1)} kbps';
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
        return message.copyWith(
          messageUuid: messageUuid ?? message.messageUuid,
          status: status ?? message.status,
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
          statusLine: _state.connection != EdgezConnectionType.none
              ? 'Settings saved; waiting for device control service'
              : 'Settings saved; connect BLE or USB to initialize device',
        ),
      );
      return;
    }
    final initKey = _initKey(config);
    if (!force && _lastInitKey == initKey) return;
    if (_initInFlight) {
      // A reconnect can become ready while initialization from the previous
      // transport is still unwinding. Remember that ready event so the new
      // connection is initialized after the older request completes.
      _initRetryRequested = true;
      return;
    }

    _initInFlight = true;
    try {
      await sdk.initializeMesh(config);
      _lastInitKey = initKey;
      _setState(_state.copyWith(
        statusLine: 'Device initialization sent; requesting status',
      ));
      await sdk.requestDeviceSettings(identity: config.identity);
      _setState(_state.copyWith(
        statusLine: 'Waiting for device status response',
      ));
      _startDeviceStatusTimeout();
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Device init failed: $error'));
    } finally {
      _initInFlight = false;
      if (_initRetryRequested) {
        _initRetryRequested = false;
        if (_bleReady && _state.connection != EdgezConnectionType.none) {
          unawaited(_sendInitIfReady(force: true));
        }
      }
    }
  }

  Future<void> _authorizeAndInitializeUsb() async {
    try {
      _setState(
        _state.copyWith(statusLine: 'Authorizing SDK release over USB'),
      );
      // Firmware explicitly supports an init containing only the signed SDK
      // release credential. Complete that handshake before sending mesh config
      // or status/settings requests on a newly opened UART session.
      await sdk.authorizeSession();
      _setState(
        _state.copyWith(statusLine: 'SDK release sent; initializing mesh'),
      );
      await _sendInitIfReady(force: true);
    } catch (error) {
      _setState(
        _state.copyWith(statusLine: 'USB SDK authorization failed: $error'),
      );
    }
  }

  void _startLocationTracking() {
    final config = _lastMeshConfig;
    final status = _state.status;
    if (config == null ||
        !config.beacon.shareLocation ||
        config.beacon.useDeviceGps ||
        _state.deviceSettings?.deviceGpsEnabled == true ||
        !_bleReady ||
        status == null ||
        !status.meshMode ||
        !status.isUsable) {
      return;
    }
    // Refresh GPS at half the beacon interval. Do not restart this timer for
    // every repeated status packet: restarting also triggers an immediate GPS
    // update and was the source of overly frequent transmissions.
    final refreshInterval = Duration(
      seconds: max(5, (config.beacon.normalizedIntervalSeconds / 2).ceil()),
    );
    if (_locationUpdateTimer?.isActive == true &&
        _locationUpdateInterval == refreshInterval) {
      return;
    }
    _stopLocationTracking();
    _locationUpdateInterval = refreshInterval;
    unawaited(refreshSharedLocation());
    _locationUpdateTimer = Timer.periodic(
      refreshInterval,
      (_) => unawaited(refreshSharedLocation()),
    );
  }

  void _updateLocationTrackingForStatus(EdgezMeshStatus? status) {
    if (status != null && status.meshMode && status.isUsable) {
      _startLocationTracking();
    } else {
      _stopLocationTracking();
    }
  }

  void _stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _locationUpdateInterval = null;
  }

  bool _isValidSharedLocation(EdgezLocation location) {
    final latitude = location.latitude;
    final longitude = location.longitude;
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);
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

  void _startDeviceStatusTimeout() {
    _deviceStatusTimeout?.cancel();
    if (_state.status != null) return;
    _deviceStatusTimeout = Timer(deviceStatusTimeout, () {
      if (_state.connection != EdgezConnectionType.none &&
          _bleReady &&
          _state.status == null) {
        _setState(
          _state.copyWith(
            statusLine: 'No device status received. '
                'Reconnecting the BLE control channel.',
          ),
        );
        if (_state.connection == EdgezConnectionType.ble) {
          unawaited(_reconnectBleAfterStatusTimeout());
        }
      }
    });
  }

  void _recoverHalowBootFromStatus(EdgezMeshStatus? status) {
    if (status == null || status.stackInitialized) {
      _halowBootRetryTimer?.cancel();
      _halowBootRetryTimer = null;
      if (status?.stackInitialized == true) {
        _bleStatusReconnectAttempts = 0;
      }
      return;
    }
    if (_state.connection != EdgezConnectionType.ble ||
        !_bleReady ||
        _provisioning ||
        _lastMeshConfig == null ||
        _halowBootRetryTimer != null) {
      return;
    }
    // Let an INIT already being processed finish. If the next status still
    // reports an uninitialized stack, resend INIT; the firmware command is
    // intentionally idempotent.
    _halowBootRetryTimer = Timer(halowBootRetryDelay, () {
      _halowBootRetryTimer = null;
      final current = _state.status;
      if (_state.connection == EdgezConnectionType.ble &&
          _bleReady &&
          current != null &&
          !current.stackInitialized) {
        _recordAppDiagnostic(
          EdgezDeviceLogLevel.warning,
          'HaLow remains uninitialized; retrying INIT over BLE',
        );
        unawaited(_sendInitIfReady(force: true));
      }
    });
  }

  Future<void> _reconnectBleAfterStatusTimeout() async {
    final deviceId = _lastBleDeviceId;
    if (deviceId == null ||
        deviceId.isEmpty ||
        _bleRecoveryInFlight ||
        _state.connection != EdgezConnectionType.ble) {
      return;
    }
    if (_bleStatusReconnectAttempts >= 3) {
      _setState(_state.copyWith(
        statusLine: 'BLE connected but the device did not respond after '
            '3 reconnect attempts.',
      ));
      return;
    }
    _bleRecoveryInFlight = true;
    _bleStatusReconnectAttempts++;
    _lastInitKey = null;
    _bleReady = false;
    try {
      await sdk.disconnect();
      _setState(_state.copyWith(
        bleConnecting: true,
        bleReady: false,
        clearStatus: true,
        statusLine: 'Reconnecting BLE after missing device status '
            '($_bleStatusReconnectAttempts/3)',
      ));
      await sdk.connectBle(deviceId);
    } catch (error) {
      _setState(_state.copyWith(
        bleConnecting: false,
        statusLine: 'BLE recovery reconnect failed: $error',
      ));
    } finally {
      _bleRecoveryInFlight = false;
    }
  }

  List<int> _encodeVoiceCallPacket({
    required int type,
    required int callId,
    required int sequence,
    required List<int> audio,
  }) {
    final bytes = Uint8List(_callMagic.length + 1 + 8 + 4 + audio.length);
    bytes.setRange(0, _callMagic.length, _callMagic);
    final data = ByteData.sublistView(bytes);
    data.setUint8(4, type);
    data.setInt64(5, callId, Endian.little);
    data.setInt32(13, sequence, Endian.little);
    bytes.setRange(17, bytes.length, audio);
    return bytes;
  }

  _DecodedVoiceCallPacket? _decodeVoiceCallPacket(List<int> payload) {
    if (payload.length < 17) return null;
    for (var index = 0; index < _callMagic.length; index++) {
      if (payload[index] != _callMagic[index]) return null;
    }
    final bytes = Uint8List.fromList(payload);
    final data = ByteData.sublistView(bytes);
    return _DecodedVoiceCallPacket(
      type: data.getUint8(4),
      callId: data.getInt64(5, Endian.little),
      sequence: data.getInt32(13, Endian.little),
      audio: bytes.sublist(17),
    );
  }

  Future<void> _handleVoiceCallFrame(List<int> payload) async {
    final config = _lastMeshConfig;
    final localNode = _state.status?.macAddress ?? 0;
    if (config == null || localNode == 0 || payload.length < 6) return;
    var fromNode = 0;
    for (var index = 0; index < 6; index++) {
      fromNode = (fromNode << 8) | payload[index];
    }
    final sender = _state.nodes[fromNode];
    if (sender == null) return;
    try {
      final envelope = await sdk.decryptVoiceCallFrame(
        config: config,
        sender: sender,
        localNode: localNode,
        payload: payload,
      );
      final packet = _decodeVoiceCallPacket(envelope.plaintext);
      if (packet == null || packet.sequence != envelope.sequence) return;
      _recordTransportTraffic(
        byteCount: payload.length,
        streamKey: 'voice:$fromNode:${packet.callId}',
        sequence: packet.sequence,
        receivedAtUs: 0,
      );
      final call = _state.voiceCall;
      switch (packet.type) {
        case _callInvite:
          if (call.isIdle) {
            _voiceCallSequence = 1;
            final incomingCall = EdgezVoiceCallState(
              peerNodeNum: fromNode,
              callId: packet.callId,
              phase: EdgezVoiceCallPhase.incoming,
            );
            _setState(
              _state.copyWith(
                voiceCall: incomingCall,
                statusLine: 'Incoming call from ${sender.resolvedDisplayName}',
              ),
            );
            _scheduleVoiceCallTimeout(incomingCall);
            _dispatchIncomingCall(incomingCall, sender);
          }
        case _callAccept:
          if (call.phase == EdgezVoiceCallPhase.outgoing &&
              call.callId == packet.callId &&
              call.peerNodeNum == fromNode) {
            _voiceCallTimeout?.cancel();
            _setState(
              _state.copyWith(
                voiceCall: EdgezVoiceCallState(
                  peerNodeNum: fromNode,
                  callId: packet.callId,
                  phase: EdgezVoiceCallPhase.active,
                ),
                statusLine: 'Voice call active',
              ),
            );
          }
        case _callEnd:
          if (call.callId == packet.callId) await _resetVoiceCall();
        case _callAudio:
          if (call.isActive &&
              call.callId == packet.callId &&
              call.peerNodeNum == fromNode &&
              packet.audio.isNotEmpty) {
            await sdk.playLiveVoiceAudio(packet.audio);
          }
      }
    } catch (error) {
      _setState(_state.copyWith(statusLine: 'Voice call frame failed: $error'));
    }
  }

  proto.NetworkPacket? _parseNetworkPacket(List<int> bytes) {
    try {
      var payload = bytes;
      if (bytes.length >= 4 && bytes[0] == 0x45 && bytes[1] == 0x5a) {
        final payloadLength = bytes[2] | (bytes[3] << 8);
        if (payloadLength <= 512 && bytes.length >= payloadLength + 4) {
          payload = bytes.sublist(4, payloadLength + 4);
        }
      }
      return proto.NetworkPacket.fromBuffer(payload);
    } catch (_) {
      return null;
    }
  }

  EdgezSensorData? _sensorData(Iterable<proto.SensorData> values) {
    double? floatValue(proto.SensorType type) {
      for (final value in values) {
        if (value.type == type && value.hasFloatValue()) {
          return value.floatValue;
        }
      }
      return null;
    }

    int? intValue(proto.SensorType type) {
      for (final value in values) {
        if (value.type == type && value.hasIntValue()) return value.intValue;
      }
      return null;
    }

    final latitude = floatValue(proto.SensorType.SENSOR_LATITUDE);
    final longitude = floatValue(proto.SensorType.SENSOR_LONGITUDE);
    final hasInvalidZeroLocation = latitude == 0 && longitude == 0;
    final data = EdgezSensorData(
      latitude: hasInvalidZeroLocation ? null : latitude,
      longitude: hasInvalidZeroLocation ? null : longitude,
      temperature: floatValue(proto.SensorType.SENSOR_TEMPERATURE),
      humidity: floatValue(proto.SensorType.SENSOR_HUMIDITY),
      accelX: floatValue(proto.SensorType.SENSOR_ACCEL_X),
      accelY: floatValue(proto.SensorType.SENSOR_ACCEL_Y),
      accelZ: floatValue(proto.SensorType.SENSOR_ACCEL_Z),
      gyroX: floatValue(proto.SensorType.SENSOR_GYRO_X),
      gyroY: floatValue(proto.SensorType.SENSOR_GYRO_Y),
      gyroZ: floatValue(proto.SensorType.SENSOR_GYRO_Z),
      binaryLengthBytes: intValue(proto.SensorType.SENSOR_LENGTH),
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

  _DecodedBeaconUserName _decodeBeaconUserName(
    String userName,
    String protoMarker,
  ) {
    const separator = '|m=';
    final separatorIndex = userName.lastIndexOf(separator);
    if (separatorIndex < 0) {
      return _DecodedBeaconUserName(userName, protoMarker);
    }
    final suffixMarker = userName.substring(separatorIndex + separator.length);
    if (!_knownMarkerIds.contains(suffixMarker) || suffixMarker == 'default') {
      return _DecodedBeaconUserName(userName, protoMarker);
    }
    return _DecodedBeaconUserName(
      userName.substring(0, separatorIndex),
      protoMarker == 'default' ? suffixMarker : protoMarker,
    );
  }

  String _markerId(proto.MarkerColor marker) {
    return switch (marker) {
      proto.MarkerColor.MARKER_RED => 'red',
      proto.MarkerColor.MARKER_BLUE => 'blue',
      proto.MarkerColor.MARKER_PURPLE => 'purple',
      proto.MarkerColor.MARKER_YELLOW => 'yellow',
      proto.MarkerColor.MARKER_PINK => 'pink',
      proto.MarkerColor.MARKER_BROWN => 'brown',
      proto.MarkerColor.MARKER_GREEN => 'green',
      proto.MarkerColor.MARKER_ORANGE => 'orange',
      proto.MarkerColor.MARKER_DEEP_PURPLE => 'deep_purple',
      proto.MarkerColor.MARKER_LIGHT_BLUE => 'light_blue',
      proto.MarkerColor.MARKER_CYAN => 'cyan',
      proto.MarkerColor.MARKER_TEAL => 'teal',
      proto.MarkerColor.MARKER_LIME => 'lime',
      proto.MarkerColor.MARKER_DEEP_ORANGE => 'deep_orange',
      proto.MarkerColor.MARKER_GRAY => 'gray',
      proto.MarkerColor.MARKER_BLUE_GRAY => 'blue_gray',
      _ => 'default',
    };
  }

  String _deviceTypeLabel(proto.DeviceType type) {
    return switch (type) {
      proto.DeviceType.DEVICE_TYPE_USER => 'User',
      proto.DeviceType.DEVICE_TYPE_GATEWAY => 'Gateway',
      proto.DeviceType.DEVICE_TYPE_BEACON => 'Beacon',
      proto.DeviceType.DEVICE_TYPE_SENSOR => 'Sensor',
      proto.DeviceType.DEVICE_TYPE_RELAY => 'Relay',
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

  void _dispatchIncomingMessage(
    EdgezConversationMessage message,
    EdgezMeshNode sender,
  ) {
    try {
      onIncomingMessage?.call(message, sender);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'edgez_flutter_sdk',
          context: ErrorDescription('while handling an incoming message'),
        ),
      );
    }
  }

  void _dispatchIncomingCall(
    EdgezVoiceCallState call,
    EdgezMeshNode caller,
  ) {
    try {
      onIncomingCall?.call(call, caller);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'edgez_flutter_sdk',
          context: ErrorDescription('while handling an incoming call'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _deviceStatusTimeout?.cancel();
    _halowBootRetryTimer?.cancel();
    _routingTableTimeout?.cancel();
    _stopLocationTracking();
    _voiceCallTimeout?.cancel();
    _pendingVoiceMessages.clear();
    for (final pending in _pendingSpeedTests.values) {
      pending.timer?.cancel();
    }
    _pendingSpeedTests.clear();
    for (final outgoing in _outgoingSpeedTests.values) {
      outgoing.expiry?.cancel();
    }
    _outgoingSpeedTests.clear();
    _batmanPaths.clear();
    _trafficMeter.clear();
    _subscription.cancel();
    super.dispose();
  }
}

class _TransportTrafficMeter {
  static const int _windowUs = 10 * 1000000;
  static const int _publishIntervalUs = 1000000;
  final ListQueue<_TrafficObservation> _observations =
      ListQueue<_TrafficObservation>();
  final LinkedHashMap<String, int> _lastSequence = LinkedHashMap<String, int>();
  int _lastPublishedUs = 0;

  EdgezLinkStats? record({
    required int byteCount,
    required String? streamKey,
    required int? sequence,
    required int receivedAtUs,
  }) {
    if (byteCount <= 0) return null;
    var lostBefore = 0;
    if (streamKey != null && sequence != null && sequence >= 0) {
      final previous = _lastSequence.remove(streamKey);
      if (previous != null && sequence > previous + 1) {
        lostBefore = sequence - previous - 1;
      }
      _lastSequence[streamKey] = max(previous ?? sequence, sequence);
      while (_lastSequence.length > 256) {
        _lastSequence.remove(_lastSequence.keys.first);
      }
    }
    _observations.addLast(
      _TrafficObservation(
        receivedAtUs,
        byteCount,
        lostBefore,
        streamKey != null && sequence != null && sequence >= 0,
      ),
    );
    final cutoff = receivedAtUs - _windowUs;
    while (
        _observations.isNotEmpty && _observations.first.receivedAtUs < cutoff) {
      _observations.removeFirst();
    }
    if (_lastPublishedUs != 0 &&
        receivedAtUs - _lastPublishedUs < _publishIntervalUs) {
      return null;
    }
    _lastPublishedUs = receivedAtUs;
    final bytes = _observations.fold<int>(
      0,
      (sum, item) => sum + item.byteCount,
    );
    final lost = _observations.fold<int>(
      0,
      (sum, item) => sum + item.lostBefore,
    );
    final received = _observations.where((item) => item.sequenced).length;
    final expected = received + lost;
    final spanUs = max(
      1000000,
      _observations.last.receivedAtUs - _observations.first.receivedAtUs,
    );
    return EdgezLinkStats(
      bitsPerSecond: bytes * 8 * 1000000 / spanUs,
      packetLossPercent: expected == 0 ? 0 : lost * 100 / expected,
      receivedPackets: received,
      expectedPackets: expected,
      updatedAtMs: receivedAtUs ~/ 1000,
    );
  }

  void clear() {
    _observations.clear();
    _lastSequence.clear();
    _lastPublishedUs = 0;
  }
}

class _TrafficObservation {
  const _TrafficObservation(
    this.receivedAtUs,
    this.byteCount,
    this.lostBefore,
    this.sequenced,
  );

  final int receivedAtUs;
  final int byteCount;
  final int lostBefore;
  final bool sequenced;
}

class _DecodedBeaconUserName {
  const _DecodedBeaconUserName(this.name, this.marker);

  final String name;
  final String marker;
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

class _PendingSpeedTest {
  static const int _publishIntervalMs = 1000;

  _PendingSpeedTest({
    required this.transferId,
    required this.totalBytes,
    required this.totalChunks,
  });

  final int transferId;
  final int totalBytes;
  final int totalChunks;
  final Set<int> chunks = <int>{};
  int receivedBytes = 0;
  int? firstDataUs;
  int? lastDataUs;
  int lastPublishedMs = 0;
  int highestChunkIndex = -1;
  bool endReceived = false;
  int repairAttempts = 0;
  DateTime? repairDeadline;
  Timer? timer;

  int get receivedChunks => chunks.length;
  bool get complete => receivedChunks >= totalChunks;
  // Keep the result display responsive without rebuilding it for every radio
  // frame. One update per second is cheap compared with the transport work.
  bool get shouldPublish =>
      lastDataUs != null &&
      lastDataUs! ~/ 1000 - lastPublishedMs >= _publishIntervalMs;
  int get elapsedMicroseconds {
    final first = firstDataUs;
    final last = lastDataUs;
    if (first == null || last == null) return 1;
    return max(1, last - first);
  }

  void put(int index, int byteCount, int receivedAtUs) {
    if (index < 0 || index >= totalChunks || byteCount < 0) return;
    if (!chunks.add(index)) return;
    if (firstDataUs == null) {
      firstDataUs = receivedAtUs;
      lastPublishedMs = receivedAtUs ~/ 1000;
    }
    lastDataUs = max(lastDataUs ?? receivedAtUs, receivedAtUs);
    highestChunkIndex = max(highestChunkIndex, index);
    receivedBytes += byteCount;
  }
}

class _OutgoingSpeedTest {
  _OutgoingSpeedTest({
    required this.totalBytes,
    required this.totalChunks,
    required this.hop,
  });

  final int totalBytes;
  final int totalChunks;
  final int hop;
  Timer? expiry;
  Future<void> repairPipeline = Future<void>.value();
}

class _RealtimePathProfile {
  const _RealtimePathProfile(
    this.speedDrainBatchChunks,
    this.speedPacingDelay,
    this.voicePacingDelay,
  );

  final int speedDrainBatchChunks;
  final Duration speedPacingDelay;
  final Duration voicePacingDelay;
}

class _BatmanPathMetric {
  const _BatmanPathMetric({
    required this.tq,
    required this.hops,
    required this.updatedAtMs,
  });

  final int tq;
  final int hops;
  final int updatedAtMs;
}

class _DecodedVoiceCallPacket {
  const _DecodedVoiceCallPacket({
    required this.type,
    required this.callId,
    required this.sequence,
    required this.audio,
  });

  final int type;
  final int callId;
  final int sequence;
  final List<int> audio;
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
