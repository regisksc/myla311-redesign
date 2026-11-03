import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/services/service_catalog_page.dart';

void main() {
  for (final width in [390.0, 375.0]) {
    testWidgets('catalog rows retain reference reading space at width $width', (
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
            onIllegalDumping: () {},
            loadCatalog: () async => [
              for (var index = 0; index < 5; index++)
                {'name': 'Service $index', 'group': 'Animals'},
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final group = find.text('Animals');
      final button = find.ancestor(
        of: group,
        matching: find.byType(OutlinedButton),
      );
      final row = tester.getRect(button);
      final title = tester.getRect(group);
      final count = tester.getRect(find.text('5 services'));
      // Canonical computed CSS includes 20px padding inside a 2px border.
      expect(row.width, width - 40);
      expect(row.height, closeTo(92.5, 0.5));
      expect(title.left - row.left, closeTo(22, 0.5));
      expect(title.height, closeTo(24, 0.5));
      expect(count.height, closeTo(19.5, 0.5));
      expect(count.top - title.bottom, closeTo(5, 0.5));

      await tester.tap(group);
      await tester.pumpAndSettle();
      final service = find.text('Service 0');
      final serviceButton = find.ancestor(
        of: service,
        matching: find.byType(OutlinedButton),
      );
      expect(tester.getSize(serviceButton).height, closeTo(68, 0.5));
      expect(
        tester.getRect(service).left - tester.getRect(serviceButton).left,
        closeTo(22, 0.5),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
