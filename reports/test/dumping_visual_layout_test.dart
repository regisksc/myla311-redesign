import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as gc;
import 'package:reports/features/report/presentation/location_map.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/application/report_store.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('report header is compact and discard remains reachable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmissionClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('New report');
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    expect(tester.widget<Text>(title).style?.fontSize, 16);
    final save = find.widgetWithText(TextButton, 'Save and close');
    expect(
      tester.widget<TextButton>(save).style?.foregroundColor?.resolve({}),
      ReportsStyle.ink,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Discard draft'),
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text('Discard draft'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Discard draft'));
    await tester.pumpAndSettle();
    expect(find.text('Discard draft?'), findsOneWidget);
  });
  testWidgets('location offers address search then map before GPS', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmissionClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final address = find.byKey(const Key('report-address'));
    final search = find.widgetWithText(OutlinedButton, 'Search');
    expect(search, findsOneWidget);
    expect(
      find.text('Street address or intersection (required)'),
      findsOneWidget,
    );
    expect(
      tester.getRect(address).center.dy,
      closeTo(tester.getRect(search).center.dy, 3),
    );
    final map = find.byType(FlutterMap);
    expect(tester.getTopLeft(address).dy, lessThan(tester.getTopLeft(map).dy));
    final gps = find.widgetWithText(OutlinedButton, 'Use my location');
    await tester.scrollUntilVisible(
      gps,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester.getTopLeft(gps).dy,
      greaterThan(tester.getBottomLeft(map).dy),
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'Search resolves the current address immediately without a second lookup',
    (tester) async {
      final original = gc.GeocodingPlatformFactory.instance;
      final lookup = _Lookup();
      gc.GeocodingPlatformFactory.instance = _LookupFactory(lookup);
      if (original != null) {
        addTearDown(() => gc.GeocodingPlatformFactory.instance = original);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationMap(
              position: null,
              enabled: true,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('report-address')),
        '200 N Spring St',
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Search'));
      await tester.pump();
      expect(lookup.requests, ['200 N Spring St, Los Angeles, CA']);
      expect(find.textContaining('No match found.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(lookup.requests, hasLength(1));
    },
  );
}

class _NoSubmissionClient implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('Visual checks must not send reports');
}

class _MemoryStore implements ReportStore {
  @override
  Future<ReportDraft?> loadDraft() async => null;
  @override
  Future<List<Report>> loadReports() async => [];
  @override
  Future<void> saveDraft(ReportDraft draft) async {}
  @override
  Future<void> saveReport(Report report) async {}
  @override
  Future<void> replaceReport(Report before, Report after) async {}
  @override
  Future<void> discardDraft(DateTime createdAt) async {}
  @override
  Future<void> removeLocalReceipt(Report receipt) async {}
}

class _Lookup extends gc.Geocoding {
  _Lookup() : super.implementation(const gc.GeocodingCreationParams());
  final requests = <String>[];
  @override
  Future<List<gc.Location>> locationFromAddress(
    String address, {
    Locale? locale,
  }) async {
    requests.add(address);
    return [];
  }
}

class _LookupFactory extends gc.GeocodingPlatformFactory {
  _LookupFactory(this.lookup);
  final _Lookup lookup;
  @override
  gc.Geocoding createGeocoding(gc.GeocodingCreationParams params) => lookup;
}
