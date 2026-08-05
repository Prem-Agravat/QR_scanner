import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrcode_generator/main.dart';

import 'package:qrcode_generator/services/storage_service.dart';

void main() {
  testWidgets('Dashboard smoke test and navigation test', (
    WidgetTester tester,
  ) async {
    StorageService.mockRecords = [];
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QRApp());

    // Verify that the title "QR Hub" is present on the home page.
    expect(find.text('QR Hub'), findsOneWidget);

    // Verify that the navigation buttons are present.
    expect(find.text('Scan QR Code'), findsOneWidget);
    expect(find.text('Generate QR Code'), findsOneWidget);
    expect(find.text('Saved History'), findsOneWidget);

    // Test Navigation to Generate QR Code screen
    await tester.tap(find.text('Generate QR Code'));
    await tester.pumpAndSettle();
    expect(find.text('Generator'), findsOneWidget);

    // Back to Dashboard
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // Test Navigation to Saved History screen
    await tester.tap(find.text('Saved History'));
    await tester.pumpAndSettle();
    expect(find.text('Saved History'), findsOneWidget);
  });
}
