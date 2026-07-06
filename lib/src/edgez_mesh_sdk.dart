import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'proto/edgez_mesh.pb.dart' as proto;

class EdgezMeshSdk {
  EdgezMeshSdk({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methods =
            methodChannel ?? const MethodChannel('edgez_flutter_sdk/methods'),
        _events =
            eventChannel ?? const EventChannel('edgez_flutter_sdk/events');

  final MethodChannel _methods;
  final EventChannel _events;
  static const _voiceChunkAudioBytes = 290;

  Stream<EdgezMeshEvent>? _meshEvents;

  Stream<EdgezMeshEvent> get events {
    return _meshEvents ??= _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map(
          (event) =>
              EdgezMeshEvent.fromMap((event as Map).cast<Object?, Object?>()),
        );
  }

  Future<void> startBleScan() {
    return _methods.invokeMethod<void>('startBleScan');
  }

  Future<void> stopBleScan() {
    return _methods.invokeMethod<void>('stopBleScan');
  }

  Future<void> connectBle(String deviceId) {
    return _methods.invokeMethod<void>('connectBle', {'deviceId': deviceId});
  }

  Future<void> disconnect() {
    return _methods.invokeMethod<void>('disconnect');
  }

  Future<bool> requestMicrophonePermission() async {
    return await _methods.invokeMethod<bool>('requestMicrophonePermission') ??
        false;
  }

  Future<void> startVoiceRecording() async {
    final permitted = await requestMicrophonePermission();
    if (!permitted) {
      throw StateError('Microphone permission denied');
    }
    await _methods.invokeMethod<void>('startVoiceRecording');
  }

  Future<EdgezVoiceRecording?> stopVoiceRecording({bool send = true}) async {
    final result = await _methods.invokeMethod<Object?>(
      'stopVoiceRecording',
      {'send': send},
    );
    if (result is! Map) return null;
    final map = result.cast<Object?, Object?>();
    final bytes = map['bytes'];
    return EdgezVoiceRecording(
      bytes: bytes is List ? List<int>.from(bytes) : const <int>[],
      durationMs: map['durationMs'] as int? ?? 0,
      codec: map['codec'] as int? ?? 0,
    );
  }

  Future<void> playVoiceMessage(EdgezConversationMessage message) {
    if (message.voiceBytes.isEmpty) {
      throw StateError('Voice message has no audio bytes');
    }
    return _methods.invokeMethod<void>('playVoiceMessage', {
      'bytes': Uint8List.fromList(message.voiceBytes),
      'codec': message.voiceCodec,
    });
  }

  Future<void> initializeMesh(EdgezMeshConfig config) {
    final packet = proto.NetworkPacket(
      operation: proto.Operation.REQUEST,
      interface: proto.Interface.HALOW,
      userHigh: Int64(config.identity.userIdHigh),
      userLow: Int64(config.identity.userIdLow),
      init: proto.HaLowInitConfig(
        countryCode: _take(config.countryCode.toUpperCase(), 2),
        meshId: _take(config.meshId, 32),
        passphrase: _take(config.passphrase, 64),
        maxHop: config.maxHop.clamp(0, 255),
        userIdHigh: Int64(config.identity.userIdHigh),
        userIdLow: Int64(config.identity.userIdLow),
        userName: _take(config.identity.name, 64),
        userPublicKey: config.identity.publicKey.take(32).toList(),
      ),
    );
    return _methods.invokeMethod<void>('initializeMesh', {
      ...config.toMap(),
      'packet': Uint8List.fromList(packet.writeToBuffer()),
    });
  }

  Future<void> requestDeviceSettings({EdgezUserIdentity? identity}) {
    final packet = proto.NetworkPacket(
      operation: proto.Operation.REQUEST,
      interface: proto.Interface.HALOW,
      userHigh: identity == null ? null : Int64(identity.userIdHigh),
      userLow: identity == null ? null : Int64(identity.userIdLow),
      deviceSettings: proto.DeviceSettings(
        action: proto.DeviceSettingsAction.DEVICE_SETTINGS_GET,
      ),
    );
    return _methods.invokeMethod<void>('sendPacket', {
      'label': 'Device settings request',
      'packet': Uint8List.fromList(packet.writeToBuffer()),
    });
  }

  Future<void> sendBeacon(EdgezMeshConfig config) async {
    final beacon = proto.Beacon(
      userIdHigh: Int64(config.identity.userIdHigh),
      userIdLow: Int64(config.identity.userIdLow),
      userName: _beaconUserName(config.identity.name, config.beacon.marker),
      userPublicKey: config.identity.publicKey.take(32).toList(),
      marker: _markerColor(config.beacon.marker),
      deviceType: proto.DeviceType.DEVICE_TYPE_USER,
      beaconIntervalSeconds: config.beacon.normalizedIntervalSeconds,
    );
    if (config.beacon.shareLocation &&
        config.beacon.latitude != null &&
        config.beacon.longitude != null) {
      beacon.attitude = config.beacon.latitude!;
      beacon.longitude = config.beacon.longitude!;
    }

    final beaconBytes = beacon.writeToBuffer();
    final payload = config.passphrase.isEmpty
        ? beaconBytes
        : await _encryptBeacon(beaconBytes, config.passphrase);
    final packet = proto.NetworkPacket(
      operation: proto.Operation.REQUEST,
      interface: proto.Interface.HALOW,
      userHigh: Int64(config.identity.userIdHigh),
      userLow: Int64(config.identity.userIdLow),
      maxHop: config.maxHop.clamp(0, 255),
      beacon: base64Encode(payload),
    );
    return _methods.invokeMethod<void>('sendPacket', {
      'label': 'Beacon',
      'packet': Uint8List.fromList(packet.writeToBuffer()),
    });
  }

  String _take(String value, int maxLength) {
    return value.length > maxLength ? value.substring(0, maxLength) : value;
  }

  String _beaconUserName(String userName, String marker) {
    final normalizedName = userName.trim().isEmpty ? 'EdgeZ User' : userName;
    final normalizedMarker = _normalizeMarker(marker);
    if (normalizedMarker == 'default') return _take(normalizedName, 64);
    final suffix = '|m=$normalizedMarker';
    return _take(normalizedName, (64 - suffix.length).clamp(0, 64)) + suffix;
  }

  proto.MarkerColor _markerColor(String marker) {
    return switch (_normalizeMarker(marker)) {
      'red' => proto.MarkerColor.MARKER_RED,
      'purple' => proto.MarkerColor.MARKER_PURPLE,
      'yellow' => proto.MarkerColor.MARKER_YELLOW,
      'pink' => proto.MarkerColor.MARKER_PINK,
      'brown' => proto.MarkerColor.MARKER_BROWN,
      'green' => proto.MarkerColor.MARKER_GREEN,
      'orange' => proto.MarkerColor.MARKER_ORANGE,
      'deep_purple' => proto.MarkerColor.MARKER_DEEP_PURPLE,
      'light_blue' => proto.MarkerColor.MARKER_LIGHT_BLUE,
      'cyan' => proto.MarkerColor.MARKER_CYAN,
      'teal' => proto.MarkerColor.MARKER_TEAL,
      'lime' => proto.MarkerColor.MARKER_LIME,
      'deep_orange' => proto.MarkerColor.MARKER_DEEP_ORANGE,
      'gray' => proto.MarkerColor.MARKER_GRAY,
      'blue_gray' => proto.MarkerColor.MARKER_BLUE_GRAY,
      'default' => proto.MarkerColor.MARKER_DEFAULT,
      _ => proto.MarkerColor.MARKER_BLUE,
    };
  }

  String _normalizeMarker(String marker) {
    const markers = {
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
    return markers.contains(marker) ? marker : 'default';
  }

  Future<List<int>> _encryptBeacon(List<int> payload, String passphrase) async {
    final random = Random.secure();
    final nonce = List<int>.generate(12, (_) => random.nextInt(256));
    final keyHash = await Sha256().hash(utf8.encode(passphrase));
    final secretKey = SecretKey(keyHash.bytes);
    final secretBox = await AesGcm.with256bits().encrypt(
      payload,
      secretKey: secretKey,
      nonce: nonce,
    );
    return <int>[
      0x45,
      0x5a,
      0x42,
      0x01,
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];
  }

  Future<String> sendTextMessage({
    required EdgezMeshConfig config,
    required EdgezMeshNode toNode,
    required int fromNode,
    required String text,
    int maxHop = 0,
  }) async {
    final messageId = _newMessageId();
    final encrypted = await _encryptConversationPayload(
      identity: config.identity,
      recipient: toNode,
      fromNode: fromNode,
      plaintext: utf8.encode(text),
    );
    final packet = proto.NetworkPacket(
      messageIdHigh: Int64(messageId.$1),
      messageIdLow: Int64(messageId.$2),
      from: Int64(fromNode),
      to: Int64(toNode.nodeNum),
      operation: proto.Operation.REQUEST,
      interface: proto.Interface.HALOW,
      sequence: 1,
      userHigh: Int64(config.identity.userIdHigh),
      userLow: Int64(config.identity.userIdLow),
      mime: proto.Mime.MIME_TEXT,
      maxHop: maxHop.clamp(0, 255),
      payload: _conversationPayload(encrypted.nonce, encrypted.ciphertext),
    );
    await _methods.invokeMethod<void>('sendPacket', {
      'label': 'Conversation message',
      'packet': Uint8List.fromList(packet.writeToBuffer()),
    });
    return _formatUuid(messageId.$1, messageId.$2);
  }

  Future<String> decryptTextMessage({
    required EdgezMeshConfig config,
    required EdgezMeshNode sender,
    required int fromNode,
    required int toNode,
    required List<int> payload,
  }) async {
    final parsed = _parseConversationPayload(payload);
    if (parsed == null) {
      return utf8.decode(payload, allowMalformed: true);
    }
    final plaintext = await _decryptConversationPayload(
      identity: config.identity,
      sender: sender,
      fromNode: fromNode,
      toNode: toNode,
      nonce: parsed.nonce,
      ciphertext: parsed.ciphertext,
    );
    return utf8.decode(plaintext);
  }

  Future<String> sendVoiceMessage({
    required EdgezMeshConfig config,
    required EdgezMeshNode toNode,
    required int fromNode,
    required List<int> bytes,
    required int durationMs,
    required int codec,
    int maxHop = 0,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Voice payload is empty');
    }
    final messageId = _newMessageId();
    final groupId = _newSignedInt64();
    final totalChunks = (bytes.length / _voiceChunkAudioBytes).ceil();
    for (var index = 0; index < totalChunks; index++) {
      final start = index * _voiceChunkAudioBytes;
      final end = min(start + _voiceChunkAudioBytes, bytes.length);
      final voiceChunk = _encodeVoiceChunk(
        groupId: groupId,
        durationMs: durationMs,
        totalChunks: totalChunks,
        index: index,
        codec: codec,
        audio: bytes.sublist(start, end),
      );
      final encrypted = await _encryptConversationPayload(
        identity: config.identity,
        recipient: toNode,
        fromNode: fromNode,
        plaintext: voiceChunk,
      );
      final packet = proto.NetworkPacket(
        messageIdHigh: Int64(messageId.$1),
        messageIdLow: Int64(messageId.$2),
        from: Int64(fromNode),
        to: Int64(toNode.nodeNum),
        operation: proto.Operation.REQUEST,
        interface: proto.Interface.HALOW,
        sequence: index + 1,
        userHigh: Int64(config.identity.userIdHigh),
        userLow: Int64(config.identity.userIdLow),
        mime: proto.Mime.MIME_VOICE,
        maxHop: maxHop.clamp(0, 255),
        payload: _conversationPayload(encrypted.nonce, encrypted.ciphertext),
      );
      await _methods.invokeMethod<void>('sendPacket', {
        'label': 'Voice chunk ${index + 1}/$totalChunks',
        'packet': Uint8List.fromList(packet.writeToBuffer()),
      });
    }
    return _formatUuid(messageId.$1, messageId.$2);
  }

  Future<EdgezVoiceChunk> decryptVoiceChunk({
    required EdgezMeshConfig config,
    required EdgezMeshNode sender,
    required int fromNode,
    required int toNode,
    required List<int> payload,
  }) async {
    final parsed = _parseConversationPayload(payload);
    if (parsed == null) {
      throw StateError('Conversation voice payload is missing');
    }
    final plaintext = await _decryptConversationPayload(
      identity: config.identity,
      sender: sender,
      fromNode: fromNode,
      toNode: toNode,
      nonce: parsed.nonce,
      ciphertext: parsed.ciphertext,
    );
    final chunk = _decodeVoiceChunk(plaintext);
    if (chunk == null) {
      throw StateError('Voice chunk is malformed');
    }
    return chunk;
  }

  Future<void> sendConversationAck({
    required EdgezMeshConfig config,
    required int fromNode,
    required int toNode,
    required int messageIdHigh,
    required int messageIdLow,
    int maxHop = 0,
  }) {
    final packet = proto.NetworkPacket(
      messageIdHigh: Int64(messageIdHigh),
      messageIdLow: Int64(messageIdLow),
      from: Int64(fromNode),
      to: Int64(toNode),
      operation: proto.Operation.ACKNOWLEDGE,
      interface: proto.Interface.HALOW,
      userHigh: Int64(config.identity.userIdHigh),
      userLow: Int64(config.identity.userIdLow),
      mime: proto.Mime.MIME_TEXT,
      maxHop: maxHop.clamp(0, 255),
    );
    return _methods.invokeMethod<void>('sendPacket', {
      'label': 'Conversation ACK',
      'packet': Uint8List.fromList(packet.writeToBuffer()),
    });
  }

  Future<_ConversationPayload> _encryptConversationPayload({
    required EdgezUserIdentity identity,
    required EdgezMeshNode recipient,
    required int fromNode,
    required List<int> plaintext,
  }) async {
    if (identity.privateKey.length != 32 || identity.publicKey.length != 32) {
      throw StateError('Local user key pair is missing');
    }
    if (recipient.publicKey.length != 32) {
      throw StateError('Remote user public key is missing');
    }
    final random = Random.secure();
    final nonce = List<int>.generate(12, (_) => random.nextInt(256));
    final key = await _conversationKey(
      identity: identity,
      localNode: fromNode,
      peerNode: recipient.nodeNum,
      peerPublicKey: recipient.publicKey,
    );
    final secretBox = await AesGcm.with256bits().encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: _conversationAad(fromNode, recipient.nodeNum, nonce),
    );
    return _ConversationPayload(
      nonce: nonce,
      ciphertext: <int>[
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ],
    );
  }

  List<int> _encodeVoiceChunk({
    required int groupId,
    required int durationMs,
    required int totalChunks,
    required int index,
    required int codec,
    required List<int> audio,
  }) {
    final data = ByteData(3 + 8 + 4 + 2 + 2 + 1 + audio.length);
    final out = data.buffer.asUint8List();
    out[0] = 0x45;
    out[1] = 0x56;
    out[2] = 0x32;
    data.setInt64(3, groupId, Endian.little);
    data.setInt32(11, durationMs.clamp(0, 0x7fffffff).toInt(), Endian.little);
    data.setUint16(15, totalChunks.clamp(0, 0xffff).toInt(), Endian.little);
    data.setUint16(17, index.clamp(0, 0xffff).toInt(), Endian.little);
    data.setUint8(19, codec.clamp(0, 0xff).toInt());
    out.setRange(20, 20 + audio.length, audio);
    return out;
  }

  EdgezVoiceChunk? _decodeVoiceChunk(List<int> payload) {
    if (payload.length < 20) return null;
    if (payload[0] != 0x45 || payload[1] != 0x56 || payload[2] != 0x32) {
      return null;
    }
    final data = ByteData.sublistView(Uint8List.fromList(payload));
    final groupId = data.getInt64(3, Endian.little);
    final durationMs =
        data.getInt32(11, Endian.little).clamp(0, 0x7fffffff).toInt();
    final totalChunks = data.getUint16(15, Endian.little);
    final index = data.getUint16(17, Endian.little);
    final codec = data.getUint8(19);
    final audio = payload.sublist(20);
    if (totalChunks <= 0 || index >= totalChunks || audio.isEmpty) {
      return null;
    }
    return EdgezVoiceChunk(
      groupId: groupId,
      durationMs: durationMs,
      totalChunks: totalChunks,
      index: index,
      codec: codec,
      audio: audio,
    );
  }

  Future<List<int>> _decryptConversationPayload({
    required EdgezUserIdentity identity,
    required EdgezMeshNode sender,
    required int fromNode,
    required int toNode,
    required List<int> nonce,
    required List<int> ciphertext,
  }) async {
    if (identity.privateKey.length != 32 || identity.publicKey.length != 32) {
      throw StateError('Local user key pair is missing');
    }
    if (sender.publicKey.length != 32) {
      throw StateError('Sender public key is missing');
    }
    if (ciphertext.length < 16) {
      throw StateError('Conversation ciphertext is malformed');
    }
    final key = await _conversationKey(
      identity: identity,
      localNode: toNode,
      peerNode: sender.nodeNum,
      peerPublicKey: sender.publicKey,
    );
    final secretBox = SecretBox(
      ciphertext.sublist(0, ciphertext.length - 16),
      nonce: nonce,
      mac: Mac(ciphertext.sublist(ciphertext.length - 16)),
    );
    return AesGcm.with256bits().decrypt(
      secretBox,
      secretKey: key,
      aad: _conversationAad(fromNode, toNode, nonce),
    );
  }

  Future<SecretKey> _conversationKey({
    required EdgezUserIdentity identity,
    required int localNode,
    required int peerNode,
    required List<int> peerPublicKey,
  }) async {
    final keyPair = SimpleKeyPairData(
      identity.privateKey,
      publicKey: SimplePublicKey(identity.publicKey, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final sharedSecret = await X25519().sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(peerPublicKey, type: KeyPairType.x25519),
    );
    final sharedBytes = await sharedSecret.extractBytes();
    final firstIsLocal = _compareIdentityKeys(
            localNode, identity.publicKey, peerNode, peerPublicKey) <=
        0;
    final digestInput = <int>[
      ...utf8.encode('EdgeZ conversation v1'),
      ...sharedBytes,
      if (firstIsLocal) ..._identityKeyBytes(localNode, identity.publicKey),
      if (firstIsLocal) ..._identityKeyBytes(peerNode, peerPublicKey),
      if (!firstIsLocal) ..._identityKeyBytes(peerNode, peerPublicKey),
      if (!firstIsLocal) ..._identityKeyBytes(localNode, identity.publicKey),
    ];
    final hash = await Sha256().hash(digestInput);
    return SecretKey(hash.bytes);
  }

  List<int> _conversationAad(
      int senderNode, int recipientNode, List<int> nonce) {
    final data = ByteData(18 + nonce.length);
    data.setInt64(0, senderNode, Endian.little);
    data.setInt64(8, recipientNode, Endian.little);
    data.setUint16(16, nonce.length, Endian.little);
    return <int>[...data.buffer.asUint8List(0, 18), ...nonce];
  }

  List<int> _identityKeyBytes(int node, List<int> publicKey) {
    final data = ByteData(8);
    data.setInt64(0, node, Endian.little);
    return <int>[...data.buffer.asUint8List(), ...publicKey];
  }

  int _compareIdentityKeys(
    int leftNode,
    List<int> leftPublicKey,
    int rightNode,
    List<int> rightPublicKey,
  ) {
    final nodeCompare = leftNode.compareTo(rightNode);
    if (nodeCompare != 0) return nodeCompare;
    final maxSize = max(leftPublicKey.length, rightPublicKey.length);
    for (var index = 0; index < maxSize; index++) {
      final left = index < leftPublicKey.length ? leftPublicKey[index] : -1;
      final right = index < rightPublicKey.length ? rightPublicKey[index] : -1;
      if (left != right) return left.compareTo(right);
    }
    return 0;
  }

  (int, int) _newMessageId() {
    final value = _newUuidBytes();
    final data = ByteData.sublistView(Uint8List.fromList(value));
    return (data.getInt64(0), data.getInt64(8));
  }

  int _newSignedInt64() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return ByteData.sublistView(Uint8List.fromList(bytes)).getInt64(0);
  }

  List<int> _newUuidBytes() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return bytes;
  }

  String _formatUuid(int high, int low) {
    String hex64(int value) {
      final unsigned = value < 0
          ? BigInt.from(value) + (BigInt.one << 64)
          : BigInt.from(value);
      return unsigned.toRadixString(16).padLeft(16, '0');
    }

    final text = '${hex64(high)}${hex64(low)}';
    return '${text.substring(0, 8)}-${text.substring(8, 12)}-${text.substring(12, 16)}-'
        '${text.substring(16, 20)}-${text.substring(20, 32)}';
  }

  List<int> _conversationPayload(List<int> nonce, List<int> ciphertext) {
    final out = <int>[];
    _writeBytesField(out, 1, nonce);
    _writeBytesField(out, 2, ciphertext);
    return out;
  }

  _ConversationPayload? _parseConversationPayload(List<int> payload) {
    var offset = 0;
    var nonce = const <int>[];
    var ciphertext = const <int>[];
    while (offset < payload.length) {
      final tag = _readVarint(payload, offset);
      if (tag == null) return null;
      offset = tag.nextOffset;
      final field = tag.value >> 3;
      final wireType = tag.value & 0x07;
      if (wireType == 0) {
        final value = _readVarint(payload, offset);
        if (value == null) return null;
        offset = value.nextOffset;
      } else if (wireType == 2) {
        final len = _readVarint(payload, offset);
        if (len == null) return null;
        offset = len.nextOffset;
        if (offset + len.value > payload.length) return null;
        final bytes = payload.sublist(offset, offset + len.value);
        if (field == 1) nonce = bytes;
        if (field == 2) ciphertext = bytes;
        offset += len.value;
      } else {
        return null;
      }
    }
    if (nonce.isEmpty && ciphertext.isEmpty) return null;
    return _ConversationPayload(nonce: nonce, ciphertext: ciphertext);
  }

  void _writeBytesField(List<int> out, int field, List<int> bytes) {
    _writeVarint(out, (field << 3) | 2);
    _writeVarint(out, bytes.length);
    out.addAll(bytes);
  }

  void _writeVarint(List<int> out, int value) {
    var current = value;
    while (current >= 0x80) {
      out.add((current & 0x7f) | 0x80);
      current >>= 7;
    }
    out.add(current);
  }

  _VarintRead? _readVarint(List<int> bytes, int offset) {
    var result = 0;
    var shift = 0;
    var index = offset;
    while (index < bytes.length && shift < 64) {
      final byte = bytes[index++];
      result |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return _VarintRead(result, index);
      }
      shift += 7;
    }
    return null;
  }

  Future<void> sendDeviceSettings({
    required EdgezDeviceSettings settings,
    EdgezUserIdentity? identity,
  }) {
    final deviceSettings = proto.DeviceSettings(
      action: proto.DeviceSettingsAction.DEVICE_SETTINGS_SET,
      deviceModeEnabled: settings.deviceModeEnabled,
      meshId: _take(settings.meshId, 32),
      shareLocation: settings.shareLocation,
      userName: _take(settings.userName, 64),
      marker: _markerColor(settings.marker),
      beaconIntervalSeconds: settings.beaconIntervalSeconds.clamp(5, 3600),
      maxHop: settings.maxHop.clamp(0, 255),
      latitude: settings.latitude,
      longitude: settings.longitude,
      geoIndex: settings.geoIndex,
      uartI2cSensorType: _take(settings.uartI2cSensorType, 64),
      rs485SensorType: _take(settings.rs485SensorType, 64),
    );
    if (identity != null) {
      deviceSettings
        ..userIdHigh = Int64(identity.userIdHigh)
        ..userIdLow = Int64(identity.userIdLow)
        ..userPublicKey = identity.publicKey.take(32).toList()
        ..userPrivateKey = identity.privateKey.take(32).toList();
    }
    if (settings.geoFenceName.trim().isNotEmpty) {
      deviceSettings.geoFence = proto.GeoFence(
        name: _take(settings.geoFenceName.trim(), 64),
        marker: _markerColor(settings.marker),
        geoIndex: settings.geoIndex,
      );
    }

    final packet = proto.NetworkPacket(
      operation: proto.Operation.REQUEST,
      interface: proto.Interface.HALOW,
      userHigh: identity == null ? null : Int64(identity.userIdHigh),
      userLow: identity == null ? null : Int64(identity.userIdLow),
      maxHop: settings.maxHop.clamp(0, 255),
      deviceSettings: deviceSettings,
    );
    return _methods.invokeMethod<void>('sendPacket', {
      'label': 'Device settings',
      'packet': Uint8List.fromList(packet.writeToBuffer()),
    });
  }
}

class _ConversationPayload {
  const _ConversationPayload({
    required this.nonce,
    required this.ciphertext,
  });

  final List<int> nonce;
  final List<int> ciphertext;
}

class _VarintRead {
  const _VarintRead(this.value, this.nextOffset);

  final int value;
  final int nextOffset;
}
