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
  static const int maxPayloadBytes = 512;

  final StreamController<Object?> _events =
      StreamController<Object?>.broadcast();
  final List<MockBleCall> calls = <MockBleCall>[];
  final Map<String, Object?> results = <String, Object?>{};
  final Map<String, Object> errors = <String, Object>{};
  final List<Uint8List> transmittedFrames = <Uint8List>[];

  @override
  Stream<Object?> get events => _events.stream;

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async {
    calls.add(MockBleCall(method, arguments));
    final error = errors[method];
    if (error != null) throw error;
    if (arguments is Map && arguments['packet'] is Uint8List) {
      transmittedFrames.add(
        encodeFrame(arguments['packet']! as Uint8List),
      );
    }
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
    emitFrame(encodeFrame(packet.writeToBuffer()));
  }

  void emitFrame(List<int> frame) {
    final packet = decodeFrame(frame);
    _events.add(<Object?, Object?>{
      'type': 'packet',
      'packet': packet,
    });
  }

  Uint8List encodeFrame(List<int> payload) {
    if (payload.length > maxPayloadBytes) {
      throw StateError(
        'Mock BLE payload too large: ${payload.length}/$maxPayloadBytes',
      );
    }
    return Uint8List.fromList(<int>[
      0x45,
      0x5a,
      payload.length & 0xff,
      (payload.length >> 8) & 0xff,
      ...payload,
    ]);
  }

  Uint8List decodeFrame(List<int> frame) {
    if (frame.length < 4 || frame[0] != 0x45 || frame[1] != 0x5a) {
      throw const FormatException('Mock BLE frame has invalid EZ header');
    }
    final payloadLength = frame[2] | (frame[3] << 8);
    if (payloadLength > maxPayloadBytes || frame.length != payloadLength + 4) {
      throw const FormatException('Mock BLE frame has invalid payload length');
    }
    return Uint8List.fromList(frame.sublist(4));
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
