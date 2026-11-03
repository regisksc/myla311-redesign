import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:reports/features/report/data/portal_submission_client.dart';

class _FailingCatalogTransport extends http.BaseClient {
  final failure = StateError('Catalog transport sentinel');
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw failure;
  }

  @override
  void close() {
    closed = true;
  }
}

void main() {
  test('catalog read closes its owned transport when the read fails', () async {
    final transport = _FailingCatalogTransport();

    await http.runWithClient(
      () => expectLater(
        PortalSubmissionClient().loadServiceCatalog(),
        throwsA(same(transport.failure)),
      ),
      () => transport,
    );

    expect(transport.closed, isTrue);
  });
}
