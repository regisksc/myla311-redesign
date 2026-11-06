import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> openStep(WidgetTester tester, int step, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('$step-$size'),
      theme: ReportsStyle.theme,
      home: ServicePreviewPage(
        service: const {
          'name': 'Flooding',
          'group': 'Street Problems/Repairs',
          'evidence': 'anonymous available; optional attachments',
        },
        draft: {'id': 'geometry', 'step': step, 'named': false},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Mona Sans',
    )..addFont(rootBundle.load('assets/fonts/MonaSans.ttf'))).load();
  });
  testWidgets('preview content uses approved heading and paragraph typography', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(375, 812), const Size(390, 844)]) {
      for (final entry in {
        0: 'Flooding',
        1: 'Place it on the map.',
        2: 'A little more context.',
        3: 'How should we reach you?',
        4: 'One last look.',
      }.entries) {
        await openStep(tester, entry.key, size);
        final heading = tester.renderObject<RenderParagraph>(
          find.text(entry.value),
        );
        expect(heading.text.style?.fontSize, 30);
        expect(heading.text.style?.height, 1.2);
      }
      await openStep(tester, 0, size);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Example questions'),
      );
      expect(paragraph.text.style?.fontSize, 16);
      expect(paragraph.text.style?.height, 1.6);
      expect(
        tester.getTopLeft(find.text('Example questions')).dy -
            tester.getBottomLeft(find.text('Flooding')).dy,
        closeTo(20, .1),
      );
      expect(
        tester
                .getTopLeft(
                  find.text(
                    'These example questions illustrate the design. The live service may ask for more details.',
                  ),
                )
                .dy -
            tester.getBottomLeft(find.text('Example questions')).dy,
        closeTo(12, .1),
      );
    }
  });

  testWidgets('preview map illustration retains the approved minimum height', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(375, 812), const Size(390, 844)]) {
      await openStep(tester, 1, size);
      final map = find.ancestor(
        of: find.bySemanticsLabel('Illustrative location pin, not a live map'),
        matching: find.byType(Card),
      );
      expect(tester.getSize(map).height, greaterThanOrEqualTo(180));
    }
  });

  testWidgets('preview option and consent checkboxes precede their labels', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in {
      0: 'Add a useful extra detail',
      4: 'I understand this creates a local demo receipt. Nothing is sent to the City.',
    }.entries) {
      await openStep(tester, entry.key, const Size(375, 812));
      final tile = find.widgetWithText(CheckboxListTile, entry.value);
      final checkbox = find.descendant(
        of: tile,
        matching: find.byType(Checkbox),
      );
      expect(
        tester.getTopLeft(checkbox).dx,
        lessThan(tester.getTopLeft(find.text(entry.value)).dx),
      );
      expect(
        tester.widget<CheckboxListTile>(tile).contentPadding,
        EdgeInsets.zero,
      );
    }
  });

  testWidgets(
    'known service entry opens the journey without preliminary panels',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openStep(tester, -1, const Size(390, 844));
      expect(find.text('← Street Problems/Repairs'), findsOneWidget);
      final eyebrow = tester.renderObject<RenderParagraph>(
        find.text('SERVICE INFORMATION'),
      );
      expect(eyebrow.text.style?.fontSize, 12);
      expect(find.text('Flooding'), findsOneWidget);
      expect(find.text('Before you start'), findsNothing);
      expect(
        find.text('This is a local preview. No report is sent to the City.'),
        findsNothing,
      );
      await tester.tap(find.text('Start report'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 6 · Details'), findsOneWidget);
    },
  );

  testWidgets('service breadcrumb returns through the existing route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ServicePreviewPage(
                    service: {
                      'name': 'Flooding',
                      'group': 'Streets',
                      'evidence': 'anonymous available',
                    },
                  ),
                ),
              ),
              child: const Text('Open service'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open service'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('← Streets'));
    await tester.pumpAndSettle();
    expect(find.text('Open service'), findsOneWidget);
    expect(find.text('Flooding'), findsNothing);
  });

  testWidgets('preview fields use approved text, inset and following margin', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openStep(tester, 0, const Size(375, 812));
    final field = find.byType(TextFormField).first;
    final input = find.descendant(
      of: field,
      matching: find.byType(InputDecorator),
    );
    expect(
      tester.widget<InputDecorator>(input).decoration.contentPadding,
      const EdgeInsets.all(14),
    );
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.style.fontSize, 16);
    expect(editable.style.height, 1.5);
    expect(
      tester
              .getTopLeft(
                find.widgetWithText(
                  CheckboxListTile,
                  'Add a useful extra detail',
                ),
              )
              .dy -
          tester.getBottomLeft(field).dy,
      closeTo(20, .1),
    );
  });

  testWidgets(
    'review presents selected answers in the approved label and value columns',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [const Size(375, 812), const Size(390, 844)]) {
        await openStep(tester, 4, size);
        expect(
          tester.getTopLeft(find.text('Service')).dy,
          tester.getTopLeft(find.text('Flooding')).dy,
        );
        expect(
          tester.getTopLeft(find.text('Flooding')).dx -
              tester.getTopLeft(find.text('Service')).dx,
          closeTo(102, .1),
        );
        final label = tester.renderObject<RenderParagraph>(
          find.text('Service'),
        );
        expect(label.text.style?.fontSize, 16);
        expect(label.text.style?.height, 1.5);
        expect(
          tester.getTopLeft(find.text('Details')).dy -
              tester.getTopLeft(find.text('Service')).dy,
          closeTo(36, .1),
        );
      }
    },
  );
}
