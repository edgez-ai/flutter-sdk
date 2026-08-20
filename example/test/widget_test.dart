import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:edgez_flutter_sdk_example/src/conversation_screen.dart';
import 'package:edgez_flutter_sdk_example/src/dashboard_tab.dart';
import 'package:edgez_flutter_sdk_example/src/gemma_voice_translator.dart';
import 'package:edgez_flutter_sdk_example/src/models.dart';
import 'package:edgez_flutter_sdk_example/src/nodes_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:edgez_flutter_sdk_example/src/app.dart';
import 'package:edgez_flutter_sdk_example/src/provisioning_screen.dart';
import 'package:edgez_flutter_sdk_example/src/voice_call_screen.dart';

Finder findVerticalScrollable() => find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    );

void main() {
  test('provisioning excludes the BLE device selected in settings', () {
    const selected = EdgezBleDevice(
      id: 'selected',
      name: 'Current',
      rssi: -40,
      lastSeenMs: 1,
    );
    const other = EdgezBleDevice(
      id: 'other',
      name: 'Available',
      rssi: -50,
      lastSeenMs: 2,
    );

    expect(provisioningBleDevices([selected, other], selected.id), [other]);
  });

  testWidgets('example app opens on the dashboard tab', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Mesh overview'), findsOneWidget);
    expect(find.text('No dashboard devices yet'), findsOneWidget);
    expect(find.text('Debug'), findsNothing);
  });

  testWidgets('nodes opens topology as a separate page', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());

    await tester.tap(find.text('Nodes').last);
    await tester.pumpAndSettle();

    expect(find.text('Prov'), findsNothing);
    await tester.tap(find.text('Topology'));
    await tester.pumpAndSettle();
    expect(find.text('Mesh topology'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Nodes'), findsWidgets);
  });

  testWidgets('nodes are grouped in collapsible HaLow channel sections',
      (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(
      MaterialApp(
        home: NodesScreen(
          activeConnection: EdgezConnectionType.ble,
          status: null,
          meshCountry: 'US',
          users: <EdgezMeshNode>[
            EdgezPublicChannels.node(1),
            EdgezMeshNode(
              nodeNum: 1,
              userUuid: 'one',
              displayName: 'Node one',
              route: 'BLE',
              lastSeenMs: now,
              marker: 'blue',
              channelNumber: 1,
            ),
            EdgezMeshNode(
              nodeNum: 2,
              userUuid: 'two',
              displayName: 'Node two',
              route: 'BLE',
              lastSeenMs: now,
              marker: 'green',
              channelNumber: 2,
            ),
          ],
          sensorSamples: const <int, List<EdgezSensorSample>>{},
          dashboardDisplays: const <String, ExampleDashboardDisplay>{},
          onOpenTopology: () {},
          onRemoveNode: (_) {},
          onToggleDashboard: (_) {},
          onTogglePublicChannel: (_, __) {},
          onOpenNode: (_) {},
        ),
      ),
    );

    expect(find.text('Channel 1'), findsOneWidget);
    expect(find.text('Public channels'), findsOneWidget);
    expect(find.text('Talkgroup port 38801'), findsNothing);
    expect(find.text('902.500 MHz · 1 node'), findsOneWidget);
    expect(find.text('Channel 2'), findsOneWidget);
    expect(find.text('903.000 MHz · 1 node'), findsOneWidget);
    expect(find.text('Node one'), findsNothing);

    await tester.tap(find.text('Channel 1'));
    await tester.pumpAndSettle();
    expect(find.text('Node one'), findsOneWidget);
    expect(find.text('Node two'), findsNothing);

    await tester.tap(find.text('Public channels'));
    await tester.pumpAndSettle();
    expect(find.text('Talkgroup port 38801'), findsOneWidget);
  });

  testWidgets('dashboard opens the device provisioning flow', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());

    await tester.tap(find.text('Prov'));
    await tester.pumpAndSettle();

    expect(find.text('Provisioning'), findsOneWidget);
    expect(find.text('Step 1 of 8: Select BLE device'), findsOneWidget);
    expect(find.text('Scanning for EdgeZ devices...'), findsOneWidget);
  });

  testWidgets('dashboard renders Android-compatible visualization widgets',
      (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final users = <EdgezMeshNode>[
      for (var index = 0; index < 6; index++)
        EdgezMeshNode(
          nodeNum: index + 1,
          userUuid: 'node-$index',
          displayName: index == 0 ? 'Mesh user' : 'Sensor $index',
          route: 'BLE',
          lastSeenMs: now,
          marker: 'green',
          deviceType: index == 0 ? 'User' : 'Sensor',
        ),
    ];
    final widgets = <ExampleDashboardWidget>[
      ExampleDashboardWidget.tempHumidity,
      ExampleDashboardWidget.latestValue,
      ExampleDashboardWidget.imuOrientation,
      ExampleDashboardWidget.binaryData,
      ExampleDashboardWidget.timeSeries,
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          activeConnection: EdgezConnectionType.ble,
          status: null,
          users: users,
          sensorSamples: <int, List<EdgezSensorSample>>{
            for (final user in users.skip(1))
              user.nodeNum: <EdgezSensorSample>[
                EdgezSensorSample(
                  nodeNum: user.nodeNum,
                  timestampMs: now - 1000,
                  data: const EdgezSensorData(
                    temperature: 21,
                    humidity: 45,
                    accelX: 0.2,
                    accelY: 0.4,
                    accelZ: 9.7,
                    binaryLengthBytes: 128,
                  ),
                ),
                EdgezSensorSample(
                  nodeNum: user.nodeNum,
                  timestampMs: now,
                  data: const EdgezSensorData(
                    temperature: 22,
                    humidity: 46,
                    accelX: 0.3,
                    accelY: 0.5,
                    accelZ: 9.6,
                    binaryLengthBytes: 128,
                  ),
                ),
              ],
          },
          dashboardDisplays: <String, ExampleDashboardDisplay>{
            'node-0': const ExampleDashboardDisplay(
              deviceKey: 'node-0',
              showOnDashboard: true,
            ),
            for (var index = 0; index < widgets.length; index++)
              'node-${index + 1}': ExampleDashboardDisplay(
                deviceKey: 'node-${index + 1}',
                showOnDashboard: true,
                widget: widgets[index],
                range: widgets[index] == ExampleDashboardWidget.timeSeries
                    ? ExampleDashboardRange.last30Minutes
                    : ExampleDashboardRange.latest,
              ),
          },
          onOpenProvisioning: () {},
          onOpenMap: () {},
          mapCamera: null,
          onOpenNode: (_) {},
        ),
      ),
    );

    expect(find.text('Tap to open conversation'), findsOneWidget);
    for (final widget in widgets) {
      expect(find.text(widget.label), findsOneWidget);
    }
    expect(find.text('Binary length: 128 bytes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drivers tab bundles only the random temperature sample',
      (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drivers').last);
    await tester.pumpAndSettle();

    expect(find.text('UART / I2C'), findsOneWidget);
    expect(find.text('Random Temperature (Sample)'), findsOneWidget);
    expect(find.text('Flow Meter RS485'), findsNothing);
    expect(find.text('SHT3x Temperature/Humidity'), findsNothing);
  });

  testWidgets('settings expose HaLow channel controls', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Device connection'), findsOneWidget);
    expect(find.text('Device mode'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Mesh Network'),
      300,
      scrollable: findVerticalScrollable(),
    );
    expect(find.text('User'), findsWidgets);
    expect(find.text('Mesh Network'), findsOneWidget);
    expect(find.text('Others'), findsOneWidget);
    await tester.tap(find.text('Mesh Network'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mesh network'),
      300,
      scrollable: findVerticalScrollable(),
    );
    expect(find.text('Bandwidth'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
  });

  testWidgets('settings opens debug as a separate page', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Debug'), findsOneWidget);
    expect(find.text('Debug'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Debug'));
    await tester.pumpAndSettle();

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Speed and loss · last 30 minutes'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to settings'));
    await tester.pumpAndSettle();
    expect(find.text('Device connection'), findsOneWidget);
  });

  testWidgets('connection selector offers BLE and USB devices', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Selected device'), findsOneWidget);
    expect(find.text('No device selected'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Select'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Select BLE or USB device'), findsOneWidget);
    expect(find.text('Scanning for EdgeZ devices'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Device connection'), findsOneWidget);
  });

  testWidgets('conversation shows GPS without overflowing a narrow screen',
      (tester) async {
    int? selectedSpeedHop;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationScreen(
            activeConnection: EdgezConnectionType.ble,
            user: const EdgezMeshNode(
              nodeNum: 0x112233445566,
              userUuid: 'remote-user',
              displayName: 'A remote user with a very long display name',
              route: 'BLE',
              lastSeenMs: 1,
              marker: 'green',
              deviceType: 'User',
            ),
            messages: const <EdgezConversationMessage>[],
            sensorSamples: const <EdgezSensorSample>[
              EdgezSensorSample(
                nodeNum: 0x112233445566,
                timestampMs: 1700000000000,
                data: EdgezSensorData(
                  latitude: 59.329323,
                  longitude: 18.068581,
                ),
              ),
            ],
            linkStats: const EdgezLinkStats(
              bitsPerSecond: 842300,
              packetLossPercent: 1.25,
              receivedPackets: 5394,
              expectedPackets: 5462,
              updatedAtMs: 1700000001000,
            ),
            callState: const EdgezVoiceCallState(),
            defaultTargetLanguage: 'English',
            onBack: () {},
            onSendMessage: (_) async {},
            onStartVoiceMessage: () async => true,
            onStopVoiceMessage: (_) async {},
            onReplayVoiceMessage: (_) {},
            onStartSpeedTest: (hop, _) async => selectedSpeedHop = hop,
            onStartCall: () async {},
          ),
        ),
      ),
    );
    expect(find.text('Hop'), findsOneWidget);
    expect(find.text('0 (Auto)'), findsOneWidget);
    final hopSelector = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(hopSelector);
    await tester.tap(hopSelector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    final speedButton = find.text('Speed test (2 MiB)');
    await tester.ensureVisible(speedButton);
    await tester.tap(speedButton);
    await tester.pumpAndSettle();
    expect(selectedSpeedHop, 2);

    expect(find.text('Location'), findsOneWidget);
    expect(find.textContaining('59.329323, 18.068581'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('conversation-link-stats')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice translation can start before Gemma is installed',
      (tester) async {
    var requested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationBubble(
            message: const EdgezConversationMessage(
              nodeNum: 7,
              text: '',
              mine: false,
              timestampMs: 1,
              voiceBytes: <int>[1, 2, 3],
              voiceCodec: 2,
              durationMs: 500,
            ),
            onReplayVoiceMessage: (_) {},
            canTranslate: false,
            onTranslateVoiceMessage: () => requested = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Install Gemma 4 to translate'));

    expect(requested, isTrue);
  });

  testWidgets('translated voice message exposes TTS replay', (tester) async {
    var requested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationBubble(
            message: const EdgezConversationMessage(
              nodeNum: 7,
              text: '',
              mine: false,
              timestampMs: 1,
              voiceBytes: <int>[1, 2, 3],
              voiceCodec: 2,
              durationMs: 500,
            ),
            onReplayVoiceMessage: (_) {},
            translation: const GemmaVoiceTranslation(
              transcript: 'Hello',
              translation: 'Hola',
              targetLanguage: 'Spanish',
            ),
            onSpeakTranslation: () => requested = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Speak translation'));

    expect(requested, isTrue);
  });

  testWidgets('voice message displays its persisted transcript',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationBubble(
            message: const EdgezConversationMessage(
              nodeNum: 7,
              text: '',
              mine: false,
              timestampMs: 1,
              voiceBytes: <int>[1, 2, 3],
              voiceCodec: 2,
              transcript: '你好，世界。',
              transcriptLanguage: 'Chinese',
            ),
            onReplayVoiceMessage: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Transcript (Chinese): 你好，世界。'), findsOneWidget);
  });

  testWidgets('voice call stays full screen and shows the answered-call timer',
      (tester) async {
    var call = const EdgezVoiceCallState(
      peerNodeNum: 0x112233445566,
      callId: 42,
      phase: EdgezVoiceCallPhase.incoming,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => VoiceCallScreen(
            call: call,
            peer: const EdgezMeshNode(
              nodeNum: 0x112233445566,
              userUuid: 'remote-user',
              displayName: 'Remote user',
              route: 'BLE',
              lastSeenMs: 1,
              marker: 'green',
            ),
            onAnswer: () async {
              setState(() {
                call = const EdgezVoiceCallState(
                  peerNodeNum: 0x112233445566,
                  callId: 42,
                  phase: EdgezVoiceCallPhase.active,
                );
              });
            },
            onEnd: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Incoming voice call'), findsOneWidget);
    expect(find.text('Answer'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call));
    await tester.pump();

    expect(find.text('Answer'), findsNothing);
    expect(find.text('End'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
