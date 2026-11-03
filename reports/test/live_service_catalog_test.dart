import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Start a Report browses the current City catalog without changing saved Reports',
    (tester) async {
      final savedReports = [
        jsonEncode({
          'createdAt': '2026-10-01T12:00:00.000',
          'description': 'Existing submitted report',
          'latitude': 34.05,
          'longitude': -118.24,
          'state': 'submitted',
          'serviceRequestNumber': 'C-04955177',
        }),
      ];
      SharedPreferences.setMockInitialValues({'reports_v2': savedReports});
      final methods = <String>[];
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/s/');
          return http.Response(
            '"fwuid":"synthetic-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"synthetic-app"}',
            200,
          );
        }
        final form = Uri.splitQueryString(request.body);
        final action = (jsonDecode(form['message']!)['actions'] as List).single;
        expect(action['params']['classname'], 'X11_H_ParentController');
        methods.add(action['params']['method'] as String);
        expect(methods.last, 'fetchInitialDetails');
        expect(action['params']['params'], isEmpty);
        return http.Response(
          jsonEncode({
            'actions': [
              {
                'state': 'SUCCESS',
                'returnValue': {
                  'returnValue': jsonEncode({
                    'isSuccess': true,
                    'response': {
                      'popularCaseList': [],
                      'caseConfigurationList': [
                        {
                          'uxGroup': 'Current City group',
                          'caseConfigurations': [
                            {
                              'uxType': 'Current City service',
                              'uxGroup': 'Current City group',
                              'uxDescription': 'Current City instructions',
                              'caseConfigId': 'session-only-encrypted-id',
                            },
                          ],
                        },
                      ],
                    },
                  }),
                },
              },
            ],
          }),
          200,
        );
      });
      await tester.pumpWidget(
        ReportApp(
          client: PortalSubmissionClient(httpClient: client),
          store: const LocalReportStore(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start a report'));
      await tester.tap(find.text('Start a report'));
      await tester.pumpAndSettle();

      expect(find.text('Current City group'), findsOneWidget);
      await tester.tap(find.text('Current City group'));
      await tester.pumpAndSettle();
      expect(find.text('Current City service'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(methods, ['fetchInitialDetails']);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getStringList('reports_v2'), savedReports);
      expect(
        preferences.getKeys().any((key) => key.contains('catalog')),
        isFalse,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
