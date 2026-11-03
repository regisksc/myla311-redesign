import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/native_app_test_support.dart';

void main() {
  testWidgets('a new dumping report replaces a saved Draft only with consent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = _DraftStore();
    store.draft = ReportDraft(
      createdAt: DateTime(2026, 10, 1),
      description: 'Keep this unfinished report',
      latitude: 34.05,
      longitude: -118.24,
      step: 3,
      flowVersion: 2,
    );
    store.reports.add(
      Report(
        description: 'Retained City receipt',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 9, 1),
        state: ReportState.submitted,
        serviceRequestNumber: 'C-04955177',
      ),
    );
    final savedDraft = store.draft!.toJson();
    final savedReceipt = store.reports.single.toJson();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: store),
    );
    await tester.pumpAndSettle();
    await _startDumping(tester);
    expect(find.text('Start a new report?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportFlowPage), findsNothing);
    expect(store.draft!.toJson(), savedDraft);

    store.failRead = true;
    await _startDumping(tester);
    expect(
      find.text(
        'Could not check your unfinished draft. Try again before starting a new report.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ReportFlowPage), findsNothing);
    expect(store.draft!.toJson(), savedDraft);

    await tester.drag(find.byType(SnackBar), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    store.failRead = false;
    await _startDumping(tester);
    await tester.tap(find.text('Start new report'));
    await tester.pumpAndSettle();
    expect(find.text('Where did you spot it?'), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('Use map center')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use map center'));
    await tester.pumpAndSettle();
    expect(store.draft!.createdAt, isNot(DateTime(2026, 10, 1)));
    expect(store.reports.single.toJson(), savedReceipt);
  });
}

Future<void> _startDumping(WidgetTester tester) async {
  final start = find.text('Start a report');
  await tester.ensureVisible(start);
  await tester.pumpAndSettle();
  await tester.tap(start);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'Search services'),
    'Illegal Dumping',
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Illegal Dumping Item Pickup'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Start report'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start report'));
  await tester.pumpAndSettle();
}

class _DraftStore extends MemoryReportStore {
  bool failRead = false;

  @override
  Future<ReportDraft?> loadDraft() async {
    if (failRead) throw StateError('Draft storage is unavailable');
    return draft;
  }
}
