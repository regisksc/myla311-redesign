import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('unmatched preview search explains results and can be cleared', (
    tester,
  ) async {
    const previews =
        '[{"id":"Local-123","service":"Graffiti Removal","step":5},'
        '{"id":"Local-456","service":"Bulky Items","step":5}]';
    const reports = '[{"srNumber":"C-04955177"}]';
    SharedPreferences.setMockInitialValues({
      'service_previews_v1': previews,
      'reports_v2': reports,
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'no matching service');
    await tester.pumpAndSettle();
    expect(find.text('No local previews match your search.'), findsOneWidget);
    expect(find.text('No local previews yet'), findsNothing);
    expect(find.text('Graffiti Removal'), findsNothing);
    expect(find.text('Bulky Items'), findsNothing);
    expect(find.text('Look up a request'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('No local previews match your search.'), findsNothing);
    expect(find.text('Graffiti Removal'), findsOneWidget);
    expect(find.text('Bulky Items'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('service_previews_v1'), previews);
    expect(prefs.getString('reports_v2'), reports);
  });
}
