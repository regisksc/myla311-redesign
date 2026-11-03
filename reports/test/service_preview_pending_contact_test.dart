import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  testWidgets(
    'pending contact saving advances once and still requires consent',
    (tester) async {
      final store = _PendingContactStore();
      await _openContact(tester, store);
      await tester.tap(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      store.contactWrite.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('One last look.'), findsOneWidget);
      expect(find.text('Local receipt'), findsNothing);
      expect(store.contactWrites, 1);
      await tester.tap(find.text('Create local receipt'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Please confirm that this creates a local demo receipt only.',
        ),
        findsOneWidget,
      );
      expect(find.text('Local receipt'), findsNothing);
    },
  );

  testWidgets('pending contact saving blocks Back, close and form changes', (
    tester,
  ) async {
    final store = _PendingContactStore();
    await _openContact(tester, store);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Back'), warnIfMissed: false);
    await tester.tap(find.text('Save and close'), warnIfMissed: false);
    await tester.tap(
      find.text('Remember contact on this device'),
      warnIfMissed: false,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('How should we reach you?'), findsOneWidget);
    expect(find.text('Open preview'), findsNothing);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(
              CheckboxListTile,
              'Remember contact on this device',
            ),
          )
          .value,
      isTrue,
    );
    store.contactWrite.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('One last look.'), findsOneWidget);
    expect(store.contactWrites, 1);
  });

  testWidgets(
    'Continue then Back in the same frame still reaches Review once',
    (tester) async {
      final store = _PendingContactStore();
      await _openContact(tester, store);
      await tester.tap(find.text('Continue'));
      await tester.tap(find.byTooltip('Back'));
      store.contactWrite.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('One last look.'), findsOneWidget);
      expect(store.contactWrites, 1);
    },
  );

  testWidgets('Continue then close in the same frame keeps Review open', (
    tester,
  ) async {
    final store = _PendingContactStore();
    await _openContact(tester, store);
    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Save and close'));
    store.contactWrite.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('One last look.'), findsOneWidget);
    expect(find.text('Open preview'), findsNothing);
    expect(store.contactWrites, 1);
  });

  testWidgets('queued contact choice cannot change the validated contact', (
    tester,
  ) async {
    final store = _PendingContactStore();
    await _openContact(tester, store);
    await tester.ensureVisible(find.text('Anonymous'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Anonymous'));
    store.contactWrite.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('One last look.'), findsOneWidget);
    expect(find.text('Ada Lovelace · ada@example.com'), findsOneWidget);
    expect(store.contactWrites, 1);
  });

  testWidgets('queued contact text cannot replace the validated email', (
    tester,
  ) async {
    final store = _PendingContactStore();
    await _openContact(tester, store);
    final email = find.widgetWithText(TextFormField, 'Email');
    await tester.ensureVisible(email);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.enterText(email, 'changed@example.com');
    store.contactWrite.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('One last look.'), findsOneWidget);
    expect(find.text('Ada Lovelace · ada@example.com'), findsOneWidget);
    expect(store.contactWrites, 1);
  });

  testWidgets(
    'failed contact saving retains the visible validated email after a queued edit',
    (tester) async {
      final store = _PendingContactStore();
      await _openContact(tester, store);
      final email = find.widgetWithText(TextFormField, 'Email');
      await tester.ensureVisible(email);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.enterText(email, 'changed@example.com');
      store.contactWrite.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('How should we reach you?'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('changed@example.com'), findsNothing);
    },
  );

  for (final label in [
    'Preview email updates',
    'Remember contact on this device',
  ]) {
    testWidgets('queued $label cannot change during contact saving', (
      tester,
    ) async {
      final store = _PendingContactStore();
      await _openContact(tester, store);
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.tap(find.text(label));
      store.contactWrite.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('One last look.'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, label),
            )
            .value,
        isTrue,
      );
      expect(store.contactWrites, 1);
    });
  }

  testWidgets('contact write failure permits retry without skipping Review', (
    tester,
  ) async {
    final store = _PendingContactStore();
    await _openContact(tester, store);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    store.contactWrite.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('How should we reach you?'), findsOneWidget);
    expect(
      find.text('Contact could not be saved on this device.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNotNull,
    );
    store.contactWrite = Completer<bool>();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    store.contactWrite.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('One last look.'), findsOneWidget);
    expect(find.text('Local receipt'), findsNothing);
    expect(store.contactWrites, 2);
  });
}

Future<void> _openContact(
  WidgetTester tester,
  _PendingContactStore store,
) async {
  SharedPreferencesStorePlatform.instance = store;
  SharedPreferences.resetStatic();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ServicePreviewPage(
                  service: {
                    'name': 'Graffiti Removal',
                    'group': 'Graffiti',
                    'evidence': 'anonymous available; optional attachments',
                  },
                  draft: {
                    'id': 'pending-contact',
                    'step': 3,
                    'description': 'Wall',
                    'address': 'Main Street',
                    'confirmed': true,
                    'named': true,
                    'firstName': 'Ada',
                    'lastName': 'Lovelace',
                    'email': 'ada@example.com',
                    'photos': 0,
                  },
                ),
              ),
            ),
            child: const Text('Open preview'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open preview'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Remember contact on this device'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Remember contact on this device'));
  await tester.pumpAndSettle();
}

class _PendingContactStore extends InMemorySharedPreferencesStore {
  _PendingContactStore() : super.empty();

  var contactWrite = Completer<bool>();
  int contactWrites = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.reports_saved_contact_v1') {
      contactWrites++;
      if (!await contactWrite.future) return false;
    }
    return super.setValue(valueType, key, value);
  }
}
