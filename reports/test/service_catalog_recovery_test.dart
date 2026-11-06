import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/services/service_catalog_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('resident retries a failed catalog read without losing Reports', (
    tester,
  ) async {
    final savedReport = jsonEncode(
      Report(
        description: 'Saved dumping Report',
        latitude: 34.05,
        longitude: -118.25,
        createdAt: DateTime(2026, 11, 1),
        state: ReportState.submitted,
        serviceRequestNumber: 'C-04955177',
      ).toJson(),
    );
    SharedPreferences.setMockInitialValues({
      'reports_v2': [savedReport],
    });
    final initialRead = Completer<List<Map<String, dynamic>>>();
    final retryRead = Completer<List<Map<String, dynamic>>>();
    var nextRead = initialRead.future;
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceCatalogPage(
          onStartReport: (_) {},
          loadCatalog: () => nextRead,
        ),
      ),
    );
    await tester.pumpAndSettle();
    initialRead.completeError(StateError('City read unavailable'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load services. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('No services found'), findsNothing);

    nextRead = retryRead.future;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Loading services…'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    retryRead.complete([
      {'name': 'Illegal Dumping Item Pickup', 'group': 'Public Rights of Way'},
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Loading services…'), findsNothing);
    expect(
      find.text('Could not load services. Please try again.'),
      findsNothing,
    );
    await tester.tap(find.text('Public Rights of Way'));
    await tester.pumpAndSettle();
    expect(find.text('Illegal Dumping Item Pickup'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getStringList('reports_v2'),
      [savedReport],
    );
  });
}
