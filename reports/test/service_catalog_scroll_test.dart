import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_catalog_page.dart';

void main() {
  testWidgets('a scrolled service category opens at its heading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceCatalogPage(
          onIllegalDumping: () {},
          loadCatalog: () async => [
            for (var index = 0; index < 23; index++)
              {'name': 'Service $index', 'group': 'Category $index'},
            for (var index = 0; index < 24; index++)
              {'name': 'Target service $index', 'group': 'Category 23'},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Category 23'),
      400,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.tap(find.text('Category 23'));
    await tester.pumpAndSettle();
    expect(find.text('All services').hitTestable(), findsOneWidget);
    expect(find.text('Category 23').hitTestable(), findsOneWidget);
    expect(find.text('Target service 0').hitTestable(), findsOneWidget);
  });
}
