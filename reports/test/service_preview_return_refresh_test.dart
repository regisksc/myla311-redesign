import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'returning from preview editing refreshes details before changing follow',
    (tester) async {
      final savedReports = jsonEncode([
        Report(
          description: 'Keep this accepted report',
          latitude: 34.0522,
          longitude: -118.2437,
          createdAt: DateTime(2026, 11, 2),
          state: ReportState.submitted,
          serviceRequestNumber: 'C-04955177',
        ).toJson(),
      ]);
      SharedPreferences.setMockInitialValues({
        'reports_v2': savedReports,
        'service_previews_v1': jsonEncode([
          {
            'id': 'edited-draft',
            'service': 'Graffiti Removal',
            'group': 'Graffiti',
            'evidence': 'anonymous available; optional attachments',
            'step': 0,
            'description': 'Original description',
            'following': true,
          },
        ]),
      });
      await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Graffiti Removal'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Resume draft'));
      await tester.tap(find.text('Resume draft'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'What needs attention?'),
        'Edited description',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and close'));
      await tester.pumpAndSettle();

      expect(find.text('Edited description'), findsOneWidget);
      expect(find.text('Original description'), findsNothing);
      await tester.ensureVisible(find.text('Unfollow locally'));
      await tester.tap(find.text('Unfollow locally'));
      await tester.pumpAndSettle();
      expect(find.text('Follow locally'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final previews =
          jsonDecode(prefs.getString('service_previews_v1')!) as List;
      expect(previews.single['description'], 'Edited description');
      expect(previews.single['following'], isFalse);
      expect(prefs.getString('reports_v2'), savedReports);
    },
  );
}
