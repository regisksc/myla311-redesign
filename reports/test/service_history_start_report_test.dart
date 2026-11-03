import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/services/service_catalog_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/native_app_test_support.dart';

void main() {
  testWidgets(
    'other-service history starts a report through the native catalog',
    (tester) async {
      const previews =
          '[{"id":"kept-preview","service":"Graffiti Removal","step":5}]';
      SharedPreferences.setMockInitialValues({'service_previews_v1': previews});
      final receipt = Report(
        description: 'Keep this accepted report',
        latitude: 34.0522,
        longitude: -118.2437,
        createdAt: DateTime(2026, 11, 2),
        state: ReportState.submitted,
        serviceRequestNumber: 'C-04955177',
      );
      final store = MemoryReportStore()..reports.add(receipt);
      await tester.pumpWidget(
        ReportApp(client: NoSubmissionClient(), store: store),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View saved reports'));
      await tester.tap(find.text('View saved reports'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('View other service reports'),
        250,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View other service reports'));
      await tester.pumpAndSettle();
      expect(find.text('Start a report'), findsOneWidget);
      await tester.tap(find.text('Start a report'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceCatalogPage), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Illegal Dumping Item Pickup',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Illegal Dumping Item Pickup'),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start report'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportFlowPage), findsOneWidget);
      await tester.tap(find.text('Save and close'));
      await tester.pumpAndSettle();
      expect(store.draft, isNotNull);
      expect(store.reports.single.toJson(), receipt.toJson());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('service_previews_v1'), previews);
    },
  );
}
