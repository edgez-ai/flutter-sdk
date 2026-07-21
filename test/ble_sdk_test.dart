import 'package:cryptography/cryptography.dart';
import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mock_ble_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BLE configuration persists through the SDK store', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = EdgezBleConfigurationStore();
    const device = EdgezBleDevice(
      id: '11:22:33:44:55:66',
      name: 'EdgeZ Mock',
      rssi: -42,
      lastSeenMs: 100,
    );

    await store.saveSelectedDevice(device);
    await store.setAutoConnect(true);

    final restored = await EdgezBleConfigurationStore().load();
    expect(restored.deviceId, device.id);
    expect(restored.deviceName, device.name);
    expect(restored.autoConnect, isTrue);
    expect(restored.selectedDevice?.label, device.label);
  });

  group('EdgezMeshSdk with mocked BLE', () {
    late MockBleTransport ble;
    late EdgezMeshSdk sdk;

    setUp(() {
      ble = MockBleTransport();
      sdk = EdgezMeshSdk(transport: ble);
    });

    tearDown(() async {
      await ble.close();
    });

    test('forwards BLE scan, connect, and disconnect calls', () async {
      await sdk.startBleScan();
      await sdk.connectBle('AA:BB:CC:DD:EE:FF');
      await sdk.stopBleScan();
      await sdk.disconnect();

      expect(
        ble.calls.map((call) => call.method),
        <String>['startBleScan', 'connectBle', 'stopBleScan', 'disconnect'],
      );
      expect(
        ble.calls[1].argumentMap['deviceId'],
        'AA:BB:CC:DD:EE:FF',
      );
    });

    test('turns mocked BLE events into SDK events', () async {
      final received = <EdgezMeshEvent>[];
      final subscription = sdk.events.listen(received.add);

      ble.emitConnection(EdgezConnectionType.ble);
      ble.emitBleDevice(
        id: '11:22:33:44:55:66',
        name: 'EdgeZ Mock',
        rssi: -47,
      );
      ble.emitReady();
      await ble.flushEvents();

      expect(
        received.map((event) => event.type),
        <EdgezMeshEventType>[
          EdgezMeshEventType.connection,
          EdgezMeshEventType.bleDevice,
          EdgezMeshEventType.ready,
        ],
      );
      expect(received[0].connection, EdgezConnectionType.ble);
      expect(received[1].bleDevice?.name, 'EdgeZ Mock');
      expect(received[1].bleDevice?.rssi, -47);

      await subscription.cancel();
    });

    test('session initializes only after mocked BLE becomes ready', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final identity = await _newIdentity('Local user', 10, 20);
      final config = EdgezMeshConfig(
        identity: identity,
        countryCode: 'EU',
        meshId: 'mock-mesh',
        passphrase: 'mock-secret',
        meshBandwidthMhz: 2,
        meshFrequencyKhz: 866000,
      );

      await session.initializeMesh(config);
      expect(ble.callsFor('initializeMesh'), isEmpty);

      await session.connectBle('11:22:33:44:55:66');
      expect(ble.callsFor('connectBle'), hasLength(1));
      expect(ble.callsFor('initializeMesh'), isEmpty);

      ble.emitConnection(EdgezConnectionType.ble);
      ble.emitReady();
      await ble.flushEvents();
      await ble.flushEvents();

      expect(session.state.connection, EdgezConnectionType.ble);
      expect(ble.callsFor('initializeMesh'), hasLength(1));
      final initPacket = ble.callsFor('initializeMesh').single.packet;
      expect(initPacket.init.meshId, 'mock-mesh');
      expect(initPacket.init.meshBandwidthMhz, 2);
      expect(initPacket.init.meshFrequencyKhz, 866000);
      expect(ble.callsFor('sendPacket'), isNotEmpty);
      expect(
        ble.callsFor('sendPacket').first.packet.deviceSettings.action,
        DeviceSettingsAction.DEVICE_SETTINGS_GET,
      );
      expect(ble.callsFor('sendPacket'), hasLength(1));

      session.dispose();
    });

    test('session decodes an inbound BLE beacon and typed sensors', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final packet = NetworkPacket(
        from: Int64(0x112233445566),
        operation: Operation.BROADCAST,
        interface: Interface.HALOW,
        beacon: Beacon(
          userIdHigh: Int64(30),
          userIdLow: Int64(40),
          userName: 'Sensor mock',
          marker: MarkerColor.MARKER_ORANGE,
          deviceType: DeviceType.DEVICE_TYPE_SENSOR,
          sensorData: <SensorData>[
            SensorData(
              type: SensorType.SENSOR_TEMPERATURE,
              floatValue: 21.5,
            ),
            SensorData(
              type: SensorType.SENSOR_ACCEL_X,
              floatValue: 9.81,
            ),
            SensorData(
              type: SensorType.SENSOR_LENGTH,
              intValue: 4096,
            ),
          ],
        ),
      );

      ble.emitPacket(packet);
      await ble.flushEvents();

      final node = session.state.nodes[0x112233445566];
      expect(node, isNotNull);
      expect(node!.displayName, 'Sensor mock');
      expect(node.deviceType, 'Sensor');
      expect(node.marker, 'orange');
      final sample = session.state.sensorSamples[node.nodeNum]!.single.data;
      expect(sample.temperature, closeTo(21.5, 0.001));
      expect(sample.accelX, closeTo(9.81, 0.001));
      expect(sample.binaryLengthBytes, 4096);

      session.dispose();
    });

    test('session accepts Android-style complete EZ beacon frames', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final packet = NetworkPacket(
        from: Int64(0x223344556677),
        operation: Operation.BROADCAST,
        interface: Interface.HALOW,
        beacon: Beacon(
          userIdHigh: Int64(50),
          userIdLow: Int64(60),
          userName: 'Forwarded beacon',
          marker: MarkerColor.MARKER_GREEN,
        ),
      );

      ble.emitRawPacketBytes(ble.encodeFrame(packet.writeToBuffer()));
      await ble.flushEvents();

      final node = session.state.nodes[0x223344556677];
      expect(node?.displayName, 'Forwarded beacon');
      expect(node?.marker, 'green');

      session.dispose();
    });

    test('session merges firmware beacons by identity like Android', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final first = NetworkPacket(
        from: Int64(0x111111111111),
        operation: Operation.BROADCAST,
        interface: Interface.HALOW,
        beacon: Beacon(
          userIdHigh: Int64(30),
          userIdLow: Int64(40),
          userName: 'Moving sensor|m=orange',
          marker: MarkerColor.MARKER_DEFAULT,
          latitude: 59.33,
          longitude: 18.06,
          deviceType: DeviceType.DEVICE_TYPE_SENSOR,
          geoFence: GeoFence(name: 'Warehouse', geoIndex: 0),
        ),
      );
      final moved = NetworkPacket(
        from: Int64(0x222222222222),
        operation: Operation.BROADCAST,
        interface: Interface.HALOW,
        beacon: Beacon(
          userIdHigh: Int64(30),
          userIdLow: Int64(40),
          userName: 'Moving sensor',
          marker: MarkerColor.MARKER_TEAL,
        ),
      );

      ble.emitPacket(first);
      await ble.flushEvents();
      final firstNode = session.state.nodes[0x111111111111];
      expect(firstNode?.displayName, 'Moving sensor');
      expect(firstNode?.marker, 'orange');
      ble.emitPacket(moved);
      await ble.flushEvents();

      expect(session.state.nodes, hasLength(1));
      expect(session.state.nodes.containsKey(0x111111111111), isFalse);
      final node = session.state.nodes[0x222222222222];
      expect(node, isNotNull);
      expect(node!.displayName, 'Moving sensor');
      expect(node.marker, 'teal');
      expect(node.deviceType, 'Sensor');
      expect(node.latitude, closeTo(59.33, 0.001));
      expect(node.longitude, closeTo(18.06, 0.001));
      expect(node.geoFenceName, 'Warehouse');
      expect(node.geoIndex, 0);

      session.dispose();
    });

    test('voice call queues invite and ends locally without waiting for BLE',
        () async {
      ble.results['requestMicrophonePermission'] = true;
      final session = EdgezMeshSession(sdk: sdk);
      final local = await _newIdentity('Local caller', 70, 80);
      final remote = await _newIdentity('Remote caller', 90, 100);
      await session.initializeMesh(
        EdgezMeshConfig(identity: local, maxHop: 4),
      );
      ble.emitPacket(
        NetworkPacket(
          status: HaLowInterfaceStatus(
            macAddress: Int64(0x112233445566),
            stackInitialized: true,
          ),
        ),
      );
      ble.emitPacket(
        NetworkPacket(
          from: Int64(0x223344556677),
          operation: Operation.BROADCAST,
          interface: Interface.HALOW,
          beacon: Beacon(
            userIdHigh: Int64(remote.userIdHigh),
            userIdLow: Int64(remote.userIdLow),
            userName: remote.name,
            userPublicKey: remote.publicKey,
          ),
        ),
      );
      await ble.flushEvents();

      await session.startVoiceCall(0x223344556677);
      expect(session.state.voiceCall.phase, EdgezVoiceCallPhase.outgoing);
      expect(ble.callsFor('sendVoiceCallFrame'), hasLength(1));

      await session.endVoiceCall();
      expect(session.state.voiceCall.phase, EdgezVoiceCallPhase.idle);
      expect(ble.callsFor('stopLiveVoiceAudio'), hasLength(1));
      await ble.flushEvents();
      expect(ble.callsFor('sendVoiceCallFrame'), hasLength(2));

      session.dispose();
    });

    test('session ignores self and identity-empty firmware beacons', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final identity = await _newIdentity('Local user', 10, 20);
      await session.initializeMesh(EdgezMeshConfig(identity: identity));

      ble.emitPacket(
        NetworkPacket(
          from: Int64(0x111111111111),
          operation: Operation.BROADCAST,
          interface: Interface.HALOW,
          beacon: Beacon(
            userIdHigh: Int64(identity.userIdHigh),
            userIdLow: Int64(identity.userIdLow),
            userName: identity.name,
            userPublicKey: identity.publicKey,
          ),
        ),
      );
      ble.emitPacket(
        NetworkPacket(
          from: Int64(0x222222222222),
          operation: Operation.BROADCAST,
          interface: Interface.HALOW,
          beacon: Beacon(),
        ),
      );
      await ble.flushEvents();

      expect(session.state.nodes, isEmpty);
      session.dispose();
    });

    test('encrypted text round-trips across two mocked BLE transports',
        () async {
      final sender = await _newIdentity('Sender', 100, 101);
      final receiver = await _newIdentity('Receiver', 200, 201);
      final receiverNode = EdgezMeshNode(
        nodeNum: 0x200,
        userUuid: '',
        displayName: receiver.name,
        route: 'BLE',
        lastSeenMs: 1,
        marker: 'blue',
        publicKey: receiver.publicKey,
        deviceType: 'User',
      );

      final messageId = await sdk.sendTextMessage(
        config: EdgezMeshConfig(identity: sender),
        toNode: receiverNode,
        fromNode: 0x100,
        text: 'hello over mocked BLE',
      );

      final packet = ble.lastPacketCall.packet;
      expect(messageId, isNotEmpty);
      expect(packet.from.toInt(), 0x100);
      expect(packet.to.toInt(), 0x200);
      expect(packet.msg.mime, Mime.MIME_TEXT);
      expect(packet.msg.payload, isNotEmpty);
      final frame = ble.transmittedFrames.single;
      expect(frame.sublist(0, 2), <int>[0x45, 0x5a]);
      expect(frame[2] | (frame[3] << 8), packet.writeToBuffer().length);

      final receiverBle = MockBleTransport();
      final receiverSdk = EdgezMeshSdk(transport: receiverBle);
      final cleartext = await receiverSdk.decryptTextMessage(
        config: EdgezMeshConfig(identity: receiver),
        sender: EdgezMeshNode(
          nodeNum: 0x100,
          userUuid: '',
          displayName: sender.name,
          route: 'BLE',
          lastSeenMs: 1,
          marker: 'blue',
          publicKey: sender.publicKey,
          deviceType: 'User',
        ),
        fromNode: 0x100,
        toNode: 0x200,
        payload: packet.msg.payload,
      );
      expect(cleartext, 'hello over mocked BLE');
      await receiverBle.close();
    });

    test('surfaces failures returned by the mocked BLE layer', () async {
      ble.errors['connectBle'] = StateError('mock connection failed');

      await expectLater(
        sdk.connectBle('unreachable'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'mock connection failed',
          ),
        ),
      );
    });

    test('rejects malformed BLE protocol frames', () {
      expect(
        () => ble.emitFrame(<int>[0x00, 0x00, 0x00, 0x00]),
        throwsFormatException,
      );
      expect(
        () => ble.emitFrame(<int>[0x45, 0x5a, 0x02, 0x00, 0x01]),
        throwsFormatException,
      );
    });
  });
}

Future<EdgezUserIdentity> _newIdentity(
  String name,
  int userIdHigh,
  int userIdLow,
) async {
  final keyPair = await X25519().newKeyPair();
  final privateKey = await keyPair.extractPrivateKeyBytes();
  final publicKey = await keyPair.extractPublicKey();
  return EdgezUserIdentity(
    userIdHigh: userIdHigh,
    userIdLow: userIdLow,
    name: name,
    privateKey: privateKey,
    publicKey: publicKey.bytes,
  );
}
