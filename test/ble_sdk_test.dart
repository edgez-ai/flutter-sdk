import 'package:cryptography/cryptography.dart';
import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mock_ble_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
