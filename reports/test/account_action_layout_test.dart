import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/account/account_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('account forms keep primary actions compact and left aligned', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [375.0, 390.0]) {
      for (final variant in [
        (route: 'Sign in to demo', action: 'Continue in demo'),
        (route: 'Create demo account', action: 'Create local profile'),
        (route: 'Forgot password?', action: 'Preview recovery'),
        (route: 'Profile', action: 'Save demo profile'),
      ]) {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('$width-${variant.route}'),
            theme: ReportsStyle.theme,
            home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
          ),
        );
        await tester.pumpAndSettle();
        if (variant.route == 'Forgot password?') {
          await tester.tap(find.text('Sign in to demo'));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text(variant.route));
        await tester.tap(find.text(variant.route));
        await tester.pumpAndSettle();
        final action = find.widgetWithText(FilledButton, variant.action);
        await tester.ensureVisible(action);
        final bounds = tester.getRect(action);
        expect(bounds.left, closeTo(20, 1), reason: '$width ${variant.action}');
        expect(
          bounds.width - tester.getSize(find.text(variant.action)).width,
          lessThanOrEqualTo(48),
          reason: '$width ${variant.action}',
        );
        expect(bounds.width, greaterThanOrEqualTo(44));
        expect(bounds.height, greaterThanOrEqualTo(44));
        expect(find.byType(TextFormField), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
