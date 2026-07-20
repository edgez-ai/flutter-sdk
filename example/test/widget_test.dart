import 'package:flutter_test/flutter_test.dart';
import 'package:edgez_flutter_sdk_example/src/app.dart';

void main() {
  testWidgets('example app shows nodes tab', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());

    expect(find.text('Nodes'), findsWidgets);
    expect(find.text('Mesh topology'), findsOneWidget);
    expect(find.textContaining('No beacon or discovery packets received yet'),
        findsOneWidget);
  });

  testWidgets('settings expose HaLow channel controls', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('User mesh settings'), findsOneWidget);
    expect(find.text('Bandwidth'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
  });
}
