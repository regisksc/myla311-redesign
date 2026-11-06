import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/application/report_flow_controller.dart';
import 'package:reports/features/report/application/report_store.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';

import 'support/native_app_test_support.dart';

void main() {
  test(
    'resumed service details survive saving and a rejected attempt',
    () async {
      final store = MemoryReportStore();
      final controller = ReportFlowController(
        store: store,
        client: _Client(),
        draft: ReportDraft(
          createdAt: DateTime(2026, 11, 6),
          requestType: 'Barricade Removal',
          serviceAnswers: {'a3Teq0000003J5XEAU': 'Street'},
          latitude: 34,
          longitude: -118,
          debrisLocation: 'Curb',
          quantity: '1',
          flowVersion: 2,
          contact: const ReportContact(anonymous: true),
        ),
      );
      addTearDown(controller.dispose);
      await controller.checkSavedAttempts();
      await controller.persistDraft();
      await controller.submit();
      final draft = await store.loadDraft();
      final retry = (await store.loadReports()).single;

      expect(
        {
          'draftType': draft?.requestType,
          'draftAnswers': draft?.serviceAnswers,
          'retryType': retry.requestType,
          'retryAnswers': retry.serviceAnswers,
          'retryState': retry.state,
        },
        {
          'draftType': 'Barricade Removal',
          'draftAnswers': {'a3Teq0000003J5XEAU': 'Street'},
          'retryType': 'Barricade Removal',
          'retryAnswers': {'a3Teq0000003J5XEAU': 'Street'},
          'retryState': ReportState.notSent,
        },
      );
    },
  );

  test(
    'named contact survives rejected attempt and remains available for retry',
    () async {
      final store = _Store();
      final client = _Client();
      final controller = ReportFlowController(
        store: store,
        client: client,
        draft: ReportDraft(
          createdAt: DateTime(2026),
          latitude: 34,
          longitude: -118,
          description: 'Couch',
          debrisLocation: 'Curb',
          quantity: '1',
          step: 5,
          flowVersion: 2,
          contact: const ReportContact(
            anonymous: false,
            firstName: 'Ada',
            lastName: 'Jones',
            email: 'ada@example.com',
          ),
        ),
      );
      await controller.checkSavedAttempts();
      expect(controller.canSubmit, true);
      await controller.submit();
      expect(client.sent!.contact!.email, 'ada@example.com');
      expect(store.replacement!.contact!.email, 'ada@example.com');
      expect(controller.savedDraft!.contact!.firstName, 'Ada');
      controller.dispose();
    },
  );
  test('anonymous submission strips any retained named details', () async {
    final store = _Store();
    final client = _Client();
    final controller = ReportFlowController(
      store: store,
      client: client,
      draft: ReportDraft(
        createdAt: DateTime(2026),
        latitude: 34,
        longitude: -118,
        description: 'Couch',
        debrisLocation: 'Curb',
        quantity: '1',
        step: 5,
        flowVersion: 2,
        contact: const ReportContact(
          anonymous: true,
          firstName: 'Ada',
          email: 'ada@example.com',
        ),
      ),
    );
    await controller.checkSavedAttempts();
    await controller.submit();
    expect(client.sent!.contact!.firstName, '');
    expect(store.replacement!.contact!.email, '');
    controller.dispose();
  });
  test(
    'optional description does not prevent continuing or submitting',
    () async {
      final controller = ReportFlowController(
        store: _Store(),
        client: _Client(),
        draft: ReportDraft(
          createdAt: DateTime(2026),
          latitude: 34,
          longitude: -118,
          debrisLocation: 'Curb',
          quantity: '1',
          step: 3,
          flowVersion: 2,
          contact: const ReportContact(anonymous: true),
        ),
      );
      await controller.checkSavedAttempts();
      expect(controller.canContinue, true);
      expect(controller.canSubmit, true);
      controller.dispose();
    },
  );
  test('invalid email cannot be used as named contact', () async {
    final controller = ReportFlowController(
      store: _Store(),
      client: _Client(),
      draft: ReportDraft(
        createdAt: DateTime(2026),
        latitude: 34,
        longitude: -118,
        debrisLocation: 'Curb',
        quantity: '1',
        step: 4,
        flowVersion: 2,
        contact: const ReportContact(
          anonymous: false,
          firstName: 'Ada',
          lastName: 'Jones',
          email: 'a@',
        ),
      ),
    );
    await controller.checkSavedAttempts();
    expect(controller.canContinue, false);
    expect(controller.canSubmit, false);
    expect(controller.contactEmailError, 'Enter a valid email address.');
    controller.dispose();
  });
}

class _Client implements SubmissionClient {
  Report? sent;
  @override
  Future<SubmissionResult> send(Report report) async {
    sent = report;
    return SubmissionFailed(SubmissionFailureKind.rejected, 'Rejected');
  }
}

class _Store implements ReportStore {
  Report? replacement;
  @override
  Future<ReportDraft?> loadDraft() async => null;
  @override
  Future<void> saveDraft(ReportDraft draft) async {}
  @override
  Future<List<Report>> loadReports() async => [];
  @override
  Future<void> saveReport(Report report) async {}
  @override
  Future<void> replaceReport(Report before, Report after) async {
    replacement = after;
  }

  @override
  Future<void> discardDraft(DateTime createdAt) async {}
  @override
  Future<void> removeLocalReceipt(Report receipt) async {}
}
