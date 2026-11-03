import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('keyboard Done finds the exact local preview', (tester) async {
    const previews =
        '[{"id":"Local-123","service":"Graffiti Removal","step":5,"description":"Saved wall report"}]';
    SharedPreferences.setMockInitialValues({'service_previews_v1': previews});
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look up a request'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Local-123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Saved wall report'), findsOneWidget);
    expect(find.text('Local record · Local-123'), findsOneWidget);
    expect(find.text('City status not available'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('service_previews_v1'),
      previews,
    );
  });
}
