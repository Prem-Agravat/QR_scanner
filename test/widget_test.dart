import 'package:flutter_test/flutter_test.dart';
import 'package:qrcode_generator/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QRApp());

    // Verify that the title "QR Hub" is present on the home page.
    expect(find.text('QR Hub'), findsOneWidget);
    
    // Verify that the navigation buttons "Scan QR Code" and "Generate QR Code" are present.
    expect(find.text('Scan QR Code'), findsOneWidget);
    expect(find.text('Generate QR Code'), findsOneWidget);
  });
}
