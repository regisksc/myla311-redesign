import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'editing a followed preview retains its local follow preference',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'service_previews_v1': jsonEncode([
          {
            'id': 'followed-draft',
            'service': 'Graffiti Removal',
            'group': 'Graffiti',
            'evidence': 'anonymous available; optional attachments',
            'step': 0,
            'description': 'Existing description',
            'following': true,
          },
        ]),
      });
      await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Graffiti Removal'));
      await tester.pumpAndSettle();
      expect(find.text('Unfollow locally'), findsOneWidget);
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
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Graffiti Removal'));
      await tester.pumpAndSettle();
      expect(find.text('Edited description'), findsOneWidget);
      expect(find.text('Unfollow locally'), findsOneWidget);
    },
  );
}
