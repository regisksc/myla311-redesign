import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/services/service_catalog_page.dart';

void main() {
  for (final width in [390.0, 375.0]) {
    testWidgets('catalog content keeps reference spacing at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, width == 390 ? 844 : 812);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      rootBundle.evict('assets/service_catalog.json');
      await tester.pumpWidget(
        MaterialApp(
          theme: ReportsStyle.theme,
          home: ServiceCatalogPage(
            onStartReport: (_) {},
            loadCatalog: () async => [
              {'name': 'Service', 'group': 'Animals'},
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heading = find.descendant(
        of: find.byType(ListView),
        matching: find.text('Services'),
      );
      final intro = find.text(
        'Find the right place to start. Browse by category or search by name.',
      );
      final search = find.byType(TextField);
      final group = find.text('Animals');
      final groupButton = find.ancestor(
        of: group,
        matching: find.byType(OutlinedButton),
      );
      expect(tester.getRect(heading).height, closeTo(36, 0.5));
      expect(tester.widget<Text>(heading).style?.letterSpacing, -1.05);
      expect(
        tester.getRect(intro).top - tester.getRect(heading).bottom,
        closeTo(16, 0.5),
      );
      expect(
        tester.getRect(search).top - tester.getRect(intro).bottom,
        closeTo(24, 0.5),
      );
      expect(tester.getRect(search).height, closeTo(60, 0.5));
      expect(
        tester.getRect(groupButton).top - tester.getRect(search).bottom,
        closeTo(24, 0.5),
      );
      await tester.tap(group);
      await tester.pumpAndSettle();
      final category = find.text('Animals');
      final categoryIntro = find.text(
        'Choose the service that best matches your concern.',
      );
      expect(tester.widget<Text>(category).style?.letterSpacing, -1.05);
      final service = find.ancestor(
        of: find.text('Service'),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.getRect(find.text('All services')).left, closeTo(20, 0.5));
      expect(
        tester.getRect(categoryIntro).top - tester.getRect(category).bottom,
        closeTo(16, 0.5),
      );
      expect(
        tester.getRect(service).top - tester.getRect(categoryIntro).bottom,
        closeTo(24, 0.5),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
