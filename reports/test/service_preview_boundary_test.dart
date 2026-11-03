import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a local preview shows the boundary documented in its catalog', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final json = await tester.runAsync(
      () => rootBundle.loadString('assets/service_catalog.json'),
    );
    final catalog = (jsonDecode(json!) as List).cast<Map<String, dynamic>>();
    final flooding = catalog.singleWhere(
      (service) => service['name'] == 'Flooding',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ServicePreviewPage(
          service: flooding,
          draft: const {'id': 'boundary-preview', 'step': 1},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('City Boundary'), findsOneWidget);
    expect(find.text('Service boundary not confirmed'), findsNothing);
    expect(
      find.bySemanticsLabel('Illustrative location pin, not a live map'),
      findsOneWidget,
    );
  });
}
