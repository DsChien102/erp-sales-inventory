import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vet45_misa/e_invoice.dart';

Future<MeInvoiceResult<List<MeInvoiceSendEmailResultItem>>> send(
  Map<String, Object?> envelope,
) {
  final client = MeInvoiceClient(
    config: MeInvoiceConfig(
      baseUrl: 'https://example.test/api/integration',
      accessToken: 'test-token',
      accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    ),
    httpClient: MockClient((request) async => http.Response(jsonEncode(envelope), 200)),
  );
  return client.sendEmail(
    const MeInvoiceSendEmailRequest(
      sendEmailDatas: [MeInvoiceSendEmailData(transactionId: 'tx')],
      isInvoiceCode: true,
      isInvoiceCalculatingMachine: false,
    ),
  );
}

void main() {
  for (final encoded in [false, true]) {
    for (final status in [0, 1, 2, 3, 4]) {
      test('preserves status $status and references in encoded=$encoded data', () async {
        final data = [
          {
            'TransactionID': 'tx',
            'RefID': 'ref',
            'RefDetailID': 'detail',
            'SendEmailStatus': status,
            'ErrorCode': '',
          },
        ];
        final result = await send({'success': true, 'data': encoded ? jsonEncode(data) : data});
        expect(result.isSuccess, isTrue);
        expect(result.data!.single.transactionId, 'tx');
        expect(result.data!.single.refId, 'ref');
        expect(result.data!.single.refDetailId, 'detail');
        expect(result.data!.single.sendEmailStatus, status);
        expect(result.data!.single.errorCode, '');
      });
    }
  }
  for (final data in [
    null,
    true,
    [],
    '{}',
    '[',
    [42],
    [
      {'TransactionID': 'tx', 'SendEmailStatus': 3.4},
    ],
    [
      {'TransactionID': 12, 'SendEmailStatus': 3},
    ],
  ]) {
    test('malformed data cannot become successful: $data', () async {
      final result = await send({'success': true, 'data': data});
      expect(result.isSuccess, isFalse);
      expect(result.error, 'meinvoice_send_email_invalid_response');
    });
  }
  test('false envelope with status 3 is not successful', () async {
    final result = await send({
      'success': false,
      'data': [
        {'TransactionID': 'tx', 'SendEmailStatus': 3},
      ],
    });
    expect(result.isSuccess, isFalse);
  });
  test('envelope errors with status 3 are not successful', () async {
    final result = await send({
      'success': true,
      'errors': ['rejected'],
      'data': [
        {'TransactionID': 'tx', 'SendEmailStatus': 3},
      ],
    });
    expect(result.isSuccess, isFalse);
  });
}
