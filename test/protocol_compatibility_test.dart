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
    sdk = EdgezMeshSdk(methodChannel: channel);
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
  });

  test('beacon uses broadcast payload and remains decryptable', () async {
    const config = EdgezMeshConfig(
      identity: identity,
      passphrase: 'mesh secret',
      beacon: EdgezBeaconConfig(
        marker: 'orange',
        shareLocation: true,
        latitude: 1.25,
        longitude: 2.5,
      ),
    );

    await sdk.sendBeacon(config);

    final packet = _packetFrom(calls.single);
    expect(packet.operation, Operation.BROADCAST);
    expect(packet.hasPayload(), isTrue);
    expect(packet.hasBeacon(), isFalse);
    final beacon = await sdk.decodeBeaconPayload(
      packet.payload,
      passphrase: config.passphrase,
    );
    expect(beacon, isNotNull);
    expect(beacon!.userName, 'Protocol User|m=orange');
    expect(beacon.latitude, closeTo(1.25, 0.001));
    expect(beacon.longitude, closeTo(2.5, 0.001));
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
