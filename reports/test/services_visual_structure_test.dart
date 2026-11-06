import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('service entry opens its existing six-step journey', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Graffiti Removal',
            'group': 'Graffiti',
            'evidence': 'anonymous available; optional attachments',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Before you start'), findsNothing);
    await tester.tap(find.text('Start report'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 6 · Details'), findsOneWidget);
    expect(find.bySemanticsLabel('Report progress'), findsOneWidget);
  });
  testWidgets('history shows the lookup ID on the preview card', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1':
          '[{"id":"local-1","service":"Graffiti Removal","step":5}]',
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('local-1'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });
}
