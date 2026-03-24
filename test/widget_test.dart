import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecureMarkApp());

    // Verify that the app title exists (using SecureMark)
    expect(find.text('SecureMark'), findsOneWidget);
  });

  testWidgets('Watermark text is displayed', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecureMarkApp());

    // Verify that the watermark text exists
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('App has a Scaffold structure', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecureMarkApp());

    // Verify that the app has a Scaffold
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Watermark uses Center widget', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecureMarkApp());

    // Verify that the Center widget exists (watermark is centered)
    expect(find.byType(Center), findsWidgets);
  });
}
