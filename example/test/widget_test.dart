import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:edgez_flutter_sdk_example/src/conversation_screen.dart';
import 'package:edgez_flutter_sdk_example/src/dashboard_tab.dart';
import 'package:edgez_flutter_sdk_example/src/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:edgez_flutter_sdk_example/src/app.dart';
import 'package:edgez_flutter_sdk_example/src/provisioning_screen.dart';

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

    expect(find.text('BLE connection'), findsOneWidget);
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
    expect(find.text('SDK events'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to settings'));
    await tester.pumpAndSettle();
    expect(find.text('BLE connection'), findsOneWidget);
  });

  testWidgets('BLE connection uses the Android-style device picker',
      (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Selected device'), findsOneWidget);
    expect(find.text('No BLE device selected'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Select'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Select BLE device'), findsOneWidget);
    expect(find.text('Scanning for EdgeZ devices'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('BLE connection'), findsOneWidget);
  });

  testWidgets('conversation shows GPS without overflowing a narrow screen',
      (tester) async {
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
            callState: const EdgezVoiceCallState(),
            onBack: () {},
            onSendMessage: (_) {},
            onStartVoiceMessage: () async => true,
            onStopVoiceMessage: (_) async {},
            onReplayVoiceMessage: (_) {},
            onStartCall: () async {},
            onAcceptCall: () async {},
            onEndCall: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Latest sensor location'), findsOneWidget);
    expect(find.text('59.329323, 18.068581'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
