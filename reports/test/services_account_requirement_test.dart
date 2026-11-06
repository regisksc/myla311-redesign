import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';

void main() {
  testWidgets('account-required service keeps its existing sign-in route', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Containers',
            'group': 'Refuse',
            'evidence': 'account required; attachments unknown',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Before you start'), findsNothing);
    expect(
      find.text('No account is needed to explore this report.'),
      findsNothing,
    );
    expect(find.text('Start preview'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });
}
