import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('SmartKeyboard example app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartKeyboardExampleApp());

    expect(find.text('SmartKeyboard Demo'), findsOneWidget);
    expect(find.text('Keyboard Status'), findsOneWidget);
    expect(find.text('Tap to show keyboard'), findsOneWidget);
  });
}
