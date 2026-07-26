import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intelliq/main.dart';

void main() {
  testWidgets('IntelliQ smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IntelliQApp());

    // Verify that the title logo is displayed.
    expect(find.byIcon(Icons.query_stats), findsOneWidget);
  });
}
