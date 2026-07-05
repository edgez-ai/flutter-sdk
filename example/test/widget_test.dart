import 'package:flutter_test/flutter_test.dart';
import 'package:edgez_flutter_sdk_example/main.dart';

void main() {
  testWidgets('example app shows nodes tab', (tester) async {
    await tester.pumpWidget(const EdgezExampleApp());

    expect(find.text('Nodes'), findsWidgets);
    expect(find.text('No HaLow users seen yet'), findsOneWidget);
  });
}
