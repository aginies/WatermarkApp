import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecureMarkApp());

    // Verify that the app title exists (using SecureMark)
    expect(find.text('SecureMark'), findsAtLeast(1));
  });
}
