import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'a retained confirmed Receipt has its task header and exact number',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final directory = Directory.systemTemp.createTempSync('receipt-header-');
      final original = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _SupportPath(directory.path);
      addTearDown(() {
        PathProviderPlatform.instance = original;
        directory.deleteSync(recursive: true);
      });
      final created = DateTime(2026, 11, 3, 12);
      const contact = ReportContact(anonymous: true);
      const items = [
        ReportItem(
          name: 'Loose/Miscellaneous Debris',
          quantity: '1',
          location: 'Curb',
        ),
      ];
      final draft = ReportDraft(
        createdAt: created,
        description: 'Synthetic retained receipt fixture',
        latitude: 34.053722,
        longitude: -118.242810,
        debrisLocation: 'Curb',
        quantity: '1',
        step: 5,
        flowVersion: 2,
        contact: contact,
        itemFamily: "I'm not sure",
        items: items,
      );
      const store = LocalReportStore();
      await tester.runAsync(() async {
        await store.saveDraft(draft);
        await store.saveReport(
          Report(
            createdAt: created,
            description: draft.description,
            latitude: draft.latitude!,
            longitude: draft.longitude!,
            debrisLocation: draft.debrisLocation,
            quantity: 1,
            contact: contact,
            itemFamily: draft.itemFamily,
            items: items,
            state: ReportState.submitted,
            serviceRequestNumber: 'SR-SYNTHETIC-RECEIPT-HEADER',
          ),
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: ReportsStyle.theme,
          home: ReportFlowPage(store: store, client: _NoSend(), draft: draft),
        ),
      );
      await tester.runAsync(() async {
        for (
          var i = 0;
          i < 100 &&
              find.text('SR-SYNTHETIC-RECEIPT-HEADER').evaluate().isEmpty;
          i++
        ) {
          await Future<void>(() {});
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('SR-SYNTHETIC-RECEIPT-HEADER'), findsOneWidget);
      final header = find.byType(AppBar);
      final title = find.descendant(of: header, matching: find.text('Receipt'));
      expect(title, findsOneWidget);
      expect(DefaultTextStyle.of(tester.element(title)).style.fontSize, 20);
      expect(tester.widget<AppBar>(header).centerTitle, isFalse);
      expect(find.text('New report'), findsNothing);
      expect(find.text('Step 6 of 6 · Review'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Save and close'), findsNothing);
      expect(find.text('Submit'), findsNothing);
      expect(find.text('Report received.'), findsOneWidget);
      expect(find.text('Copy number'), findsOneWidget);
      await tester.ensureVisible(find.text('Back to home'));
      expect(find.text('Back to home').hitTestable(), findsOneWidget);
      final saved = await tester.runAsync(store.loadReports);
      expect(saved!.single.serviceRequestNumber, 'SR-SYNTHETIC-RECEIPT-HEADER');
      expect(saved.single.state, ReportState.submitted);
    },
  );
}

class _NoSend implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('Receipt checks must never send');
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  @override
  Future<String> getApplicationSupportPath() async => path;
}
