import 'dart:async';
import 'dart:typed_data';

import 'package:coap/coap.dart';

import 'edgez_mesh_sdk.dart';

/// Post-provision transport for an ESP32 reached through its Wi-Fi network.
/// BLE and native phone functions are delegated to [fallback].
class EdgezCoapTransport implements EdgezPlatformTransport {
  EdgezCoapTransport({EdgezPlatformTransport? fallback})
      : fallback = fallback ?? EdgezChannelTransport() {
    _fallbackSubscription = this.fallback.events.listen(
          _events.add,
          onError: _events.addError,
        );
  }

  final EdgezPlatformTransport fallback;
  final StreamController<Object?> _events =
      StreamController<Object?>.broadcast();
  late final StreamSubscription<Object?> _fallbackSubscription;
  CoapClient? _client;
  CoapObserveClientRelation? _observation;
  StreamSubscription<CoapResponse>? _observeSubscription;
  String? _host;
  int _port = 5683;

  @override
  Stream<Object?> get events => _events.stream;

  Uri _uri(String path) => Uri(path: path);

  Future<void> connect({
    required String host,
    int port = 5683,
    int userIdHigh = 0,
    int userIdLow = 0,
  }) async {
    await _closeCoap(emitDisconnected: false);
    _host = host;
    _port = port;
    final client = CoapClient(
      Uri(scheme: 'coap', host: host, port: port),
      config: CoapConfigDefault(),
    );
    _client = client;
    final identity = ByteData(16)
      ..setUint64(0, userIdHigh & 0xffffffffffffffff, Endian.big)
      ..setUint64(8, userIdLow & 0xffffffffffffffff, Endian.big);
    final registration = await client.postBytes(
      _uri('v1/session'),
      payload: identity.buffer.asUint8List(),
      confirmable: true,
    );
    if (!registration.isSuccess) {
      client.close();
      _client = null;
      throw StateError(
        'CoAP session registration failed: ${registration.statusCodeString}',
      );
    }
    final request = CoapRequest.get(_uri('v1/events'));
    final observation = await client.observe(request);
    _observation = observation;
    _observeSubscription = observation.listen(
      _handleEvent,
      onError: (Object error, StackTrace stack) {
        _events.addError(error, stack);
        _events.add({'type': 'connection', 'connection': 'none'});
      },
    );
    _events.add({'type': 'connection', 'connection': 'coap'});
    _events.add({
      'type': 'log',
      'log': 'CoAP connected to $host:$port',
      'diagnostic': true,
    });
  }

  void _handleEvent(CoapResponse response) {
    final data = response.payload;
    if (data == null || data.isEmpty) return;
    final kind = data[0];
    final payload = Uint8List.fromList(data.sublist(1));
    switch (kind) {
      case 0:
        _events.add({
          'type': 'packet',
          'packet': payload,
          'receivedAtUs': DateTime.now().microsecondsSinceEpoch,
        });
      case 1:
        final voice = _stripPrefix(payload, const [0x56, 0x43, 0x02]);
        _events.add({'type': 'voiceFrame', 'packet': voice});
      case 2:
        final speed = _stripPrefix(payload, const [0x53, 0x54, 0x02]);
        _events.add({
          'type': 'speedTestFrame',
          'packet': speed,
          'receivedAtUs': DateTime.now().microsecondsSinceEpoch,
        });
      case 3:
        _events.add({
          'type': 'log',
          'log': 'Device log frame received (${payload.length} bytes)',
          'diagnostic': true,
        });
    }
  }

  Uint8List _stripPrefix(Uint8List value, List<int> prefix) {
    if (value.length < prefix.length) return value;
    for (var i = 0; i < prefix.length; i++) {
      if (value[i] != prefix[i]) return value;
    }
    return Uint8List.sublistView(value, prefix.length);
  }

  Future<void> _postFrame(Uint8List payload) async {
    final response = await _requireClient().postBytes(
      _uri('v1/frame'),
      payload: payload,
      confirmable: true,
    );
    if (!response.isSuccess) {
      throw StateError('CoAP frame rejected: ${response.statusCodeString}');
    }
  }

  Future<void> _postRealtime(Uint8List payload) async {
    await _requireClient().postBytes(
      _uri('v1/realtime'),
      payload: payload,
      confirmable: false,
    );
  }

  CoapClient _requireClient() =>
      _client ?? (throw StateError('CoAP transport is not connected'));

  Uint8List _routedRealtime(
    List<int> prefix,
    int to,
    int maxHop,
    int sequence,
    List<int> payload,
  ) {
    final output = Uint8List(prefix.length + 11 + payload.length);
    output.setRange(0, prefix.length, prefix);
    var offset = prefix.length;
    for (var shift = 40; shift >= 0; shift -= 8) {
      output[offset++] = (to >> shift) & 0xff;
    }
    output[offset++] = maxHop.clamp(0, 255);
    ByteData.sublistView(output).setUint32(offset, sequence, Endian.big);
    offset += 4;
    output.setRange(offset, output.length, payload);
    return output;
  }

  Future<void> _closeCoap({bool emitDisconnected = true}) async {
    await _observeSubscription?.cancel();
    final client = _client;
    final observation = _observation;
    if (client != null && observation != null) {
      await client.cancelObserveProactive(observation);
    }
    client?.close();
    _observeSubscription = null;
    _observation = null;
    _client = null;
    _host = null;
    if (emitDisconnected) {
      _events.add({'type': 'connection', 'connection': 'none'});
    }
  }

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async {
    final args = arguments is Map ? arguments : const <Object?, Object?>{};
    switch (method) {
      case 'connectCoap':
        await connect(
          host: args['host'] as String,
          port: args['port'] as int? ?? 5683,
          userIdHigh: args['userIdHigh'] as int? ?? 0,
          userIdLow: args['userIdLow'] as int? ?? 0,
        );
        return null;
      case 'disconnect':
        if (_client != null) {
          await _closeCoap();
          return null;
        }
        return fallback.invokeMethod<T>(method, arguments);
      case 'initializeMesh':
      case 'sendPacket':
        await _postFrame(args['packet'] as Uint8List);
        return null;
      case 'sendVoiceCallFrame':
        final nonce = args['nonce'] as Uint8List;
        final ciphertext = args['ciphertext'] as Uint8List;
        await _postRealtime(_routedRealtime(
          const [0x56, 0x43, 0x02],
          (args['to'] as num).toInt(),
          (args['maxHop'] as num).toInt(),
          (args['sequence'] as num).toInt(),
          [...nonce, ...ciphertext],
        ));
        return null;
      case 'sendSpeedTestFrame':
        await _postRealtime(_routedRealtime(
          const [0x53, 0x54, 0x02],
          (args['to'] as num).toInt(),
          (args['maxHop'] as num).toInt(),
          (args['sequence'] as num).toInt(),
          args['payload'] as Uint8List,
        ));
        return null;
      default:
        return fallback.invokeMethod<T>(method, arguments);
    }
  }

  Future<void> dispose() async {
    await _closeCoap(emitDisconnected: false);
    await _fallbackSubscription.cancel();
    await _events.close();
  }
}
