import 'dart:async';
import 'dart:typed_data';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';

class MockBleCall {
  const MockBleCall(this.method, this.arguments);

  final String method;
  final Object? arguments;

  Map<Object?, Object?> get argumentMap =>
      (arguments as Map).cast<Object?, Object?>();

  NetworkPacket get packet {
    final bytes = argumentMap['packet']! as Uint8List;
    return NetworkPacket.fromBuffer(bytes);
  }
}

class MockBleTransport implements EdgezPlatformTransport {
  final StreamController<Object?> _events =
      StreamController<Object?>.broadcast();
  final List<MockBleCall> calls = <MockBleCall>[];
  final Map<String, Object?> results = <String, Object?>{};
  final Map<String, Object> errors = <String, Object>{};

  @override
  Stream<Object?> get events => _events.stream;

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async {
    calls.add(MockBleCall(method, arguments));
    final error = errors[method];
    if (error != null) throw error;
    return results[method] as T?;
  }

  Iterable<MockBleCall> callsFor(String method) =>
      calls.where((call) => call.method == method);

  MockBleCall get lastPacketCall => calls.lastWhere(
        (call) =>
            call.arguments is Map &&
            (call.arguments as Map).containsKey('packet'),
      );

  void emitConnection(EdgezConnectionType connection) {
    _events.add(<Object?, Object?>{
      'type': 'connection',
      'connection': connection.name,
    });
  }

  void emitReady() {
    _events.add(const <Object?, Object?>{'type': 'ready'});
  }

  void emitBleDevice({
    required String id,
    required String name,
    int rssi = -60,
  }) {
    _events.add(<Object?, Object?>{
      'type': 'bleDevice',
      'bleDevice': <Object?, Object?>{
        'id': id,
        'name': name,
        'rssi': rssi,
        'lastSeenMs': DateTime.now().millisecondsSinceEpoch,
      },
    });
  }

  void emitPacket(NetworkPacket packet) {
    _events.add(<Object?, Object?>{
      'type': 'packet',
      'packet': packet.writeToBuffer(),
    });
  }

  void emitLog(String message) {
    _events.add(<Object?, Object?>{'type': 'log', 'log': message});
  }

  Future<void> flushEvents() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() => _events.close();
}
