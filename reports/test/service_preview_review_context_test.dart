import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('review identifies the selected service at both mobile widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(375, 812), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(size),
          theme: ReportsStyle.theme,
          home: const ServicePreviewPage(
            service: {
              'name': 'Flooding',
              'group': 'Street Problems/Repairs',
              'evidence': 'anonymous available; optional attachments',
            },
            draft: {
              'id': 'review-service',
              'step': 4,
              'description': 'Water beside the curb',
              'address': '200 N Spring St',
              'confirmed': true,
              'named': false,
              'photos': 1,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('Service')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('Flooding')),
        findsOneWidget,
      );
      expect(find.text('Water beside the curb'), findsOneWidget);
      expect(find.text('200 N Spring St'), findsOneWidget);
      expect(find.text('1 sample evidence'), findsOneWidget);
      expect(find.text('Anonymous'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('contact and review retain their approved decision headings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    for (final entry in {
      3: 'How should we reach you?',
      4: 'One last look.',
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(entry.key),
          theme: ReportsStyle.theme,
          home: ServicePreviewPage(
            service: const {
              'name': 'Flooding',
              'group': 'Streets',
              'evidence': 'anonymous available',
            },
            draft: {'id': 'heading', 'step': entry.key, 'named': false},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });
}
