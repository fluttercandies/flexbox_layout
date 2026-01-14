// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('App navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlexboxExampleApp());

    // Verify that home page loads
    expect(find.text('Flexbox Examples'), findsOneWidget);

    // Verify that navigation items exist
    expect(find.text('Basic Flexbox'), findsOneWidget);
    expect(find.text('Animated Flexbox'), findsOneWidget);
    expect(find.text('Cat Gallery'), findsOneWidget);
    expect(find.text('Sliver Flexbox'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
  });
}
