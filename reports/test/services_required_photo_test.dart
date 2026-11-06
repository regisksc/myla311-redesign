import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';

void main() {
  testWidgets('shows the known photo requirement at the evidence step', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Flooding',
            'group': 'Other',
            'evidence':
                'anonymous available; required attachments; advertised limit 5',
          },
          draft: {'id': 'required-photo', 'step': 2},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Photos are required for this service.'), findsOneWidget);
  });
}
