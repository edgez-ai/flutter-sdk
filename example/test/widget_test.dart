import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:edgez_flutter_sdk_example/src/conversation_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:edgez_flutter_sdk_example/src/app.dart';

Finder findVerticalScrollable() => find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    );

void main() {
  testWidgets('example app shows nodes tab', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());

    expect(find.text('Nodes'), findsWidgets);
    expect(find.text('Topology'), findsOneWidget);
    expect(find.textContaining('No beacon or discovery packets received yet'),
        findsOneWidget);
  });

  testWidgets('nodes opens topology as a separate page', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());

    await tester.tap(find.text('Topology'));
    await tester.pumpAndSettle();
    expect(find.text('Mesh topology'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Nodes'), findsWidgets);
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
