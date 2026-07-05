import 'dart:async';

import 'package:flutter/services.dart';

import 'models.dart';

class EdgezMeshSdk {
  EdgezMeshSdk({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methods = methodChannel ?? const MethodChannel('edgez_flutter_sdk/methods'),
        _events = eventChannel ?? const EventChannel('edgez_flutter_sdk/events');

  final MethodChannel _methods;
  final EventChannel _events;

  Stream<EdgezMeshEvent>? _meshEvents;

  Stream<EdgezMeshEvent> get events {
    return _meshEvents ??= _events.receiveBroadcastStream().where((event) => event is Map).map(
          (event) => EdgezMeshEvent.fromMap((event as Map).cast<Object?, Object?>()),
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
    return _methods.invokeMethod<void>('initializeMesh', config.toMap());
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
