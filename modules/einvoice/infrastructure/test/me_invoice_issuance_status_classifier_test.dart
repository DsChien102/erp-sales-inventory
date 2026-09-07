import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_issuance_status_classifier.dart';
import 'package:vet45_misa/e_invoice.dart';

void main() {
  group('MeInvoiceIssuanceStatusClassifier', () {
    test(
      'provider issued status (PublishStatus == 1) becomes typed success',
      () {
        final status = MeInvoiceInvoiceStatus(
          refId: 'ref-1',
          transactionId: 'tx-1',
          invSeries: '1C26TVE',
          invNo: '00000123',
          publishStatus: 1,
          publishedTime: DateTime.utc(2026, 8, 28, 10, 0),
        );
        final outcome = MeInvoiceIssuanceStatusClassifier.classify(
          statusResult: MeInvoiceResult.ok([status]),
          idempotencyKey: 'ref-1',
          payloadHash: 'hash-1',
        );

        expect(outcome, isA<MeInvoiceIssuanceStatusSuccess>());
        final success = outcome as MeInvoiceIssuanceStatusSuccess;
        expect(success.evidence.providerReference, 'tx-1');
        expect(success.evidence.invoiceNumber, '00000123');
        expect(success.evidence.invoiceSeries, '1C26TVE');
        expect(success.evidence.idempotencyKey, 'ref-1');
        expect(success.evidence.payloadHash, 'hash-1');
        expect(success.evidence.issuedAt, DateTime.utc(2026, 8, 28, 10, 0));
      },
    );

    test(
      'provider processing/pending status (PublishStatus != 1 && no terminal rejection) remains pending',
      () {
        final status = MeInvoiceInvoiceStatus(
          refId: 'ref-1',
          transactionId: 'tx-1',
          publishStatus: 0,
        );
        final outcome = MeInvoiceIssuanceStatusClassifier.classify(
          statusResult: MeInvoiceResult.ok([status]),
          idempotencyKey: 'ref-1',
          payloadHash: 'hash-1',
        );

        expect(outcome, isA<MeInvoiceIssuanceStatusPending>());
      },
    );

    test('empty status data list becomes pending/undetermined', () {
      final outcome = MeInvoiceIssuanceStatusClassifier.classify(
        statusResult: const MeInvoiceResult.ok(<MeInvoiceInvoiceStatus>[]),
        idempotencyKey: 'ref-1',
        payloadHash: 'hash-1',
      );

      expect(outcome, isA<MeInvoiceIssuanceStatusUndetermined>());
    });

    test(
      'transport error or timeout is undetermined, NEVER definite failure',
      () {
        final outcomeTimeout = MeInvoiceIssuanceStatusClassifier.classify(
          statusResult: const MeInvoiceResult.failed(
            'meinvoice_network_timeout',
          ),
          idempotencyKey: 'ref-1',
          payloadHash: 'hash-1',
        );
        expect(outcomeTimeout, isA<MeInvoiceIssuanceStatusUndetermined>());

        final outcome5xx = MeInvoiceIssuanceStatusClassifier.classify(
          statusResult: const MeInvoiceResult.failed('meinvoice_5xx'),
          idempotencyKey: 'ref-1',
          payloadHash: 'hash-1',
        );
        expect(outcome5xx, isA<MeInvoiceIssuanceStatusUndetermined>());
      },
    );

    test(
      'terminal rejection error code in result maps to definite failure',
      () {
        final outcome = MeInvoiceIssuanceStatusClassifier.classify(
          statusResult: const MeInvoiceResult.failed(
            'InvalidInvSeries: Invalid series',
          ),
          idempotencyKey: 'ref-1',
          payloadHash: 'hash-1',
        );

        expect(outcome, isA<MeInvoiceIssuanceStatusDefiniteFailure>());
        final failure = outcome as MeInvoiceIssuanceStatusDefiniteFailure;
        expect(failure.evidence.providerCode, 'InvalidInvSeries');
        expect(failure.evidence.providerMessage, 'Invalid series');
      },
    );
  });
}
