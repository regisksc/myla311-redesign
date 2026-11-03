import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('preview history introduces local records before its controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [375.0, 390.0]) {
      SharedPreferences.setMockInitialValues({
        'service_previews_v1':
            '[{"id":"geometry-preview","service":"Flooding","step":5}]',
      });
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(width),
          theme: ReportsStyle.theme,
          home: const ServiceHistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      final heading = find.text('My Reports');
      final intro = find.text(
        'Your drafts and completed previews stay on this device.',
      );
      expect(heading, findsOneWidget);
      expect(intro, findsOneWidget);
      final headingStyle = tester.widget<Text>(heading).style!;
      final introStyle = tester.widget<Text>(intro).style!;
      expect(headingStyle.fontSize, 30);
      expect(headingStyle.height, 1.2);
      expect(introStyle.fontSize, 16);
      expect(introStyle.height, 1.5);
      expect(tester.getRect(heading).left, closeTo(20, .1));
      expect(
        tester.getRect(intro).top - tester.getRect(heading).bottom,
        closeTo(16, .1),
      );
      expect(
        tester.getRect(find.byType(TextField)).top -
            tester.getRect(intro).bottom,
        closeTo(24, .1),
      );
      expect(
        tester.getRect(find.text('Look up a request')).top,
        greaterThan(tester.getRect(find.text('Flooding')).bottom),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('local lookup has its own heading and a history breadcrumb', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [375.0, 390.0]) {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(width),
          theme: ReportsStyle.theme,
          home: const ServiceHistoryPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Look up a request'));
      await tester.pumpAndSettle();

      final heading = find.descendant(
        of: find.byType(ListView),
        matching: find.text('Look up a request'),
      );
      final breadcrumb = find.widgetWithText(TextButton, 'My Reports');
      final intro = find.text('City lookup is not connected in this preview.');
      expect(heading, findsOneWidget);
      expect(breadcrumb, findsOneWidget);
      final headingStyle = tester.widget<Text>(heading).style!;
      final introStyle = tester.widget<Text>(intro).style!;
      expect(headingStyle.fontSize, 30);
      expect(headingStyle.height, 1.2);
      expect(introStyle.fontSize, 16);
      expect(introStyle.height, 1.5);
      expect(tester.getRect(heading).left, closeTo(20, .1));
      expect(tester.getRect(breadcrumb).left, closeTo(20, .1));
      expect(
        tester.getRect(heading).top - tester.getRect(breadcrumb).bottom,
        closeTo(0, .1),
      );
      expect(
        tester.getRect(intro).top - tester.getRect(heading).bottom,
        closeTo(16, .1),
      );
      expect(
        tester.getRect(find.byType(TextFormField)).top -
            tester.getRect(intro).bottom,
        closeTo(24, .1),
      );
      await tester.tap(breadcrumb);
      await tester.pumpAndSettle();
      expect(find.text('My Reports'), findsOneWidget);
      expect(find.text('My previews'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Look up a request'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
