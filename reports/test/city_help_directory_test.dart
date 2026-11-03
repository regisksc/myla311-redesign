import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  testWidgets(
    'guest searches City help and returns from contact details without changing reports',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'reports_device_preferences_v1': true,
      });
      final support = Directory.systemTemp.createTempSync('city-help-');
      final originalPaths = PathProviderPlatform.instance;
      final originalLauncher = UrlLauncherPlatform.instance;
      final launcher = _Launcher();
      PathProviderPlatform.instance = _SupportPath(support.path);
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() async {
        PathProviderPlatform.instance = originalPaths;
        UrlLauncherPlatform.instance = originalLauncher;
        await support.delete(recursive: true);
      });
      const store = LocalReportStore();
      final draft = ReportDraft(
        createdAt: DateTime(2026, 10, 29),
        description: 'Preserved report',
        flowVersion: 2,
        contact: const ReportContact(anonymous: true),
      );
      await store.saveDraft(draft);
      final receipt = Report(
        description: 'Previously submitted',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 10, 28),
        contact: const ReportContact(anonymous: true),
      ).submittedWith('C-04955177');
      await store.saveReport(receipt);
      var requests = 0;
      final transport = MockClient((_) async {
        requests++;
        return http.Response('{}', 500);
      });
      addTearDown(transport.close);
      await tester.pumpWidget(
        ReportApp(
          client: PortalSubmissionClient(httpClient: transport),
          store: store,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Help and information'));
      await tester.tap(find.text('Help and information'));
      await tester.pumpAndSettle();

      final search = find.widgetWithText(TextField, 'Search help');
      expect(search, findsOneWidget);
      await tester.enterText(search, 'unmatched-help-topic');
      await tester.pumpAndSettle();
      expect(
        find.text('No help topics found. Try another word.'),
        findsOneWidget,
      );
      await tester.enterText(search, '  311  ');
      await tester.pumpAndSettle();
      expect(find.text('Who to call at MyLA311'), findsOneWidget);
      expect(find.text('How reporting works'), findsNothing);
      expect(launcher.urls, isEmpty);
      await tester.tap(find.text('Who to call at MyLA311'));
      await tester.pumpAndSettle();
      expect(find.textContaining('213-473-3231'), findsWidgets);
      expect(find.textContaining('311@lacity.org'), findsWidgets);
      expect(find.textContaining('911'), findsOneWidget);
      expect(launcher.urls, isEmpty);

      await tester.ensureVisible(find.text('All help topics'));
      await tester.tap(find.text('All help topics'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller?.text, '  311  ');
      expect(find.text('Who to call at MyLA311'), findsOneWidget);
      await tester.enterText(search, 'privacy');
      await tester.pumpAndSettle();
      expect(find.text('Your information & privacy'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      final retainedDraft = await tester.runAsync(store.loadDraft);
      final retainedReports = await tester.runAsync(store.loadReports);
      expect(retainedDraft!.toJson(), draft.toJson());
      expect(retainedReports!.single.toJson(), receipt.toJson());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reports_device_preferences_v1'), isTrue);
      expect(requests, 0);
      expect(launcher.urls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _Launcher extends UrlLauncherPlatform {
  final urls = <String>[];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    return true;
  }
}
