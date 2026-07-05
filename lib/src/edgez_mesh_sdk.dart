import 'dart:async';

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

  String _take(String value, int maxLength) {
    return value.length > maxLength ? value.substring(0, maxLength) : value;
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
