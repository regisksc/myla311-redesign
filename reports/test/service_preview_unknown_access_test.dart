import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:reports/features/account/account_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('unverified service access explains availability without Start', (
    tester,
  ) async {
    for (final evidence in [
      '',
      'optional attachments; location boundary City Boundary',
    ]) {
      SharedPreferences.setMockInitialValues({
        'reports_v2': 'preserved City receipts',
      });
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(evidence),
          home: ServicePreviewPage(
            service: {
              'name': 'Unverified service',
              'group': 'Other',
              'evidence': evidence,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Availability is still being confirmed.'),
        findsOneWidget,
      );
      expect(
        find.text('The next steps for this service are not verified yet.'),
        findsOneWidget,
      );
      expect(find.text('Start preview'), findsNothing);
      expect(find.text('Start report'), findsNothing);
      expect(
        find.text('No account is needed to explore this report.'),
        findsNothing,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('reports_v2'),
        'preserved City receipts',
      );
    }
  });

  testWidgets('known access retains anonymous, contact and account actions', (
    tester,
  ) async {
    for (final access in [
      'anonymous available',
      'contact required',
      'account required',
    ]) {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(access),
          home: ServicePreviewPage(
            service: {
              'name': 'Known service',
              'group': 'Other',
              'evidence': '$access; optional attachments',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Availability is still being confirmed.'), findsNothing);
      final account = access == 'account required';
      expect(
        find.text(account ? 'Explore demo sign in' : 'Start preview'),
        findsOneWidget,
      );
      await tester.tap(
        find.text(account ? 'Explore demo sign in' : 'Start preview'),
      );
      await tester.pumpAndSettle();
      if (account) {
        expect(find.byType(DemoSignInPage), findsOneWidget);
      } else {
        expect(find.text('Example questions'), findsOneWidget);
      }
    }
  });

  testWidgets(
    'verified dumping callback remains reachable without preview access evidence',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var starts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ServicePreviewPage(
                      service: const {
                        'name': 'Illegal Dumping Item Pickup',
                        'group': 'Other',
                        'evidence': '',
                      },
                      onIllegalDumping: () => starts++,
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
      expect(
        find.text('Continue to report illegal dumping to the City.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Start report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start report'));
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(find.text('Open service'), findsOneWidget);
    },
  );

  testWidgets(
    'existing unknown-access draft resumes without changing its saved data',
    (tester) async {
      const records =
          '[{"id":"unknown-draft","service":"Existing service","group":"Other","evidence":"optional attachments","step":0,"description":"Keep this description","named":false,"photos":0}]';
      SharedPreferences.setMockInitialValues({'service_previews_v1': records});
      await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Existing service'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume draft'));
      await tester.pumpAndSettle();
      expect(find.text('Keep this description'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Availability is still being confirmed.'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'service_previews_v1',
        ),
        records,
      );
    },
  );
}
