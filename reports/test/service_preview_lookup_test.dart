import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('resident looks up an exact local preview and returns to history', (
    tester,
  ) async {
    const previews =
        '[{"id":"Local-123","service":"Graffiti Removal","step":5,"description":"Paint on wall","address":"Main Street"},'
        '{"id":"Local-456","service":"Bulky Items","step":5}]';
    const reports = '[{"srNumber":"C-04955177"}]';
    SharedPreferences.setMockInitialValues({
      'service_previews_v1': previews,
      'reports_v2': reports,
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Look up a request'));
    await tester.pumpAndSettle();
    expect(
      find.text('City lookup is not connected in this preview.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Local-12');
    await tester.tap(find.text('Find local preview'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No local preview matches that reference. City lookup is not connected.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'local-123');
    await tester.tap(find.text('Find local preview'));
    await tester.pumpAndSettle();
    expect(find.text('Paint on wall'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('My previews'), findsOneWidget);

    await tester.tap(find.text('Look up a request'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Local-123');
    await tester.tap(find.text('Find local preview'));
    await tester.pumpAndSettle();
    expect(find.text('Paint on wall'), findsOneWidget);
    expect(find.text('This preview was not sent to the City.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bulky');
    await tester.pumpAndSettle();
    expect(find.text('Bulky Items'), findsOneWidget);
    expect(find.text('Graffiti Removal'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('service_previews_v1'), previews);
    expect(prefs.getString('reports_v2'), reports);
  });
}
