import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_catalog_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates a local preview receipt', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: ServiceCatalogPage(onIllegalDumping: () {})),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Graffiti Removal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal').last);
    await tester.pumpAndSettle();
    expect(find.text('Graffiti Removal'), findsWidgets);
    await tester.tap(find.text('Start report'));
    await tester.pumpAndSettle();
    expect(find.text('Example questions'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Graffiti on wall');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Place it on the map.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Main Street');
    await tester.ensureVisible(find.text('Confirm sample pin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm sample pin'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('A little more context.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How should we reach you?'), findsOneWidget);
    await tester.tap(find.text('Anonymous'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('One last look.'), findsOneWidget);
    final consent = find.text(
      'I understand this creates a local demo receipt. Nothing is sent to the City.',
    );
    await tester.scrollUntilVisible(
      consent,
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(consent);
    await tester.tap(find.text('Create local receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Local receipt'), findsOneWidget);
    expect(find.textContaining('not sent'), findsWidgets);
  });
}
