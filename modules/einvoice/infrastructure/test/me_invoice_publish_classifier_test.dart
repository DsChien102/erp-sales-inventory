import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_publish_classifier.dart';
import 'package:vet45_misa/e_invoice.dart';

void main() {
  group('MeInvoicePublishClassifier', () {
    test('classifies InvalidInvSeries as definiteFailure', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: MeInvoiceResult.ok([
          const MeInvoicePublishInvoiceResultItem(
            refId: 'key-1',
            errorCode: 'InvalidInvSeries',
            descriptionErrorCode: 'bad series',
          ),
        ]),
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
    });

    test('classifies DuplicateInvoiceRefID as undetermined', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: MeInvoiceResult.ok([
          MeInvoicePublishInvoiceResultItem(
            refId: 'key-1',
            transactionId: 'tx-1',
            invNo: '0000001',
            errorCode: MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
          ),
        ]),
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        'DUPLICATE_INVOICE_REF_ID',
      );
    });

    test('classifies HTTP client InvalidInvSeries response', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode({'Success': true, 'Data': 'tok'}),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'publishInvoiceResult': [
              {
                'RefID': 'key-1',
                'ErrorCode': 'InvalidInvSeries',
                'DescriptionErrorCode': 'bad series',
              },
            ],
          }),
          200,
        );
      });

      final client = MeInvoiceClient(
        config: const MeInvoiceConfig(
          baseUrl: 'https://meinvoice-test.misa.vn',
          appId: 'app',
          taxCode: '0100000000',
          username: 'user',
          password: 'secret',
        ),
        httpClient: httpClient,
      );

      final result = await client.publish(
        MeInvoicePublishRequest(
          signType: MeInvoiceSignType.hsmWithCks,
          invoiceData: const [
            MeInvoiceInvoiceData(refId: 'key-1', invSeries: '1C25TYY'),
          ],
        ),
      );

      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: result,
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
    });
  });
}
