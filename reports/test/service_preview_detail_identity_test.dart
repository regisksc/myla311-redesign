import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('saved preview details identify local record and truthful status', (
    tester,
  ) async {
    const previews =
        '[{"id":"Local-Exact-001","service":"Graffiti Removal","step":5},'
        '{"id":"Draft-Exact-002","service":"Bulky Items","step":2,"group":"Bulky Items","evidence":"Local preview"}]';
    const reports = '[{"srNumber":"C-04955177"}]';
    SharedPreferences.setMockInitialValues({
      'service_previews_v1': previews,
      'reports_v2': reports,
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();

    for (final record in [
      ('Graffiti Removal', 'Local-Exact-001', 'Preview complete'),
      ('Bulky Items', 'Draft-Exact-002', 'Draft'),
    ]) {
      await tester.tap(find.text(record.$1));
      await tester.pumpAndSettle();
      expect(find.text('Local record · ${record.$2}'), findsOneWidget);
      expect(find.text(record.$3), findsOneWidget);
      expect(find.text('Local preview'), findsOneWidget);
      expect(find.text('Saved on this device'), findsOneWidget);
      expect(find.text('City status not available'), findsOneWidget);
      expect(
        find.text('This preview was not sent to the City.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'City actions to edit or cancel are not verified. You can manage only the local preview.',
        ),
        findsOneWidget,
      );
      if (record.$3 == 'Draft') {
        expect(find.text('Resume draft'), findsOneWidget);
      } else {
        expect(find.text('Resume draft'), findsNothing);
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('service_previews_v1'), previews);
    expect(prefs.getString('reports_v2'), reports);
  });
}
