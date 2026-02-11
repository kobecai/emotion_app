// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:emotion_app/ui/app.dart';

void main() {
  testWidgets('LetGo app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LetGoApp());

    // Verify that the home screen renders the title.
    expect(find.text('LET GO'), findsOneWidget);
  });
}
