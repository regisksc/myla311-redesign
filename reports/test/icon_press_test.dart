import 'dart:async';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final platform = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets('keyboard focus visibly outlines Settings', (tester) async {
    await _openHome(tester, 'normal');

    await _focusSettings(tester);

    expect(
      tester.getSemantics(_control('Settings')).flagsCollection.isFocused,
      Tristate.isTrue,
    );
    expect(
      _surfaces(_control('Settings')).any(
        (decoration) =>
            decoration.border is Border &&
            (decoration.border! as Border).top.color == const Color(0xff3c3c3c),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, variant: platform);

  testWidgets('Enter opens the focused Settings control', (tester) async {
    await _openHome(tester, 'normal');
    await _focusSettings(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Reduce motion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: platform);

  for (final mode in ['normal', 'system', 'session']) {
    testWidgets(
      '$mode Settings feedback recovers without opening Settings',
      (tester) async {
        await _openHome(tester, mode);

        final feedback = await _probe(tester, 'Settings');

        expect(feedback, _expected());
        expect(find.widgetWithText(AppBar, 'Settings'), findsNothing);
        expect(tester.takeException(), isNull);
      },
      variant: platform,
    );

    testWidgets('$mode Settings tap opens its preferences', (tester) async {
      await _openHome(tester, mode);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Reduce motion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets('$mode developer close feedback keeps the sheet open', (
      tester,
    ) async {
      await _openDeveloperSheet(tester, mode);

      final feedback = await _probe(tester, 'Close Dev API mode');

      expect(feedback, _expected(inset: true, reduced: mode != 'normal'));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets('$mode developer close tap dismisses the sheet', (
      tester,
    ) async {
      await _openDeveloperSheet(tester, mode);

      await tester.tap(find.byTooltip('Close Dev API mode'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets(
      '$mode disabled zoom feedback stays flat and does not zoom',
      (tester) async {
        final paths = await _openFlow(tester, mode, blocked: true);
        try {
          final initialZoom = _zoom(tester);

          final feedback = await _probe(tester, 'Zoom in');

          expect(feedback, _expected(enabled: false));
          expect(_zoom(tester), initialZoom);
          expect(tester.takeException(), isNull);
        } finally {
          await _releasePendingRead(tester, paths);
        }
      },
      variant: platform,
    );

    testWidgets('$mode disabled zoom tap leaves the map unchanged', (
      tester,
    ) async {
      final paths = await _openFlow(tester, mode, blocked: true);
      try {
        final initialZoom = _zoom(tester);

        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pumpAndSettle();

        expect(_zoom(tester), initialZoom);
        expect(tester.takeException(), isNull);
      } finally {
        await _releasePendingRead(tester, paths);
      }
    }, variant: platform);

    testWidgets(
      '$mode zoom-in feedback recovers without changing the map',
      (tester) async {
        await _openFlow(tester, mode);
        final initialZoom = _zoom(tester);

        final feedback = await _probe(tester, 'Zoom in');

        expect(feedback, _expected());
        expect(_zoom(tester), initialZoom);
        expect(tester.takeException(), isNull);
      },
      variant: platform,
    );

    testWidgets('$mode zoom-in tap increases the map scale once', (
      tester,
    ) async {
      await _openFlow(tester, mode);
      final initialZoom = _zoom(tester);

      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();

      expect(_zoom(tester) - initialZoom, 1);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets(
      '$mode zoom-out feedback recovers without changing the map',
      (tester) async {
        await _openFlow(tester, mode);
        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pumpAndSettle();
        final zoomed = _zoom(tester);

        final feedback = await _probe(tester, 'Zoom out');

        expect(feedback, _expected());
        expect(_zoom(tester), zoomed);
        expect(tester.takeException(), isNull);
      },
      variant: platform,
    );

    testWidgets('$mode zoom-out tap restores the original map scale', (
      tester,
    ) async {
      await _openFlow(tester, mode);
      final initialZoom = _zoom(tester);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();

      expect(_zoom(tester), initialZoom);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets(
      '$mode zoom-in feedback remains reusable after zooming back',
      (tester) async {
        await _openFlow(tester, mode);
        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Zoom out'));
        await tester.pumpAndSettle();

        final feedback = await _probe(tester, 'Zoom in');

        expect(feedback, _expected());
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
      variant: platform,
    );

    testWidgets('$mode in-flow discard asks for confirmation', (tester) async {
      await _openFlow(tester, mode);
      await _showDiscardAction(tester);

      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();

      expect(find.text('Discard draft?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets('$mode cancelling discard retains the report flow', (
      tester,
    ) async {
      await _openFlow(tester, mode);
      await _showDiscardAction(tester);
      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets('$mode Back feedback recovers without leaving the report', (
      tester,
    ) async {
      await _openFlow(tester, mode);

      final feedback = await _probe(tester, 'Back');

      expect(feedback, _expected());
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: platform);

    testWidgets('$mode Back tap returns to Home', (tester) async {
      await _openFlow(tester, mode);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Start a report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: platform);
  }
}

Future<_SupportPath> _openHome(WidgetTester tester, String mode) async {
  rootBundle.evict('assets/service_catalog.json');
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final originalPaths = PathProviderPlatform.instance;
  final directory = Directory('.dart_tool').createTempSync('icon-press-');
  final paths = _SupportPath(directory.absolute.path);
  PathProviderPlatform.instance = paths;
  addTearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    await directory.delete(recursive: true);
  });
  SharedPreferences.setMockInitialValues({});
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: mode == 'system');
  await tester.pumpWidget(const ReportApp(client: _NoCityWrites()));
  await tester.pumpAndSettle();
  await _ready(tester, () => find.text('Start a report').evaluate().isNotEmpty);
  if (mode == 'session') {
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Reduce motion'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
  return paths;
}

Future<void> _focusSettings(WidgetTester tester) async {
  for (var tab = 0; tab < 12; tab++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    if (tester.getSemantics(_control('Settings')).flagsCollection.isFocused ==
        Tristate.isTrue) {
      return;
    }
  }
}

Future<void> _openDeveloperSheet(WidgetTester tester, String mode) async {
  await _openHome(tester, mode);
  await tester.ensureVisible(find.text('Dev / API'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Dev / API'));
  await tester.pumpAndSettle();
}

Future<_SupportPath> _openFlow(
  WidgetTester tester,
  String mode, {
  bool blocked = false,
}) async {
  final paths = await _openHome(tester, mode);
  if (blocked) {
    final pending = Completer<String>();
    paths.pending = pending;
    addTearDown(() {
      if (!pending.isCompleted) pending.complete(paths.path);
    });
  }
  await tester.ensureVisible(find.text('Start a report'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start a report'));
  await tester.pumpAndSettle();
  await _ready(
    tester,
    () =>
        find.widgetWithText(TextField, 'Search services').evaluate().isNotEmpty,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Search services'),
    'Illegal Dumping',
  );
  await tester.pumpAndSettle();
  await _ready(
    tester,
    () => find.text('Illegal Dumping Item Pickup').evaluate().isNotEmpty,
  );
  await tester.tap(find.text('Illegal Dumping Item Pickup'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Start report'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start report'));
  await tester.pumpAndSettle();
  if (!blocked) {
    await _ready(tester, () => _zoomEnabled(tester));
  }
  return paths;
}

Future<void> _releasePendingRead(
  WidgetTester tester,
  _SupportPath paths,
) async {
  final pending = paths.pending;
  paths.pending = null;
  if (pending != null && !pending.isCompleted) pending.complete(paths.path);
  if (find.byTooltip('Zoom in').evaluate().isNotEmpty) {
    await _ready(tester, () => _zoomEnabled(tester));
  }
}

bool _zoomEnabled(WidgetTester tester) =>
    find.byTooltip('Zoom in').evaluate().isNotEmpty &&
    tester.widget<IconButton>(_control('Zoom in')).onPressed != null;

Future<void> _showDiscardAction(WidgetTester tester) async {
  for (
    var scroll = 0;
    scroll < 5 && find.text('Discard draft').evaluate().isEmpty;
    scroll++
  ) {
    await tester.dragFrom(
      tester.getTopLeft(find.byType(ListView).first) + const Offset(4, 100),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
  }
  await Scrollable.ensureVisible(
    tester.element(find.text('Discard draft')),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
}

Finder _control(String tooltip) => find
    .ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton))
    .first;

double _zoom(WidgetTester tester) =>
    MapCamera.of(tester.element(find.byType(TileLayer))).zoom;

Iterable<BoxDecoration> _surfaces(Finder control) sync* {
  for (final element in [
    ...find
        .descendant(of: control, matching: find.byType(DecoratedBox))
        .evaluate(),
    ...find
        .ancestor(of: control, matching: find.byType(DecoratedBox))
        .evaluate(),
  ]) {
    if (element.renderObject case final RenderDecoratedBox render) {
      if (render.decoration case final BoxDecoration decoration) {
        yield decoration;
      }
    }
  }
}

List<double> _depth(Finder control) => [
  for (final decoration in _surfaces(control))
    for (final shadow in decoration.boxShadow ?? const <BoxShadow>[])
      if (shadow.offset.dy > 0) shadow.offset.dy,
];

Future<Map<String, Object>> _probe(WidgetTester tester, String tooltip) async {
  final control = _control(tooltip);
  await Scrollable.ensureVisible(tester.element(control), alignment: 0.5);
  await tester.pumpAndSettle();
  final icon = find.descendant(of: control, matching: find.byType(Icon)).last;
  final bounds = tester.getRect(control);
  final origin = tester.getCenter(icon);
  final resting = _depth(control);
  final gesture = await tester.startGesture(tester.getCenter(control));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 90));
  final halfway = tester.getCenter(icon).dy - origin.dy;
  await tester.pump(const Duration(milliseconds: 90));
  final held = tester.getCenter(icon).dy - origin.dy;
  final pressed = _depth(control);
  final stable = tester.getRect(control) == bounds;
  await gesture.cancel();
  await tester.pumpAndSettle();
  final restored =
      tester.getCenter(icon) == origin &&
      _depth(control).toString() == resting.toString();
  final release = await tester.startGesture(tester.getCenter(control));
  await tester.pump(const Duration(milliseconds: 100));
  await release.moveTo(const Offset(1, 1));
  await release.up();
  await tester.pumpAndSettle();
  return {
    'restDepth': resting,
    'pressedDepth': pressed,
    'travel': held,
    'animated': halfway > 0 && halfway < held,
    'fixedBounds': stable && tester.getRect(control) == bounds,
    'minimumHitArea': bounds.width >= 44 && bounds.height >= 44,
    'cancelRestored': restored,
    'releaseRestored':
        tester.getCenter(icon) == origin &&
        _depth(control).toString() == resting.toString(),
  };
}

Map<String, Object> _expected({
  bool enabled = true,
  bool inset = false,
  bool reduced = false,
}) => {
  'restDepth': enabled ? [3.0] : <double>[],
  'pressedDepth': enabled && inset ? [1.0] : <double>[],
  'travel': enabled && !(inset && reduced) ? 3.0 : 0.0,
  'animated': inset && !reduced && enabled,
  'fixedBounds': true,
  'minimumHitArea': true,
  'cancelRestored': true,
  'releaseRestored': true,
};

Future<void> _ready(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  if (!ready()) throw StateError('The icon action did not become available');
  await tester.pumpAndSettle();
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  Completer<String>? pending;

  @override
  Future<String> getApplicationSupportPath() =>
      pending?.future ?? Future.value(path);
}

class _NoCityWrites implements SubmissionClient {
  const _NoCityWrites();

  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('Icon feedback must not submit a Report');
}
