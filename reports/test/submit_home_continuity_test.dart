import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/submit_home_native_fixture.dart';

void main() {
  testWidgets(
    'Submit retains its pending control and first accepted Home frame has the delivery overlay',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final originalPaths = PathProviderPlatform.instance;
      final support = Directory('.dart_tool').createTempSync('continuity-');
      PathProviderPlatform.instance = _SupportPath(support.absolute.path);
      addTearDown(() async {
        PathProviderPlatform.instance = originalPaths;
        await support.delete(recursive: true);
      });
      SharedPreferences.setMockInitialValues({});
      await motionStore.saveDraft(motionReviewDraft());
      final portal = ControlledMotionPortal();
      await tester.pumpWidget(ReportApp(client: portal.client));
      final resume = find.descendant(
        of: find.byKey(const Key('home-resume-card')),
        matching: find.text('Continue'),
      );
      await _until(tester, () => resume.evaluate().isNotEmpty);
      await tester.ensureVisible(resume);
      await tester.tap(resume);
      final submit = find.widgetWithText(FilledButton, 'Submit');
      await _until(
        tester,
        () =>
            submit.evaluate().isNotEmpty &&
            tester.widget<FilledButton>(submit).onPressed != null,
      );
      await tester.pumpAndSettle();
      final submitBounds = tester.getRect(submit);
      await tester.tap(submit);
      await _until(tester, () => portal.submissions == 1);
      final pending = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(FilledButton),
      );
      expect(tester.getRect(pending), submitBounds);
      expect(tester.widget<FilledButton>(pending).onPressed, isNull);
      final scene = find.byKey(const Key('report-delivery-scene'));
      expect(scene, findsNothing);
      expect(find.text(motionReceipt), findsNothing);
      expect(portal.submittedAction.toString(), contains('submitCase'));

      portal.acceptance.complete();
      var exposedHomeFrames = 0;
      await _until(tester, () {
        if (find.byType(ReportFlowPage).evaluate().isEmpty &&
            scene.evaluate().isEmpty) {
          exposedHomeFrames++;
        }
        return scene.evaluate().isNotEmpty;
      });
      expect(
        exposedHomeFrames,
        0,
        reason:
            'Home must never flash its old hero between Submit and delivery',
      );
      final retained = (await tester.runAsync(motionStore.loadReports))!.single;
      expect(retained.state, ReportState.submitted);
      expect(retained.serviceRequestNumber, motionReceipt);
      final serialized = retained.toJson();
      await tester.pumpAndSettle();
      expect(find.text(motionReceipt), findsOneWidget);
      expect(find.text('View receipt'), findsOneWidget);
      expect(portal.submissions, 1);
      expect(
        (await tester.runAsync(motionStore.loadReports))!.single.toJson(),
        serialized,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000; turn++) {
      await Future<void>(() {});
      await tester.pump();
      if (ready()) return;
    }
    throw StateError('The resident action did not become available');
  });
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;

  @override
  Future<String> getApplicationSupportPath() async => path;
}
