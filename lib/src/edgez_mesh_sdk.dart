import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
    required int toNode,
    required String text,
    int maxHop = 0,
  }) async {
    final result = await _methods.invokeMethod<String>('sendTextMessage', {
      'toNode': toNode,
      'text': text,
      'maxHop': maxHop,
    });
    return result ?? '';
  }

  Future<String> sendVoiceMessage({
    required int toNode,
    required List<int> bytes,
    required int durationMs,
    required int codec,
    int maxHop = 0,
  }) async {
    final result = await _methods.invokeMethod<String>('sendVoiceMessage', {
      'toNode': toNode,
      'bytes': Uint8List.fromList(bytes),
      'durationMs': durationMs,
      'codec': codec,
      'maxHop': maxHop,
    });
    return result ?? '';
  }

  Future<void> sendDeviceSettings(Map<String, Object?> settings) {
    return _methods.invokeMethod<void>('sendDeviceSettings', settings);
  }
}
