import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';

const motionReceipt = 'SYNTHETIC-MOTION-01';
const motionStore = LocalReportStore();

ReportDraft motionReviewDraft({DateTime? createdAt}) => ReportDraft(
  createdAt: createdAt ?? DateTime(2026, 10, 29, 12),
  latitude: 34.052235,
  longitude: -118.243683,
  debrisLocation: 'Curb',
  quantity: '2',
  description: 'Controlled motion verification, no City write',
  step: 4,
);

class ControlledMotionPortal {
  final acceptance = Completer<void>();
  int submissions = 0;
  Map<String, dynamic>? submittedAction;

  late final client = PortalSubmissionClient(httpClient: MockClient(_reply));

  Future<http.Response> _reply(http.Request request) async {
    if (request.method == 'GET') {
      return http.Response(
        '<script>{"fwuid":"synthetic-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"synthetic-app"}}</script>',
        200,
      );
    }
    final action =
        (jsonDecode(Uri.splitQueryString(request.body)['message']!)['actions']
                    as List)
                .single
            as Map<String, dynamic>;
    final method = action['params']['method'];
    if (method == 'submitCase') {
      submissions++;
      submittedAction = action;
      await acceptance.future;
    }
    final response = switch (method) {
      'fetchInitialDetails' => {
        'popularCaseList': [
          {
            'uxType': 'Illegal Dumping Item Pickup',
            'caseConfigId': 'synthetic-type',
          },
        ],
      },
      'fetchCaseTypeDetails' => {
        'objCaseConfigWrapper': {
          'sCaseType': 'Illegal Dumping Item Pickup',
          'sCasePriority': 'Normal',
          'sCaseDefaultStatus': 'New',
          'lstCaseQuestion': [
            for (final field in [
              'Description',
              'Location_of_Loose_Miscellaneous_Debris__c',
              'No_of_Loose_Miscellaneous_Debris__c',
            ])
              {'sFieldtoUpdate': field},
          ],
        },
        'contactWrapperResponse': {'bIsLogin': false},
      },
      'validateAddress' => jsonEncode({
        'address': {
          'ShortLabel': 'SYNTHETIC CURB',
          'City': 'LOS ANGELES',
          'X': -118.243683,
          'Y': 34.052235,
        },
        'location': {'x': -118.243683, 'y': 34.052235},
      }),
      'submitCase' => {'sCaseNumber': motionReceipt},
      _ => throw StateError('Unexpected controlled Portal method $method'),
    };
    return http.Response(
      jsonEncode({
        'actions': [
          {
            'state': 'SUCCESS',
            'returnValue': {
              'returnValue': jsonEncode({
                'isSuccess': true,
                'message': 'Controlled response',
                'response': response,
              }),
            },
          },
        ],
      }),
      200,
    );
  }
}

Future<void> main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  if (await motionStore.loadDraft() != null) {
    throw StateError(
      'Use a dedicated QA installation without an existing draft',
    );
  }
  await motionStore.saveDraft(motionReviewDraft(createdAt: DateTime.now()));
  final portal = ControlledMotionPortal();
  portal.acceptance.complete();
  runApp(ReportApp(client: portal.client));
}
