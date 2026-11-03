import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/native_app_test_support.dart';

void main() {
  testWidgets('material family cards retain the canonical 100px minimum', (
    tester,
  ) async {
    for (final width in [375.0, 390.0]) {
      await _openStep(tester, width, 1);
      final family = find.ancestor(
        of: find.text('Bulky Items'),
        matching: find.byType(OutlinedButton),
      );
      expect(
        tester.getSize(family).height,
        greaterThanOrEqualTo(100),
        reason: 'family at $width',
      );
      await tester.tap(find.text('Bulky Items'));
      await tester.pumpAndSettle();
      expect(find.text('Mattress'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('optional details provide seven visible text rows', (
    tester,
  ) async {
    for (final width in [375.0, 390.0]) {
      await _openStep(tester, width, 3);
      final field = find.byKey(const Key('report-description'));
      final editor = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      expect(
        tester.getSize(editor).height,
        greaterThanOrEqualTo(168),
        reason: 'seven24px rows at $width',
      );
      expect(tester.getSize(field).height, greaterThanOrEqualTo(198));
      expect(find.text('Describe the dumped items (optional)'), findsOneWidget);
      await tester.enterText(field, 'Synthetic access note beside the curb');
      expect(
        tester.widget<TextField>(field).controller!.text,
        'Synthetic access note beside the curb',
      );
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _openStep(WidgetTester tester, double width, int step) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(
    () => rootBundle.loadString('assets/illegal_dumping_items.json'),
  );
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('$width-$step'),
      theme: ReportsStyle.theme,
      home: ReportFlowPage(
        store: MemoryReportStore(),
        client: NoSubmissionClient(),
        draft: ReportDraft(
          createdAt: DateTime(2026, 11, 3),
          flowVersion: 2,
          step: step,
          latitude: 34.0537,
          longitude: -118.2428,
          contact: const ReportContact(anonymous: true),
        ),
      ),
    ),
  );
  if (step == 1) {
    for (
      var turn = 0;
      turn < 100 && find.text('Bulky Items').evaluate().isEmpty;
      turn++
    ) {
      await tester.runAsync(() => Future<void>(() {}));
      await tester.pump();
    }
  }
  await tester.pumpAndSettle();
}
