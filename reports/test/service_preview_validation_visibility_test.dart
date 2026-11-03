import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Mona Sans',
    )..addFont(rootBundle.load('assets/fonts/MonaSans.ttf'))).load();
  });

  testWidgets(
    'unchecked Review reveals and announces its error above the footer',
    (tester) async {
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final semantics = tester.ensureSemantics();
      const error =
          'Please confirm that this creates a local demo receipt only.';
      const receipts = '[{"serviceRequestNumber":"C-04955177"}]';
      try {
        for (final size in [const Size(375, 812), const Size(390, 844)]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          SharedPreferences.setMockInitialValues({'reports_v2': receipts});
          await tester.pumpWidget(reviewApp(size));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Create local receipt'));
          await tester.pumpAndSettle();
          final errorRect = tester.getRect(find.text(error));
          final bodyRect = tester.getRect(find.byType(ListView));
          final footerRect = tester.getRect(
            find.byKey(const Key('preview-action-footer')),
          );
          expect(errorRect.top, greaterThanOrEqualTo(bodyRect.top));
          expect(errorRect.bottom, lessThanOrEqualTo(footerRect.top));
          expect(
            tester.getSemantics(find.text(error)),
            matchesSemantics(
              label: error,
              isLiveRegion: true,
              textDirection: TextDirection.ltr,
            ),
          );
          expect(find.text('Local receipt'), findsNothing);
          expect(
            (await SharedPreferences.getInstance()).getString('reports_v2'),
            receipts,
          );
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'reduced motion reveals Review errors without animated scrolling',
    (tester) async {
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        reviewApp(const Size(375, 812), reducedMotion: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create local receipt'));
      await tester.pump();
      await tester.pump();
      final error = find.text(
        'Please confirm that this creates a local demo receipt only.',
      );
      final footer = find.byKey(const Key('preview-action-footer'));
      expect(
        tester.getBottomLeft(error).dy,
        lessThanOrEqualTo(tester.getTopLeft(footer).dy),
      );
      expect(find.text('Local receipt'), findsNothing);
    },
  );
}

Widget reviewApp(Size size, {bool reducedMotion = false}) => MaterialApp(
  key: ValueKey('$size-$reducedMotion'),
  theme: ReportsStyle.theme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: child!,
  ),
  home: const ServicePreviewPage(
    service: {
      'name': 'Flooding',
      'group': 'Street Problems/Repairs',
      'evidence': 'anonymous available; optional attachments',
    },
    draft: {
      'id': 'unchecked-review',
      'step': 4,
      'description': 'Synthetic preview: water collecting near curb.',
      'address': '200 N Spring St, Los Angeles, CA',
      'photos': 1,
      'named': false,
    },
  ),
);
