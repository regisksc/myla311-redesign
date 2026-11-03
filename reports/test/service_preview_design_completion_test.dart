import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const service = {
  'name': 'Flooding',
  'group': 'Streets',
  'evidence': 'anonymous available; optional attachments',
  'boundary': 'City of Los Angeles',
};

Future<void> openPreview(
  WidgetTester tester, {
  int step = 0,
  Map<String, dynamic> answers = const {},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ServicePreviewPage(
        service: service,
        draft: {
          'id': 'design-preview',
          'step': step,
          'description': 'Water in the street',
          'address': 'Main Street',
          'confirmed': true,
          'named': false,
          ...answers,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    150,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Flooding extra detail is conditional, required and restored', (
    tester,
  ) async {
    await openPreview(tester);
    expect(find.text('Where is water collecting?'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Extra detail'), findsNothing);
    await reveal(tester, 'Add a useful extra detail');
    await tester.tap(find.text('Add a useful extra detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await reveal(tester, 'Add the extra detail you selected.');
    expect(find.byKey(const Key('preview-section-0')), findsOneWidget);
    await reveal(tester, 'Extra detail');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Extra detail'),
      'Water reaches the curb',
    );
    await tester.pumpAndSettle();
    final saved = (await const ServicePreviewStore().load()).single;
    expect(saved['extra'], isTrue);
    expect(saved['extraDetail'], 'Water reaches the curb');
    await tester.pumpWidget(const SizedBox());
    await openPreview(tester, answers: saved);
    await reveal(tester, 'Extra detail');
    expect(find.text('Water reaches the curb'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-section-1')), findsOneWidget);
  });

  testWidgets('location shows its boundary and restores an optional landmark', (
    tester,
  ) async {
    await openPreview(tester, step: 1);
    expect(find.text('City of Los Angeles'), findsOneWidget);
    await reveal(tester, 'Nearby landmark (optional)');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nearby landmark (optional)'),
      'Beside the library',
    );
    await tester.pumpAndSettle();
    final saved = (await const ServicePreviewStore().load()).single;
    expect(saved['reference'], 'Beside the library');
    expect(saved['boundary'], 'City of Los Angeles');
    await tester.pumpWidget(const SizedBox());
    await openPreview(tester, answers: saved);
    await reveal(tester, 'Nearby landmark (optional)');
    expect(find.text('Beside the library'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await openPreview(tester, step: 4, answers: saved..['step'] = 4);
    expect(find.text('Beside the library'), findsOneWidget);
  });

  testWidgets('named preview updates persist alongside remembered contact', (
    tester,
  ) async {
    await openPreview(
      tester,
      step: 3,
      answers: {
        'named': true,
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
      },
    );
    await reveal(tester, 'Preview email updates');
    final updates = find.widgetWithText(
      CheckboxListTile,
      'Preview email updates',
    );
    expect(tester.widget<CheckboxListTile>(updates).value, isTrue);
    await tester.tap(updates);
    await tester.pumpAndSettle();
    await reveal(tester, 'Remember contact on this device');
    await tester.tap(find.text('Remember contact on this device'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final saved = (await const ServicePreviewStore().load()).single;
    expect(saved['updates'], isFalse);
    expect(saved['firstName'], 'Ada');
    expect(saved['lastName'], 'Lovelace');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reports_saved_contact_v1'), contains('Lovelace'));
    await tester.pumpWidget(const SizedBox());
    await openPreview(tester, answers: {...saved, 'step': 3});
    await reveal(tester, 'Preview email updates');
    expect(tester.widget<CheckboxListTile>(updates).value, isFalse);
  });

  testWidgets('local receipt requires consent again after answers change', (
    tester,
  ) async {
    const consent =
        'I understand this creates a local demo receipt. Nothing is sent to the City.';
    const existingReports = '[{"serviceRequestNumber":"C-04955177"}]';
    SharedPreferences.setMockInitialValues({'reports_v2': existingReports});
    await openPreview(
      tester,
      step: 4,
      answers: {
        'named': true,
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
      },
    );
    await tester.tap(find.text('Create local receipt'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-section-4')), findsOneWidget);
    await reveal(
      tester,
      'Please confirm that this creates a local demo receipt only.',
    );
    await reveal(tester, consent);
    await tester.tap(find.text(consent));
    await tester.pumpAndSettle();
    expect(
      (await const ServicePreviewStore().load()).single['reviewConsent'],
      isTrue,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await reveal(tester, 'Phone (optional)');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone (optional)'),
      '2135550100',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await reveal(tester, consent);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, consent),
          )
          .value,
      isFalse,
    );
    await tester.tap(find.text(consent));
    await tester.tap(find.text('Create local receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Local receipt'), findsOneWidget);
    final saved = (await const ServicePreviewStore().load()).single;
    expect(saved['step'], 5);
    expect(saved['phone'], '2135550100');
    expect(saved['reviewConsent'], isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reports_v2'), existingReports);
  });
}
