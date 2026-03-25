import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/main.dart';

void main() {
  testWidgets('App has a Scaffold structure', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureMarkApp());
    // No need for pumpAndSettle; scaffold should appear immediately
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Watermark uses Center widget', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureMarkApp());
    expect(find.byType(Center), findsOneWidget);
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureMarkApp());
    expect(find.byType(SecureMarkApp), findsOneWidget);
  });
}
