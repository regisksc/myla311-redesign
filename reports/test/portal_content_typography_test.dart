import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/account/help_page.dart';
import 'package:reports/features/account/account_page.dart';
import 'package:reports/features/account/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Settings informational cards retain measured heading and copy rhythm',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          theme: ReportsStyle.theme,
          home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      for (final row in [
        (
          'Your account',
          'Sign in, manage your profile, or keep using MyLA311 without an account.',
        ),
        ('Saved contact details', 'Nothing remembered for future reports.'),
        (
          'Privacy & permissions',
          'Location is requested only when you choose to use it. Photos are optional. Your device manages permissions.',
        ),
        (
          'Data on this device',
          'Clear local preview data and remembered contact. Real submissions and unconfirmed sends are kept.',
        ),
      ]) {
        await tester.scrollUntilVisible(find.text(row.$1), 150);
        await tester.pumpAndSettle();
        final heading = find.text(row.$1);
        final copy = find.text(row.$2);
        expect(
          tester.getTopLeft(copy).dy - tester.getBottomLeft(heading).dy,
          12,
        );
        final titleStyle = tester
            .renderObject<RenderParagraph>(heading)
            .text
            .style!;
        final copyStyle = tester
            .renderObject<RenderParagraph>(copy)
            .text
            .style!;
        expect(titleStyle.fontSize, 21);
        expect(titleStyle.height, 1.2);
        expect(copyStyle.fontSize, 15);
        expect(copyStyle.height, 1.6);
      }
    },
  );
  testWidgets('Demo account card matches measured title and paragraph gap', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    final heading = find.text('Demo account');
    final paragraph = find.text(
      'Sign in, registration and profile changes are simulated locally.',
    );
    final style = tester.renderObject<RenderParagraph>(heading).text.style!;
    expect(style.fontSize, 25);
    expect(style.height, 1.2);
    expect(style.fontWeight, FontWeight.w800);
    expect(
      tester.getTopLeft(paragraph).dy - tester.getBottomLeft(heading).dy,
      12,
    );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Help uses measured mobile heading and introductory rhythm', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [375.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(theme: ReportsStyle.theme, home: const HelpPage()),
      );
      await tester.pumpAndSettle();
      final heading = find.text('Let’s clear things up.');
      final intro = find.text('A few useful answers, without the fine print.');
      final headingStyle = tester
          .renderObject<RenderParagraph>(heading)
          .text
          .style!;
      final introStyle = tester
          .renderObject<RenderParagraph>(intro)
          .text
          .style!;
      expect(headingStyle.fontSize, 29);
      expect(headingStyle.height, 1.12);
      expect(introStyle.fontSize, 15);
      expect(introStyle.height, 1.6);
      expect(
        tester.getTopLeft(intro).dy - tester.getBottomLeft(heading).dy,
        10,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Account overview uses portal title and paragraph spacing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('Your account');
    final intro = find.text(
      'Explore account tools without connecting to a City account.',
    );
    expect(
      tester.renderObject<RenderParagraph>(title).text.style!.fontSize,
      30,
    );
    expect(
      tester.renderObject<RenderParagraph>(intro).text.style!.fontSize,
      16,
    );
    expect(tester.getTopLeft(intro).dy - tester.getBottomLeft(title).dy, 16);
    expect(
      tester.getTopLeft(find.byType(Card).first).dy -
          tester.getBottomLeft(intro).dy,
      24,
    );
  });
  testWidgets('Account forms use portal paragraph and field rhythm', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in to demo'));
    await tester.pumpAndSettle();
    final title = find.descendant(
      of: find.byType(ListView),
      matching: find.text('Sign in'),
    );
    final intro = find.text('Demo only. Do not enter a real password.');
    expect(
      tester.renderObject<RenderParagraph>(title).text.style!.fontSize,
      30,
    );
    expect(
      tester.renderObject<RenderParagraph>(intro).text.style!.fontSize,
      16,
    );
    expect(tester.getTopLeft(intro).dy - tester.getBottomLeft(title).dy, 16);
    final email = find.text('Email');
    expect(tester.getTopLeft(email).dy - tester.getBottomLeft(intro).dy, 44);
    expect(
      tester.getTopLeft(find.byType(TextFormField).first).dy -
          tester.getBottomLeft(email).dy,
      8,
    );
  });
  testWidgets('Settings uses the measured mobile page-intro heading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Make yourself comfortable'),
      150,
    );
    final title = find.descendant(
      of: find.byType(ListView),
      matching: find.text('Settings'),
    );
    expect(
      tester.renderObject<RenderParagraph>(title).text.style!.fontSize,
      29,
    );
    expect(
      tester.renderObject<RenderParagraph>(title).text.style!.height,
      1.12,
    );
  });
}
