import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('edgez_flutter_sdk/protocol_test');
  late EdgezMeshSdk sdk;
  late List<MethodCall> calls;

  const identity = EdgezUserIdentity(
    userIdHigh: 11,
    userIdLow: 22,
    name: 'Protocol User',
    publicKey: <int>[1, 2, 3, 4],
  );

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    sdk = EdgezMeshSdk(
      methodChannel: channel,
      releaseCredential: _testReleaseCredential,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialization uses the latest HaLow init fields', () async {
    const config = EdgezMeshConfig(
      identity: identity,
      countryCode: 'se',
      meshId: 'edgez-test',
      passphrase: 'secret',
      maxHop: 7,
      meshBandwidthMhz: 4,
      meshFrequencyKhz: 915000,
      beacon: EdgezBeaconConfig(
        marker: 'teal',
        shareLocation: true,
        latitude: 59.33,
        longitude: 18.06,
      ),
    );

    await sdk.initializeMesh(config);

    final packet = _packetFrom(calls.single);
    expect(packet.hasInit(), isTrue);
    expect(packet.init.countryCode, 'SE');
    expect(packet.init.marker, 'teal');
    expect(packet.init.hasLocation, isTrue);
    expect(packet.init.latitude, closeTo(59.33, 0.001));
    expect(packet.init.longitude, closeTo(18.06, 0.001));
    expect(packet.init.meshBandwidthMhz, 4);
    expect(packet.init.meshFrequencyKhz, 915000);
    expect(packet.init.sdkCompatibility, '^0.5.0');
    expect(packet.init.sdkReleaseId, 'edgez_flutter_sdk@test');
    expect(packet.init.sdkReleaseSignature, hasLength(64));
  });

  test('unsigned source checkout fails closed before transport', () async {
    final unsignedSdk = EdgezMeshSdk(
      methodChannel: channel,
      releaseCredential: const EdgezSdkReleaseCredential(
        compatibility: '^0.5.0',
        releaseId: 'source-checkout',
        signatureHex: '',
      ),
    );

    expect(
      () =>
          unsignedSdk.initializeMesh(const EdgezMeshConfig(identity: identity)),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });

  test('release credential signs compatibility and release identity', () {
    expect(
      _testReleaseCredential.signingPayload,
      'EDGEZ-FLUTTER-SDK-RELEASE-V1:'
      '^0.5.0:edgez_flutter_sdk@test',
    );
  });

  test('device settings carry the added provisioning fields', () async {
    const settings = EdgezDeviceSettings(
      meshId: 'edgez-test',
      passphrase: 'mesh-passphrase',
      upstreamWifiSsid: 'uplink',
      upstreamWifiPassphrase: 'wifi-passphrase',
      beaconUnicast: 0x123456789abc,
      deviceType: 'sensor',
      sleepModeEnabled: true,
    );

    await sdk.sendDeviceSettings(settings: settings, identity: identity);

    final packet = _packetFrom(calls.single);
    expect(packet.hasDeviceSettings(), isTrue);
    expect(packet.deviceSettings.passphrase, 'mesh-passphrase');
    expect(packet.deviceSettings.upstreamWifiSsid, 'uplink');
    expect(packet.deviceSettings.upstreamWifiPassphrase, 'wifi-passphrase');
    expect(packet.deviceSettings.beaconUnicast.toInt(), 0x123456789abc);
    expect(packet.deviceSettings.deviceType, DeviceType.DEVICE_TYPE_SENSOR);
    expect(packet.deviceSettings.sleepModeEnabled, isTrue);
  });

  test('sensor drivers use begin, 220-byte chunks, and commit', () async {
    final script = List<String>.filled(500, 'x').join();
    await sdk.sendSensorScript(
      EdgezSensorScriptConfig(
        scriptId: 1003,
        version: 2,
        name: 'Random Temperature (Sample)',
        sensorType: '1003-1',
        connector: EdgezSensorConnector.uartI2c,
        script: script,
      ),
    );

    final packets = calls.map(_packetFrom).toList(growable: false);
    expect(packets, hasLength(5));
    expect(packets.first.scriptConfig.action,
        ScriptConfigAction.SCRIPT_CONFIG_BEGIN);
    expect(packets.last.scriptConfig.action,
        ScriptConfigAction.SCRIPT_CONFIG_COMMIT);
    final chunks = packets
        .where((packet) =>
            packet.scriptConfig.action ==
            ScriptConfigAction.SCRIPT_CONFIG_CHUNK)
        .map((packet) => packet.scriptConfig.chunk)
        .toList(growable: false);
    expect(chunks.map((chunk) => chunk.length), <int>[220, 220, 60]);
    expect(chunks.expand((chunk) => chunk).length, 500);
    expect(packets.first.scriptConfig.selectUartI2c, isTrue);
    expect(packets.first.scriptConfig.sensorType, '1003-1');
  });

  test('topology reports become five-minute RSSI links', () async {
    final fakeSdk = _FakeEdgezMeshSdk();
    final session = EdgezMeshSession(sdk: fakeSdk);
    final reportPacket = NetworkPacket(
      from: Int64(0x100),
      operation: Operation.BROADCAST,
      interface: Interface.HALOW,
      report: Report(
        peers: <Peer>[
          Peer(id: Int64(0x200), rssi: 934),
          Peer(id: Int64(0x300), rssi: 1000),
        ],
      ),
    );

    fakeSdk.addPacket(reportPacket.writeToBuffer());
    await Future<void>.delayed(Duration.zero);

    expect(session.state.topologyLinks, hasLength(2));
    expect(session.state.topologyLinks.first.reporterNodeNum, 0x100);
    expect(
      session.state.topologyLinks
          .firstWhere((link) => link.peerNodeNum == 0x200)
          .rssiDbm,
      -66,
    );
    expect(
      session.state.topologyLinks
          .firstWhere((link) => link.peerNodeNum == 0x300)
          .rssiDbm,
      isNull,
    );

    session.dispose();
    await fakeSdk.close();
  });
}

const _testReleaseCredential = EdgezSdkReleaseCredential(
  compatibility: '^0.5.0',
  releaseId: 'edgez_flutter_sdk@test',
  signatureHex: '000102030405060708090a0b0c0d0e0f'
      '101112131415161718191a1b1c1d1e1f'
      '202122232425262728292a2b2c2d2e2f'
      '303132333435363738393a3b3c3d3e3f',
);

NetworkPacket _packetFrom(MethodCall call) {
  final arguments = (call.arguments as Map).cast<Object?, Object?>();
  final bytes = arguments['packet']! as Uint8List;
  return NetworkPacket.fromBuffer(bytes);
}

class _FakeEdgezMeshSdk extends EdgezMeshSdk {
  final StreamController<EdgezMeshEvent> _events =
      StreamController<EdgezMeshEvent>.broadcast();

  @override
  Stream<EdgezMeshEvent> get events => _events.stream;

  void addPacket(List<int> packet) {
    _events
        .add(EdgezMeshEvent(type: EdgezMeshEventType.packet, packet: packet));
  }

  Future<void> close() => _events.close();
}
