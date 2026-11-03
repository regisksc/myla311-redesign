import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'preview steps use compact flow headers while Services stays general',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final step in [-1, 0, 1, 2, 3, 4, 5]) {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(step),
            theme: ReportsStyle.theme,
            home: ServicePreviewPage(
              service: const {
                'id': 'flooding',
                'name': 'Flooding',
                'group': 'Water',
                'mode': 'guest',
                'evidence': 'optional attachments',
              },
              draft: step < 0
                  ? null
                  : {'id': 'header-fixture-$step', 'step': step},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final flow = step >= 0 && step < 5;
        final header = find.byType(AppBar);
        final title = find.descendant(
          of: header,
          matching: find.text(flow ? 'New report' : 'Services'),
        );
        expect(title, findsOneWidget, reason: 'step $step');
        final titleStyle = DefaultTextStyle.of(tester.element(title)).style;
        expect(titleStyle.fontSize, flow ? 16 : 20, reason: 'step $step');
        expect(tester.widget<AppBar>(header).centerTitle, isNot(true));
        if (flow) {
          final save = find.widgetWithText(TextButton, 'Save and close');
          final label = find.descendant(
            of: save,
            matching: find.text('Save and close'),
          );
          final saveStyle = DefaultTextStyle.of(tester.element(label)).style;
          expect(saveStyle.fontSize, 11);
          expect(saveStyle.color, ReportsStyle.ink);
          expect(tester.getSize(save).height, greaterThanOrEqualTo(44));
          expect(tester.widget<TextButton>(save).onPressed, isNotNull);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
}
