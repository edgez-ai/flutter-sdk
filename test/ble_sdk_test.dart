import 'dart:async';
import 'dart:typed_data';

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
    await store.setMeshRadio(
      country: 'EU',
      bandwidthMhz: 2,
      frequencyKhz: 866000,
    );

    final restored = await EdgezBleConfigurationStore().load();
    expect(restored.deviceId, device.id);
    expect(restored.deviceName, device.name);
    expect(restored.autoConnect, isTrue);
    expect(restored.shareLocation, isFalse);
    expect(restored.logLevel, EdgezDeviceLogLevel.none);
    expect(restored.selectedDevice?.label, device.label);
    expect(restored.preferredTransport, EdgezPreferredTransport.ble);
    expect(restored.meshCountry, 'EU');
    expect(restored.meshBandwidthMhz, 2);
    expect(restored.meshFrequencyKhz, 866000);

    await store.setShareLocation(true);
    expect((await store.load()).shareLocation, isTrue);

    const usbDevice = EdgezUsbDevice(
      id: 7,
      name: 'CP2102',
      vendorId: 0x10c4,
      productId: 0xea60,
    );
    await store.saveSelectedUsbDevice(usbDevice);
    final usbRestored = await store.load();
    expect(usbRestored.preferredTransport, EdgezPreferredTransport.usb);
    expect(usbRestored.usbVendorId, usbDevice.vendorId);
    expect(usbRestored.usbProductId, usbDevice.productId);
    expect(usbRestored.usbDeviceName, usbDevice.name);
  });

  group('OTA release metadata', () {
    test('parses the manifest and compares semantic versions', () {
      final release = EdgezOtaRelease.fromJson(<String, Object?>{
        'version': 'v0.6.1',
        'size': 123456,
        'url': 'https://www.edgez.ai/firmware/app.bin',
      });

      expect(release.size, 123456);
      expect(release.isNewerThan('0.6.0'), isTrue);
      expect(release.isNewerThan('v0.6.1'), isFalse);
      expect(release.isNewerThan('0.7.0'), isFalse);
    });

    test('rejects incomplete or invalid manifests', () {
      expect(
        () => EdgezOtaRelease.fromJson(<String, Object?>{
          'version': '0.6.1',
          'size': 0,
          'url': 'https://www.edgez.ai/firmware/app.bin',
        }),
        throwsFormatException,
      );
      expect(
        () => EdgezOtaRelease.fromJson(<String, Object?>{
          'version': '0.6.1',
          'size': 123,
          'url': 'not a URL',
        }),
        throwsFormatException,
      );
    });
  });

  group('EdgezMeshSdk with mocked BLE', () {
    late MockBleTransport ble;
    late EdgezMeshSdk sdk;

    setUp(() {
      ble = MockBleTransport();
      sdk = EdgezMeshSdk(
        transport: ble,
        releaseCredential: _testReleaseCredential,
      );
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

    test('requests the BATMAN routing table from the connected device',
        () async {
      await sdk.requestRoutingTable(fromNode: 0x112233445566);

      final packet = ble.callsFor('sendPacket').single.packet;
      expect(packet.from.toInt(), 0x112233445566);
      expect(packet.operation, Operation.REQUEST);
      expect(packet.interface, Interface.HALOW);
      expect(packet.hasRoutingTable(), isTrue);
      expect(packet.routingTable.routes, isEmpty);
    });

    test('lists and connects an Android USB device', () async {
      ble.results['listUsbDevices'] = <Object?>[
        <Object?, Object?>{
          'id': 7,
          'name': 'ESP32-S3 USB JTAG/serial debug unit',
          'vendorId': 0x303a,
          'productId': 0x1001,
        },
      ];

      final devices = await sdk.listUsbDevices();
      await sdk.connectUsb(devices.single.id);

      expect(devices.single.vendorId, 0x303a);
      expect(devices.single.label, contains('303a:1001'));
      expect(ble.callsFor('connectUsb').single.argumentMap['deviceId'], 7);
    });

    test('sets device log level', () async {
      await sdk.setDeviceLogLevel(EdgezDeviceLogLevel.debug);

      final call = ble.callsFor('setDeviceLogLevel').single;
      expect(call.argumentMap['level'], 4);
      expect(call.argumentMap['tag'], '');
    });

    test('returns the best known phone location from the platform', () async {
      ble.results['getBestKnownLocation'] = <Object?, Object?>{
        'latitude': 59.3293,
        'longitude': 18.0686,
        'timestampMs': 123456,
      };

      final location = await sdk.getBestKnownLocation();

      expect(location?.latitude, closeTo(59.3293, 0.000001));
      expect(location?.longitude, closeTo(18.0686, 0.000001));
      expect(location?.timestampMs, 123456);
      expect(ble.callsFor('getBestKnownLocation'), hasLength(1));
    });

    test('normalizes voice-message audio through the Android transport',
        () async {
      ble.results['decodeVoiceMessageToWav'] = Uint8List.fromList(
        <int>[0x52, 0x49, 0x46, 0x46],
      );
      const message = EdgezConversationMessage(
        nodeNum: 7,
        text: '',
        mine: false,
        timestampMs: 1,
        voiceBytes: <int>[1, 2, 3],
        voiceCodec: 2,
        durationMs: 500,
      );

      final wav = await sdk.decodeVoiceMessageToWav(message);

      expect(wav, <int>[0x52, 0x49, 0x46, 0x46]);
      final call = ble.callsFor('decodeVoiceMessageToWav').single;
      expect(call.argumentMap['bytes'], Uint8List.fromList(<int>[1, 2, 3]));
      expect(call.argumentMap['codec'], 2);
    });

    test('forwards background notification commands to Android', () async {
      ble.results['requestNotificationPermission'] = true;
      ble.results['notificationsAllowed'] = true;
      ble.results['canUseFullScreenIntent'] = true;
      ble.results['showIncomingMessageNotification'] = true;
      ble.results['showIncomingCallNotification'] = true;
      const sender = EdgezMeshNode(
        nodeNum: 0x1234,
        userUuid: 'sender',
        displayName: 'Remote user',
        route: 'BLE',
        lastSeenMs: 1,
        marker: 'blue',
      );
      const message = EdgezConversationMessage(
        nodeNum: 0x1234,
        text: 'Hello from the mesh',
        mine: false,
        timestampMs: 2,
        messageUuid: 'message-1',
      );
      const call = EdgezVoiceCallState(
        peerNodeNum: 0x1234,
        callId: 99,
        phase: EdgezVoiceCallPhase.incoming,
      );

      expect(await sdk.requestNotificationPermission(), isTrue);
      expect(await sdk.notificationsAllowed, isTrue);
      expect(await sdk.canUseFullScreenIntent, isTrue);
      expect(
        await sdk.showIncomingMessageNotification(
          message: message,
          sender: sender,
        ),
        isTrue,
      );
      expect(
        await sdk.showIncomingCallNotification(call: call, caller: sender),
        isTrue,
      );
      await sdk.cancelIncomingCallNotification();
      await sdk.clearCallLockScreenPresentation();

      expect(
        ble.calls.map((item) => item.method),
        containsAllInOrder(<String>[
          'requestNotificationPermission',
          'notificationsAllowed',
          'canUseFullScreenIntent',
          'showIncomingMessageNotification',
          'showIncomingCallNotification',
          'cancelIncomingCallNotification',
          'clearCallLockScreenPresentation',
        ]),
      );
      final messageCall =
          ble.callsFor('showIncomingMessageNotification').single;
      expect(messageCall.argumentMap['sender'], 'Remote user');
      expect(messageCall.argumentMap['body'], 'Hello from the mesh');
      final callCommand = ble.callsFor('showIncomingCallNotification').single;
      expect(callCommand.argumentMap['callId'], 99);
    });

    test('forwards OTA readiness, image, progress, and cancellation', () async {
      ble.results['isOtaReady'] = true;
      ble.results['performOta'] = 'Firmware uploaded; the device is restarting';
      final session = EdgezMeshSession(sdk: sdk);

      expect(await session.isOtaReady, isTrue);
      ble.emitConnection(EdgezConnectionType.ble);
      ble.emitReady();
      await ble.flushEvents();
      expect(session.state.otaReady, isTrue);
      ble.emitOtaProgress(sentBytes: 220, totalBytes: 440);
      await ble.flushEvents();
      expect(session.state.otaInProgress, isTrue);
      expect(session.state.otaProgress, 0.5);

      await session.performOta(<int>[1, 2, 3, 4]);
      final otaCall = ble.callsFor('performOta').single;
      expect(
          otaCall.argumentMap['image'], Uint8List.fromList(<int>[1, 2, 3, 4]));
      expect(session.state.otaProgress, 1);
      expect(session.state.otaInProgress, isFalse);

      await session.abortOta();
      expect(ble.callsFor('abortOta'), hasLength(1));
      expect(session.state.otaInProgress, isFalse);

      ble.emitConnection(EdgezConnectionType.none);
      await ble.flushEvents();
      expect(session.state.otaReady, isFalse);

      session.dispose();
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

    test('maps every HaLow license status from protobuf', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final statuses = <LicenseStatus, EdgezLicenseStatus>{
        LicenseStatus.LICENSE_STATUS_UNSPECIFIED:
            EdgezLicenseStatus.unspecified,
        LicenseStatus.LICENSE_STATUS_AUTHORIZED: EdgezLicenseStatus.authorized,
        LicenseStatus.LICENSE_STATUS_DEVICE_NOT_LICENSED:
            EdgezLicenseStatus.deviceNotLicensed,
        LicenseStatus.LICENSE_STATUS_SDK_RELEASE_REQUIRED:
            EdgezLicenseStatus.sdkReleaseRequired,
        LicenseStatus.LICENSE_STATUS_SDK_VERSION_INCOMPATIBLE:
            EdgezLicenseStatus.sdkVersionIncompatible,
        LicenseStatus.LICENSE_STATUS_SDK_RELEASE_INVALID:
            EdgezLicenseStatus.sdkReleaseInvalid,
      };

      for (final entry in statuses.entries) {
        ble.emitPacket(
          NetworkPacket(
            status: HaLowInterfaceStatus(licenseStatus: entry.key),
          ),
        );
        await ble.flushEvents();

        expect(session.state.status?.licenseStatus, entry.value);
        expect(
          session.state.status?.licensed,
          entry.value == EdgezLicenseStatus.authorized,
        );
        expect(session.state.status?.licenseStatus.label, isNotEmpty);
      }

      session.dispose();
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
      expect(session.state.connection, EdgezConnectionType.none);
      expect(session.state.bleConnecting, isTrue);
      expect(session.state.statusLine, contains('waiting for Android'));

      ble.emitConnection(EdgezConnectionType.ble);
      await ble.flushEvents();
      expect(session.state.connection, EdgezConnectionType.ble);
      expect(session.state.bleConnecting, isFalse);
      expect(session.state.bleReady, isFalse);
      expect(session.state.statusLine, contains('setting up control channel'));

      ble.emitReady();
      await ble.flushEvents();
      await ble.flushEvents();

      expect(session.state.connection, EdgezConnectionType.ble);
      expect(session.state.bleReady, isTrue);
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

      // Android can rebuild the writable GATT channel without exposing the
      // brief disconnected state to Dart. A new ready event must resend INIT
      // even though the mesh configuration is unchanged.
      ble.emitReady();
      await ble.flushEvents();
      await ble.flushEvents();
      expect(ble.callsFor('initializeMesh'), hasLength(2));

      session.dispose();
    });

    test('session retries INIT while BLE status says HaLow is not booted',
        () async {
      final session = EdgezMeshSession(
        sdk: sdk,
        halowBootRetryDelay: const Duration(milliseconds: 10),
      );
      final identity = await _newIdentity('Retry user', 11, 21);
      await session.initializeMesh(EdgezMeshConfig(
        identity: identity,
        meshId: 'retry-mesh',
        passphrase: 'retry-secret',
      ));
      await session.connectBle('11:22:33:44:55:66');
      ble.emitConnection(EdgezConnectionType.ble);
      ble.emitReady();
      await ble.flushEvents();
      await ble.flushEvents();
      expect(ble.callsFor('initializeMesh'), hasLength(1));

      ble.emitPacket(NetworkPacket(
        status: HaLowInterfaceStatus(
          supported: true,
          stackInitialized: false,
        ),
      ));
      await ble.flushEvents();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await ble.flushEvents();
      await ble.flushEvents();

      expect(ble.callsFor('initializeMesh'), hasLength(2));
      session.dispose();
    });

    test('session reconnects BLE when the device status times out', () async {
      final session = EdgezMeshSession(
        sdk: sdk,
        deviceStatusTimeout: const Duration(milliseconds: 10),
      );
      final identity = await _newIdentity('Reconnect user', 12, 22);
      await session.initializeMesh(EdgezMeshConfig(
        identity: identity,
        meshId: 'reconnect-mesh',
        passphrase: 'reconnect-secret',
      ));
      await session.connectBle('11:22:33:44:55:66');
      ble.emitConnection(EdgezConnectionType.ble);
      ble.emitReady();
      await ble.flushEvents();
      await ble.flushEvents();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await ble.flushEvents();

      expect(ble.callsFor('disconnect'), hasLength(1));
      expect(ble.callsFor('connectBle'), hasLength(2));
      session.dispose();
    });

    test('session initializes mesh over USB when USB becomes ready', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final identity = await _newIdentity('USB user', 30, 40);
      await session.initializeMesh(
        EdgezMeshConfig(
          identity: identity,
          countryCode: 'US',
          meshId: 'usb-mesh',
          passphrase: 'usb-secret',
          meshBandwidthMhz: 1,
          meshFrequencyKhz: 902500,
        ),
      );
      const device = EdgezUsbDevice(
        id: 7,
        name: 'ESP32-S3 USB',
        vendorId: 0x303a,
        productId: 0x1001,
      );

      await session.connectUsb(device);
      ble.emitConnection(EdgezConnectionType.usb);
      ble.emitReady();
      await ble.flushEvents();
      await ble.flushEvents();

      expect(session.state.connection, EdgezConnectionType.usb);
      expect(session.state.bleReady, isTrue);
      final initPacket = ble.callsFor('initializeMesh').single.packet;
      expect(initPacket.init.meshId, 'usb-mesh');
      expect(initPacket.init.meshFrequencyKhz, 902500);

      ble.emitUsbLinkStats(
        sentPings: 3,
        receivedPings: 2,
        receivedPongs: 3,
        rttMs: 12,
      );
      await ble.flushEvents();
      expect(session.state.usbLinkStats.bidirectional, isTrue);
      expect(session.state.usbLinkStats.rttMs, 12);

      // Reopening CP2102 can reset the ESP32 and clear its in-RAM SDK release
      // authorization. The identical init packet must therefore be resent.
      await session.connectUsb(device);
      ble.emitConnection(EdgezConnectionType.usb);
      ble.emitReady();
      await ble.flushEvents();
      await ble.flushEvents();
      expect(ble.callsFor('initializeMesh'), hasLength(2));

      session.dispose();
    });

    test('session sends periodic GPS with the dedicated protocol', () async {
      ble.results['getBestKnownLocation'] = <Object?, Object?>{
        'latitude': 59.3293,
        'longitude': 18.0686,
        'timestampMs': 123456,
      };
      final session = EdgezMeshSession(sdk: sdk);
      final identity = await _newIdentity('Tracking user', 30, 40);

      ble.emitConnection(EdgezConnectionType.ble);
      ble.emitReady();
      await ble.flushEvents();

      await session.initializeMesh(
        EdgezMeshConfig(
          identity: identity,
          beacon: const EdgezBeaconConfig(
            shareLocation: true,
            intervalSeconds: 3600,
          ),
        ),
      );
      await ble.flushEvents();

      expect(
        ble.callsFor('sendPacket').where(
              (call) => call.argumentMap['label'] == 'GPS location update',
            ),
        isEmpty,
      );

      ble.emitPacket(
        NetworkPacket(
          status: HaLowInterfaceStatus(
            supported: true,
            stackInitialized: true,
            meshMode: true,
            linkUp: true,
            routeReady: true,
            firmwareVersion: '0.5.5',
          ),
        ),
      );
      await ble.flushEvents();
      await ble.flushEvents();

      final locationCalls = ble.callsFor('sendPacket').where(
            (call) => call.argumentMap['label'] == 'GPS location update',
          );
      expect(locationCalls, hasLength(1));
      expect(locationCalls.single.packet.hasLocationUpdate(), isTrue);
      expect(
        locationCalls.single.packet.locationUpdate.latitude,
        closeTo(59.3293, 0.0001),
      );

      // Repeated status reports must not restart location tracking and cause
      // another immediate GPS transmission.
      ble.emitPacket(
        NetworkPacket(
          status: HaLowInterfaceStatus(
            supported: true,
            stackInitialized: true,
            meshMode: true,
            linkUp: true,
            routeReady: true,
            firmwareVersion: '0.5.5',
          ),
        ),
      );
      await ble.flushEvents();
      expect(
        ble.callsFor('sendPacket').where(
              (call) => call.argumentMap['label'] == 'GPS location update',
            ),
        hasLength(1),
      );
      session.dispose();
    });

    test('session clears the connecting state when BLE connect fails',
        () async {
      ble.errors['connectBle'] = StateError('mock connection failed');
      final session = EdgezMeshSession(sdk: sdk);

      await session.connectBle('unreachable');

      expect(session.state.connection, EdgezConnectionType.none);
      expect(session.state.bleConnecting, isFalse);
      expect(session.state.statusLine, contains('BLE connect failed'));
      session.dispose();
    });

    test('session keeps cached nodes and conversations across disconnect',
        () async {
      final session = EdgezMeshSession(sdk: sdk);
      const nodeNum = 0x112233445566;
      const node = EdgezMeshNode(
        nodeNum: nodeNum,
        userUuid: 'remote-user',
        displayName: 'Remote user',
        route: 'BLE',
        lastSeenMs: 100,
        marker: 'green',
        deviceType: 'User',
      );
      const message = EdgezConversationMessage(
        nodeNum: nodeNum,
        text: 'Retained message',
        mine: false,
        timestampMs: 100,
        messageUuid: 'retained-message',
        status: '',
      );
      session.restoreCachedMeshData(
        nodes: const <int, EdgezMeshNode>{nodeNum: node},
        conversations: const <int, List<EdgezConversationMessage>>{
          nodeNum: <EdgezConversationMessage>[message],
        },
      );

      await session.disconnect();

      expect(session.state.connection, EdgezConnectionType.none);
      expect(session.state.status, isNull);
      expect(session.state.nodes[nodeNum], node);
      expect(session.state.conversations[nodeNum], <EdgezConversationMessage>[
        message,
      ]);
      expect(session.state.statusLine, 'Disconnected');
      session.dispose();
    });

    test('session stores one reusable transcript on a voice message', () {
      final session = EdgezMeshSession(sdk: sdk);
      const message = EdgezConversationMessage(
        nodeNum: 7,
        text: 'Voice message',
        mine: false,
        timestampMs: 100,
        messageUuid: 'voice-1',
        voiceBytes: <int>[1, 2, 3],
        voiceCodec: 2,
      );
      session.restoreCachedMeshData(
        nodes: const <int, EdgezMeshNode>{},
        conversations: const <int, List<EdgezConversationMessage>>{
          7: <EdgezConversationMessage>[message],
        },
      );

      session.updateConversationMessageTranscript(
        message,
        transcript: '你好，世界。',
        language: 'Chinese',
      );

      final saved = session.state.conversations[7]!.single;
      expect(saved.transcript, '你好，世界。');
      expect(saved.transcriptLanguage, 'Chinese');
      expect(saved.voiceBytes, message.voiceBytes);
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
            SensorData(
              type: SensorType.SENSOR_LATITUDE,
              floatValue: 0,
            ),
            SensorData(
              type: SensorType.SENSOR_LONGITUDE,
              floatValue: 0,
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
      expect(sample.latitude, isNull);
      expect(sample.longitude, isNull);

      session.dispose();
    });

    test('session decodes GPS sensor values from topology peers', () async {
      final session = EdgezMeshSession(sdk: sdk);
      final packet = NetworkPacket(
        from: Int64(0x112233445566),
        operation: Operation.RESPONSE,
        interface: Interface.HALOW,
        report: Report(
          peers: <Peer>[
            Peer(
              id: Int64(0x223344556677),
              rssi: 950,
              sensorData: <SensorData>[
                SensorData(
                  type: SensorType.SENSOR_LATITUDE,
                  floatValue: 59.3293,
                ),
                SensorData(
                  type: SensorType.SENSOR_LONGITUDE,
                  floatValue: 18.0686,
                ),
              ],
            ),
          ],
        ),
      );

      ble.emitPacket(packet);
      await ble.flushEvents();

      final samples = session.state.sensorSamples[0x223344556677];
      expect(samples, hasLength(1));
      expect(samples!.single.data.latitude, closeTo(59.3293, 0.001));
      expect(samples.single.data.longitude, closeTo(18.0686, 0.001));
      expect(session.state.nodes[0x223344556677]?.hasLocation, isTrue);
      expect(
        session.state.nodes[0x223344556677]?.latitude,
        closeTo(59.3293, 0.001),
      );
      expect(
        session.state.nodes[0x223344556677]?.longitude,
        closeTo(18.0686, 0.001),
      );
      expect(session.state.topologyLinks, hasLength(1));

      ble.emitPacket(
        NetworkPacket(
          from: Int64(0x112233445566),
          operation: Operation.RESPONSE,
          interface: Interface.HALOW,
          report: Report(
            peers: <Peer>[
              Peer(
                id: Int64(0x223344556677),
                rssi: 950,
                sensorData: <SensorData>[
                  SensorData(
                    type: SensorType.SENSOR_LATITUDE,
                    floatValue: 0,
                  ),
                  SensorData(
                    type: SensorType.SENSOR_LONGITUDE,
                    floatValue: 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await ble.flushEvents();

      expect(session.state.sensorSamples[0x223344556677], hasLength(1));
      expect(
        session.state.nodes[0x223344556677]?.latitude,
        closeTo(59.3293, 0.001),
      );
      expect(
        session.state.nodes[0x223344556677]?.longitude,
        closeTo(18.0686, 0.001),
      );

      session.dispose();
    });

    test('session keeps requested BATMAN routes separate from topology links',
        () async {
      final session = EdgezMeshSession(sdk: sdk);
      ble.emitPacket(
        NetworkPacket(
          from: Int64(0x112233445566),
          operation: Operation.RESPONSE,
          interface: Interface.HALOW,
          routingTable: RoutingTable(
            routes: <RouteEntry>[
              RouteEntry(
                destination: Int64(0x223344556677),
                nextHop: Int64(0x223344556677),
                tq: 240,
                hops: 1,
                ageMs: 120,
              ),
              RouteEntry(
                destination: Int64(0x334455667788),
                nextHop: Int64(0x223344556677),
                tq: 180,
                hops: 2,
                ageMs: 850,
              ),
            ],
          ),
        ),
      );
      await ble.flushEvents();

      expect(session.state.routingTable, hasLength(2));
      expect(session.state.routingTable.first.isDirect, isTrue);
      expect(session.state.routingTable.last.isDirect, isFalse);
      expect(session.state.routingTable.last.nextHopNodeNum, 0x223344556677);
      expect(session.state.topologyLinks, isEmpty);
      expect(session.state.routingTableLoading, isFalse);

      session.dispose();
    });

    test('session excludes the local device from discovered nodes', () async {
      const localNode = 0x112233445566;
      final session = EdgezMeshSession(sdk: sdk);

      ble.emitNode(
        const EdgezMeshNode(
          nodeNum: localNode,
          userUuid: '',
          displayName: 'Local device',
          route: 'HALOW',
          lastSeenMs: 1,
          marker: 'blue',
        ),
      );
      await ble.flushEvents();
      expect(session.state.nodes, contains(localNode));

      ble.emitPacket(
        NetworkPacket(
          status: HaLowInterfaceStatus(macAddress: Int64(localNode)),
        ),
      );
      await ble.flushEvents();
      expect(session.state.nodes, isNot(contains(localNode)));

      ble.emitPacket(
        NetworkPacket(
          from: Int64(localNode),
          operation: Operation.RESPONSE,
          interface: Interface.HALOW,
          report: Report(
            peers: <Peer>[
              Peer(
                id: Int64(localNode),
                sensorData: <SensorData>[
                  SensorData(
                    type: SensorType.SENSOR_LATITUDE,
                    floatValue: 59.3293,
                  ),
                  SensorData(
                    type: SensorType.SENSOR_LONGITUDE,
                    floatValue: 18.0686,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await ble.flushEvents();

      expect(session.state.nodes, isNot(contains(localNode)));
      expect(session.state.sensorSamples, isNot(contains(localNode)));
      session.dispose();
    });

    test('session uses a self beacon as the device GPS location', () async {
      const localNode = 0x112233445566;
      final session = EdgezMeshSession(sdk: sdk);

      ble.emitPacket(
        NetworkPacket(
          status: HaLowInterfaceStatus(macAddress: Int64(localNode)),
        ),
      );
      ble.emitPacket(
        NetworkPacket(
          deviceSettings: DeviceSettings(
            action: DeviceSettingsAction.DEVICE_SETTINGS_REPORT,
            deviceGpsEnabled: true,
          ),
        ),
      );
      ble.emitPacket(
        NetworkPacket(
          from: Int64(localNode),
          operation: Operation.RESPONSE,
          interface: Interface.HALOW,
          beacon: Beacon(
            userIdHigh: Int64(10),
            userIdLow: Int64(20),
            userName: 'Local GPS',
            latitude: 59.3293,
            longitude: 18.0686,
          ),
        ),
      );
      await ble.flushEvents();

      expect(session.state.deviceSettings?.deviceGpsEnabled, isTrue);
      expect(session.state.selfLocation, isNotNull);
      expect(session.state.selfLocation!.latitude, closeTo(59.3293, 0.001));
      expect(session.state.selfLocation!.longitude, closeTo(18.0686, 0.001));
      expect(session.state.nodes, isNot(contains(localNode)));

      await session.setDeviceGpsEnabled(false);
      final settingsPacket = ble.callsFor('sendPacket').last.packet;
      expect(settingsPacket.deviceSettings.deviceGpsEnabled, isFalse);

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

      expect(
        session.state.nodes.values.where((node) => !node.isPublicChannel),
        hasLength(1),
      );
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
      expect(
        ble.callsFor('sendVoiceCallFrame').first.argumentMap['waitForDrainMs'],
        1500,
      );

      await session.endVoiceCall();
      expect(session.state.voiceCall.phase, EdgezVoiceCallPhase.idle);
      expect(ble.callsFor('stopOpenManetComms'), hasLength(1));
      await ble.flushEvents();
      expect(ble.callsFor('sendVoiceCallFrame'), hasLength(2));

      session.dispose();
    });

    test('voice call decrypts and plays BLE audio frames in order', () async {
      final voiceSdk = _OrderedVoiceSdk();
      EdgezVoiceCallState? incomingCall;
      EdgezMeshNode? incomingCaller;
      final session = EdgezMeshSession(
        sdk: voiceSdk,
        onIncomingCall: (call, caller) {
          incomingCall = call;
          incomingCaller = caller;
        },
      );
      const remoteNode = 0x223344556677;
      const localNode = 0x112233445566;
      const identity = EdgezUserIdentity(
        userIdHigh: 70,
        userIdLow: 80,
        name: 'Local caller',
        publicKey: <int>[1],
      );
      await session.initializeMesh(const EdgezMeshConfig(identity: identity));
      voiceSdk.emit(
        EdgezMeshEvent(
          type: EdgezMeshEventType.status,
          status: const EdgezMeshStatus(
            supported: true,
            macAddress: localNode,
            stackInitialized: true,
            meshMode: true,
            linkUp: true,
            routeReady: true,
            readyForReport: true,
            meshId: 'edgez',
            ipAddress: '',
            gateway: '',
          ),
        ),
      );
      voiceSdk.emit(
        const EdgezMeshEvent(
          type: EdgezMeshEventType.node,
          node: EdgezMeshNode(
            nodeNum: remoteNode,
            userUuid: 'remote',
            displayName: 'Remote caller',
            route: 'BLE',
            lastSeenMs: 1,
            marker: 'blue',
            publicKey: <int>[2],
          ),
        ),
      );
      await voiceSdk.flush();

      voiceSdk.plaintexts[9] = _voicePacket(1, 1234, 9);
      voiceSdk.emitVoice(remoteNode, 9);
      await voiceSdk.flush();
      expect(incomingCall?.phase, EdgezVoiceCallPhase.incoming);
      expect(incomingCall?.callId, 1234);
      expect(incomingCaller?.nodeNum, remoteNode);
      await session.endVoiceCall();
      voiceSdk.decryptStarted.clear();

      await session.startVoiceCall(remoteNode);
      final callId = session.state.voiceCall.callId;
      voiceSdk.plaintexts[1] = _voicePacket(2, callId, 1);
      voiceSdk.emitVoice(remoteNode, 1);
      await voiceSdk.flush();
      expect(session.state.voiceCall.phase, EdgezVoiceCallPhase.active);

      voiceSdk.plaintexts[2] = _voicePacket(4, callId, 2, <int>[11]);
      voiceSdk.plaintexts[3] = _voicePacket(4, callId, 3, <int>[22]);
      voiceSdk.emitVoice(remoteNode, 2);
      voiceSdk.emitVoice(remoteNode, 3);
      await voiceSdk.flush();

      expect(voiceSdk.decryptStarted, <int>[1, 2]);
      voiceSdk.releaseFirstAudio.complete();
      await voiceSdk.flush();
      await voiceSdk.flush();
      expect(voiceSdk.decryptStarted, <int>[1, 2, 3]);
      expect(voiceSdk.played, <int>[11, 22]);

      session.dispose();
      await voiceSdk.close();
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

      expect(session.state.nodes.values.where((node) => !node.isPublicChannel),
          isEmpty);
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
      expect(ble.lastPacketCall.argumentMap['waitForDrainMs'], 3000);
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

      EdgezConversationMessage? incomingMessage;
      EdgezMeshNode? incomingSender;
      final receiverSession = EdgezMeshSession(
        sdk: receiverSdk,
        onIncomingMessage: (message, senderNode) {
          incomingMessage = message;
          incomingSender = senderNode;
        },
      );
      await receiverSession.initializeMesh(
        EdgezMeshConfig(identity: receiver),
      );
      receiverBle.emitPacket(
        NetworkPacket(
          from: Int64(0x100),
          operation: Operation.BROADCAST,
          interface: Interface.HALOW,
          beacon: Beacon(
            userIdHigh: Int64(sender.userIdHigh),
            userIdLow: Int64(sender.userIdLow),
            userName: sender.name,
            userPublicKey: sender.publicKey,
          ),
        ),
      );
      await receiverBle.flushEvents();
      receiverBle.emitRawPacketBytes(packet.writeToBuffer());
      for (var attempt = 0;
          attempt < 10 && incomingMessage == null;
          attempt++) {
        await receiverBle.flushEvents();
      }
      expect(incomingMessage?.text, 'hello over mocked BLE');
      expect(incomingMessage?.mine, isFalse);
      expect(incomingSender?.displayName, sender.name);
      receiverSession.dispose();
      await receiverBle.close();
    });

    test('recorded voice chunks request transport drain back-pressure',
        () async {
      final sender = await _newIdentity('Voice sender', 300, 301);
      final receiver = await _newIdentity('Voice receiver', 400, 401);
      final receiverNode = EdgezMeshNode(
        nodeNum: 0x400,
        userUuid: '',
        displayName: receiver.name,
        route: 'USB',
        lastSeenMs: 1,
        marker: 'blue',
        publicKey: receiver.publicKey,
        deviceType: 'User',
      );

      await sdk.sendVoiceMessage(
        config: EdgezMeshConfig(identity: sender),
        toNode: receiverNode,
        fromNode: 0x300,
        bytes: List<int>.generate(600, (index) => index & 0xff),
        durationMs: 1000,
        codec: 1,
      );

      final calls = ble.callsFor('sendPacket').toList(growable: false);
      expect(calls, hasLength(3));
      expect(
        calls.every((call) => call.argumentMap['waitForDrainMs'] == 3000),
        isTrue,
      );
      expect(calls.every((call) => call.packet.msg.mime == Mime.MIME_VOICE),
          isTrue);

      final receiverTransport = MockBleTransport();
      final receiverSdk = EdgezMeshSdk(transport: receiverTransport);
      final decodedAudio = <int>[];
      for (var index = 0; index < calls.length; index++) {
        final chunk = await receiverSdk.decryptVoiceChunk(
          config: EdgezMeshConfig(identity: receiver),
          sender: EdgezMeshNode(
            nodeNum: 0x300,
            userUuid: '',
            displayName: sender.name,
            route: 'USB',
            lastSeenMs: 1,
            marker: 'blue',
            publicKey: sender.publicKey,
            deviceType: 'User',
          ),
          fromNode: 0x300,
          toNode: 0x400,
          payload: calls[index].packet.msg.payload,
        );
        expect(chunk.index, index);
        expect(chunk.totalChunks, calls.length);
        decodedAudio.addAll(chunk.audio);
      }
      expect(decodedAudio, List<int>.generate(600, (index) => index & 0xff));
      await receiverTransport.close();
    });

    test('speed test sends exactly 2 MiB as binary streaming frames', () async {
      final progressUpdates = <(int, int)>[];
      await sdk.sendSpeedTest(
        toNode: 0x200,
        fromNode: 0x100,
        hop: 3,
        onProgress: (sent, total) => progressUpdates.add((sent, total)),
      );

      final calls = ble.callsFor('sendSpeedTestFrame').toList(growable: false);
      final frames = calls
          .map((call) => EdgezSpeedTestFrame.tryDecode(
                call.argumentMap['payload']! as List<int>,
              ))
          .whereType<EdgezSpeedTestFrame>()
          .toList();
      expect(frames.first.type, EdgezSpeedTestFrameType.start);
      expect(frames.last.type, EdgezSpeedTestFrameType.end);
      expect(
        frames
            .where((frame) => frame.type == EdgezSpeedTestFrameType.data)
            .fold<int>(0, (total, frame) => total + frame.data.length),
        EdgezMeshSdk.speedTestBytes,
      );
      expect(calls.every((call) => call.argumentMap['to'] == 0x200), isTrue);
      expect(calls.every((call) => call.argumentMap['maxHop'] == 3), isTrue);
      // Native adds a 3-byte protocol marker and an 11-byte route prefix.
      // The complete BLE/USB payload must fit the shared 512-byte limit.
      expect(
        calls.every(
          (call) =>
              3 + 11 + (call.argumentMap['payload']! as List<int>).length <=
              512,
        ),
        isTrue,
      );
      // Firmware adds the EdgeZ route prefix and inner Ethernet frame before
      // BATMAN adds its unicast header. The resulting radio frame must also
      // remain within BATMAN's 512-byte packet limit.
      expect(
        calls.every(
          (call) =>
              38 +
                  14 +
                  10 +
                  (call.argumentMap['payload']! as List<int>).length <=
              512,
        ),
        isTrue,
      );
      final drainCalls = calls
          .where((call) => call.argumentMap.containsKey('waitForDrainMs'))
          .toList(growable: false);
      expect(drainCalls, isNotEmpty);
      expect(drainCalls.first.argumentMap['sequence'], 7);
      expect(drainCalls.last.argumentMap['sequence'], frames.length);
      expect(drainCalls.last.argumentMap['waitForDrainMs'], 10000);
      // A transfer completing inside one second publishes only its final
      // progress value instead of rebuilding UI state for every data frame.
      expect(progressUpdates, <(int, int)>[
        (EdgezMeshSdk.speedTestBytes, EdgezMeshSdk.speedTestBytes),
      ]);
    });

    test('speed test uses route TTL without duplicating the hop rule in frame',
        () async {
      final sentPackets = <(int, int)>[];
      await sdk.sendSpeedTest(
        toNode: 0x200,
        fromNode: 0x100,
        totalBytes: 384,
        hop: 2,
        onPacketSent: (bytes, sequence) => sentPackets.add((bytes, sequence)),
      );

      final calls = ble.callsFor('sendSpeedTestFrame').toList(growable: false);
      expect(calls, hasLength(3));
      final frames = calls
          .map((call) => EdgezSpeedTestFrame.tryDecode(
                call.argumentMap['payload']! as List<int>,
              ))
          .whereType<EdgezSpeedTestFrame>()
          .toList(growable: false);
      expect(frames.map((frame) => frame.type), <EdgezSpeedTestFrameType>[
        EdgezSpeedTestFrameType.start,
        EdgezSpeedTestFrameType.data,
        EdgezSpeedTestFrameType.end,
      ]);
      expect(calls.every((call) => call.argumentMap['maxHop'] == 2), isTrue);
      final dataPayload = calls[1].argumentMap['payload']! as List<int>;
      expect(dataPayload[4], 3);
      expect(dataPayload, hasLength(26 + 384));
      final obsoleteV2 = List<int>.from(dataPayload)..[4] = 2;
      expect(EdgezSpeedTestFrame.tryDecode(obsoleteV2), isNull);
      expect(sentPackets, <(int, int)>[(26, 1), (410, 2), (26, 3)]);
      expect(calls.last.argumentMap['waitForDrainMs'], 10000);
    });

    test('speed test rejects hop rules outside 0 through 3', () async {
      await expectLater(
        sdk.sendSpeedTest(toNode: 0x200, fromNode: 0x100, hop: 4),
        throwsArgumentError,
      );
    });

    test('speed repair resends only chunks selected by the missing bitmap',
        () async {
      final request = EdgezSpeedTestFrame.repairRequest(
        transferId: 77,
        totalBytes: 4 * 424,
        totalChunks: 4,
        baseChunk: 0,
        missingBitmap: Uint8List.fromList(<int>[0x05]),
      );

      await sdk.resendSpeedTestChunks(
        toNode: 0x200,
        hop: 2,
        request: request,
      );

      final calls = ble.callsFor('sendSpeedTestFrame').toList(growable: false);
      final frames = calls
          .map((call) => EdgezSpeedTestFrame.tryDecode(
                call.argumentMap['payload']! as List<int>,
              ))
          .whereType<EdgezSpeedTestFrame>()
          .toList(growable: false);
      expect(frames.map((frame) => frame.chunkIndex), <int>[0, 2]);
      expect(
          frames.every((frame) => frame.type == EdgezSpeedTestFrameType.data),
          isTrue);
      expect(calls.every((call) => call.argumentMap['maxHop'] == 2), isTrue);
      expect(frames[1].data.take(3), <int>[2, 3, 4]);
    });

    test('receiver waits for END before publishing a complete speed test',
        () async {
      final session = EdgezMeshSession(sdk: sdk);
      const fromNode = 0x100;
      const transferId = 41;
      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.start(
          transferId: transferId,
          totalBytes: 3,
          totalChunks: 1,
        ),
      );
      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.data(
          transferId: transferId,
          totalBytes: 3,
          totalChunks: 1,
          chunkIndex: 0,
          data: Uint8List.fromList(<int>[1, 2, 3]),
        ),
      );
      await ble.flushEvents();
      expect(session.state.linkStats[fromNode], isNull);

      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.end(
          transferId: transferId,
          totalBytes: 3,
          totalChunks: 1,
        ),
      );
      await ble.flushEvents();
      expect(session.state.linkStats[fromNode]?.packetLossPercent, 0);
      session.dispose();
    });

    test('receiver requests missing speed chunks after END', () async {
      final session = EdgezMeshSession(
        sdk: sdk,
        speedTestInactivityTimeout: const Duration(seconds: 5),
        speedTestReliableDelivery: true,
      );
      const fromNode = 0x100;
      const transferId = 78;
      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.start(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
        ),
      );
      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.data(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
          chunkIndex: 1,
          data: Uint8List.fromList(<int>[1, 2, 3]),
        ),
      );
      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.end(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
        ),
      );
      await ble.flushEvents();

      final repair = ble
          .callsFor('sendSpeedTestFrame')
          .map((call) => EdgezSpeedTestFrame.tryDecode(
                call.argumentMap['payload']! as List<int>,
              ))
          .whereType<EdgezSpeedTestFrame>()
          .singleWhere(
            (frame) => frame.type == EdgezSpeedTestFrameType.repairRequest,
          );
      expect(repair.chunkIndex, 0);
      expect(repair.data, <int>[0x05]);
      session.dispose();
    });

    test('best-effort receiver reports loss without requesting repair',
        () async {
      final session = EdgezMeshSession(
        sdk: sdk,
        speedTestInactivityTimeout: const Duration(milliseconds: 10),
      );
      const fromNode = 0x100;
      const transferId = 79;
      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.start(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
        ),
      );
      ble.emitSpeedTestFrame(
        fromNode: fromNode,
        frame: EdgezSpeedTestFrame.end(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
        ),
      );
      await ble.flushEvents();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final sentTypes = ble
          .callsFor('sendSpeedTestFrame')
          .map((call) => EdgezSpeedTestFrame.tryDecode(
                call.argumentMap['payload']! as List<int>,
              ))
          .whereType<EdgezSpeedTestFrame>()
          .map((frame) => frame.type);
      expect(sentTypes, isNot(contains(EdgezSpeedTestFrameType.repairRequest)));
      expect(session.state.linkStats[fromNode]?.packetLossPercent, 100);
      session.dispose();
    });

    test('speed result is visible on receiver and sent to the sender',
        () async {
      final sender = await _newIdentity('Speed sender', 500, 501);
      final receiver = await _newIdentity('Speed receiver', 600, 601);
      final session = EdgezMeshSession(
        sdk: sdk,
        speedTestInactivityTimeout: const Duration(seconds: 1),
      );
      const fromNode = 0x100;
      const localNode = 0x200;
      const transferId = 42;

      await session.initializeMesh(EdgezMeshConfig(identity: receiver));
      ble.emitPacket(
        NetworkPacket(
          status: HaLowInterfaceStatus(macAddress: Int64(localNode)),
        ),
      );
      ble.emitPacket(
        NetworkPacket(
          from: Int64(fromNode),
          operation: Operation.BROADCAST,
          interface: Interface.HALOW,
          beacon: Beacon(
            userIdHigh: Int64(sender.userIdHigh),
            userIdLow: Int64(sender.userIdLow),
            userName: sender.name,
            userPublicKey: sender.publicKey,
          ),
        ),
      );
      await ble.flushEvents();

      void emit(EdgezSpeedTestFrame frame, int timestampSeconds) {
        ble.emitSpeedTestFrame(
          fromNode: fromNode,
          frame: frame,
          receivedAtUs: timestampSeconds * 1000000,
        );
      }

      emit(
        EdgezSpeedTestFrame.start(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
        ),
        1,
      );
      emit(
        EdgezSpeedTestFrame.data(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
          chunkIndex: 0,
          data: Uint8List.fromList(<int>[1, 2, 3]),
        ),
        2,
      );
      await ble.flushEvents();
      // A congested link may pause for longer than the old two-second timeout.
      // The receiver must retain earlier chunks until END arrives.
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      emit(
        EdgezSpeedTestFrame.data(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
          chunkIndex: 2,
          data: Uint8List.fromList(<int>[7, 8, 9]),
        ),
        4,
      );
      await ble.flushEvents();

      // Rolling presentation updates are available once per second without
      // rebuilding state for every received radio frame.
      expect(session.state.linkStats[fromNode], isNotNull);
      expect(session.state.conversations[fromNode], isNull);

      emit(
        EdgezSpeedTestFrame.end(
          transferId: transferId,
          totalBytes: 9,
          totalChunks: 3,
        ),
        5,
      );
      await ble.flushEvents();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      final completed = session.state.linkStats[fromNode];
      expect(session.state.sharedLinkStats, isNotNull);
      expect(
        session.state.sharedLinkStats!.updatedAtMs,
        greaterThan(1000000000000),
      );
      expect(completed?.bitsPerSecond, greaterThan(0));
      expect(completed?.packetLossPercent, closeTo(33.33, 0.01));
      expect(completed?.receivedPackets, 2);
      expect(completed?.expectedPackets, 3);

      for (var attempt = 0;
          attempt < 10 &&
              !ble.callsFor('sendPacket').any(
                    (call) =>
                        call.packet.hasMsg() &&
                        call.packet.msg.mime == Mime.MIME_TEXT,
                  );
          attempt++) {
        await ble.flushEvents();
      }
      final resultPacket = ble.callsFor('sendPacket').lastWhere(
            (call) =>
                call.packet.hasMsg() && call.packet.msg.mime == Mime.MIME_TEXT,
          );
      final resultText = await sdk.decryptTextMessage(
        config: EdgezMeshConfig(identity: sender),
        sender: EdgezMeshNode(
          nodeNum: localNode,
          userUuid: '',
          displayName: receiver.name,
          route: 'BLE',
          lastSeenMs: 1,
          marker: 'blue',
          publicKey: receiver.publicKey,
          deviceType: 'User',
        ),
        fromNode: localNode,
        toNode: fromNode,
        payload: resultPacket.packet.msg.payload,
      );
      expect(resultText, contains('Speed test result'));
      expect(resultText, contains('Average speed:'));
      expect(resultText, contains('Packet loss: 33.33%'));
      final receiverMessages = session.state.conversations[fromNode]!;
      expect(receiverMessages, hasLength(1));
      expect(receiverMessages.single.mine, isTrue);
      expect(receiverMessages.single.text, resultText);
      expect(receiverMessages.single.status, startsWith('Sent via'));

      final senderBle = MockBleTransport();
      final senderSession = EdgezMeshSession(
        sdk: EdgezMeshSdk(transport: senderBle),
      );
      await senderSession.initializeMesh(EdgezMeshConfig(identity: sender));
      senderBle.emitPacket(
        NetworkPacket(
          from: Int64(localNode),
          operation: Operation.BROADCAST,
          interface: Interface.HALOW,
          beacon: Beacon(
            userIdHigh: Int64(receiver.userIdHigh),
            userIdLow: Int64(receiver.userIdLow),
            userName: receiver.name,
            userPublicKey: receiver.publicKey,
          ),
        ),
      );
      await senderBle.flushEvents();
      senderBle.emitRawPacketBytes(resultPacket.packet.writeToBuffer());
      for (var attempt = 0;
          attempt < 10 &&
              (senderSession.state.conversations[localNode]?.isEmpty ?? true);
          attempt++) {
        await senderBle.flushEvents();
      }
      final senderMessages = senderSession.state.conversations[localNode]!;
      expect(senderMessages, hasLength(1));
      expect(senderMessages.single.mine, isFalse);
      expect(senderMessages.single.text, resultText);
      senderSession.dispose();
      await senderBle.close();
      session.dispose();
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

const _testReleaseCredential = EdgezSdkReleaseCredential(
  compatibility: '^0.5.0',
  releaseId: 'edgez_flutter_sdk@test',
  signatureHex: '000102030405060708090a0b0c0d0e0f'
      '101112131415161718191a1b1c1d1e1f'
      '202122232425262728292a2b2c2d2e2f'
      '303132333435363738393a3b3c3d3e3f',
);

Uint8List _voicePacket(int type, int callId, int sequence,
    [List<int> audio = const <int>[]]) {
  final packet = Uint8List(17 + audio.length);
  packet.setRange(0, 4, const <int>[0x45, 0x56, 0x43, 0x32]);
  final data = ByteData.sublistView(packet);
  data.setUint8(4, type);
  data.setInt64(5, callId, Endian.little);
  data.setInt32(13, sequence, Endian.little);
  packet.setRange(17, packet.length, audio);
  return packet;
}

class _OrderedVoiceSdk extends EdgezMeshSdk {
  _OrderedVoiceSdk() : super(transport: MockBleTransport());

  final StreamController<EdgezMeshEvent> _events =
      StreamController<EdgezMeshEvent>.broadcast();
  final Map<int, List<int>> plaintexts = <int, List<int>>{};
  final List<int> decryptStarted = <int>[];
  final List<int> played = <int>[];
  final Completer<void> releaseFirstAudio = Completer<void>();

  @override
  Stream<EdgezMeshEvent> get events => _events.stream;

  void emit(EdgezMeshEvent event) => _events.add(event);

  void emitVoice(int fromNode, int marker) {
    emit(
      EdgezMeshEvent(
        type: EdgezMeshEventType.voiceFrame,
        packet: <int>[
          for (var shift = 40; shift >= 0; shift -= 8)
            (fromNode >> shift) & 0xff,
          marker,
        ],
      ),
    );
  }

  @override
  Future<bool> requestMicrophonePermission() async => true;

  @override
  Future<void> startLiveVoiceAudio() async {}

  @override
  Future<void> stopLiveVoiceAudio() async {}

  @override
  Future<void> sendVoiceCallFrame({
    required EdgezMeshConfig config,
    required EdgezMeshNode toNode,
    required int fromNode,
    required List<int> plaintext,
    required int sequence,
    int maxHop = 0,
  }) async {}

  @override
  Future<EdgezVoiceCallEnvelope> decryptVoiceCallFrame({
    required EdgezMeshConfig config,
    required EdgezMeshNode sender,
    required int localNode,
    required List<int> payload,
  }) async {
    final marker = payload.last;
    decryptStarted.add(marker);
    if (marker == 2) await releaseFirstAudio.future;
    return EdgezVoiceCallEnvelope(
      fromNode: sender.nodeNum,
      sequence: marker,
      plaintext: plaintexts[marker]!,
    );
  }

  @override
  Future<void> playLiveVoiceAudio(List<int> audio) async {
    played.add(audio.single);
  }

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() => _events.close();
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
