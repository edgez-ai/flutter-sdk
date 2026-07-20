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
}
