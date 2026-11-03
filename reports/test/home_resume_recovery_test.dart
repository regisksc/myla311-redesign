import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/native_app_test_support.dart';

void main() {
  testWidgets('Home retries saved-state loading and restores draft resume', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final draft = ReportDraft(
      createdAt: DateTime(2026, 11, 3),
      step: 2,
      description: 'Mattress beside the curb',
      latitude: 34.0522,
      longitude: -118.2437,
    );
    final receipt = Report(
      createdAt: DateTime(2026, 11, 2),
      description: 'Previously accepted report',
      latitude: 34.0522,
      longitude: -118.2437,
      state: ReportState.submitted,
      serviceRequestNumber: 'C-04955177',
    );
    final store = _FlakyStore()
      ..draft = draft
      ..reports.add(receipt);
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: store),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved reports could not be loaded.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const Key('home-resume-card')), findsNothing);
    expect(store.draft?.toJson(), draft.toJson());
    expect(store.reports.single.toJson(), receipt.toJson());

    store.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Saved reports could not be loaded.'), findsNothing);
    final card = find.byKey(const Key('home-resume-card'));
    expect(card, findsOneWidget);
    expect(find.text('Mattress beside the curb · Step 3 of 6'), findsOneWidget);
    await tester.tap(
      find.descendant(of: card, matching: find.text('Continue')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReportFlowPage), findsOneWidget);
    expect(find.text('Step 3 of 6 · Photos'), findsOneWidget);
    expect(store.draft?.toJson(), draft.toJson());
    expect(store.reports.single.toJson(), receipt.toJson());
    expect(tester.takeException(), isNull);
  });
}

class _FlakyStore extends MemoryReportStore {
  bool failRead = true;

  @override
  Future<List<Report>> loadReports() async {
    if (failRead) throw StateError('Saved reports unavailable');
    return super.loadReports();
  }
}
