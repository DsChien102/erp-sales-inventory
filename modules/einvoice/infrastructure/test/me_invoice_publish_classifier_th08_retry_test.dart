import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_publish_classifier.dart';
import 'package:vet45_misa/e_invoice.dart';

void main() {
  group('th08_hardening_retry — MeInvoicePublishClassifier table', () {
    const canonical = {'invDate': '2026-08-01'};

    test('InvoiceNumberNotCotinuous is retryable provider rejection', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-continuous',
        result: MeInvoiceResult.ok([
          const MeInvoicePublishInvoiceResultItem(
            refId: 'key-continuous',
            errorCode: MeInvoicePublishErrorCodes.invoiceNumberNotContinuous,
            descriptionErrorCode: 'gap in series',
          ),
        ]),
        canonicalInvoice: canonical,
      );

      expect(outcome, isA<MeInvoicePublishRetryableRejection>());
      final retry = outcome as MeInvoicePublishRetryableRejection;
      expect(
        retry.providerCode,
        MeInvoicePublishErrorCodes.invoiceNumberNotContinuous,
      );
      expect(retry.retryAfter, const Duration(seconds: 5));
    });

    test('InvoiceDuplicated is reconcile-first undetermined', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-dup',
        result: MeInvoiceResult.ok([
          const MeInvoicePublishInvoiceResultItem(
            refId: 'key-dup',
            errorCode: MeInvoicePublishErrorCodes.invoiceDuplicated,
          ),
        ]),
        canonicalInvoice: canonical,
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        PublishUndeterminedReasonCodes.invoiceDuplicatedReconcileFirst,
      );
    });

    test('DuplicateInvoiceRefID stays reconciliation-only undetermined', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-ref',
        result: MeInvoiceResult.ok([
          MeInvoicePublishInvoiceResultItem(
            refId: 'key-ref',
            transactionId: 'tx-1',
            invNo: '0000001',
            errorCode: MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
          ),
        ]),
        canonicalInvoice: canonical,
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        PublishUndeterminedReasonCodes.duplicateInvoiceRefId,
      );
    });

    test('transport timeout stays undetermined not retryable rejection', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-timeout',
        result: const MeInvoiceResult.failed('meinvoice_network_timeout'),
        canonicalInvoice: canonical,
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        'PROVIDER_TIMEOUT',
      );
    });
  });
}
