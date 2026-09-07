import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_classifier.dart';
import 'package:vet45_misa/e_invoice.dart';

void main() {
  group('MeInvoiceDeliveryClassifier', () {
    test('matched status 3 without error maps to Succeeded', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.ok([
          MeInvoiceSendEmailResultItem(
            transactionId: 'tx-1',
            sendEmailStatus: 3,
          ),
        ]),
      );

      expect(outcome, isA<DeliveryProviderSucceeded>());
    });

    for (final status in [0, 1, 2, 3, 4, 99, null]) {
      test(
        'status $status is classified without assuming acceptance is sent',
        () {
          final outcome = MeInvoiceDeliveryClassifier.classify(
            MeInvoiceResult.ok([
              MeInvoiceSendEmailResultItem(
                transactionId: 'tx-1',
                sendEmailStatus: status,
              ),
            ]),
            transactionId: 'tx-1',
          );
          expect(
            outcome,
            status == 3
                ? isA<DeliveryProviderSucceeded>()
                : status == 2
                ? isA<DeliveryProviderDefiniteFailure>()
                : isA<DeliveryProviderUndetermined>(),
          );
        },
      );
    }
    for (final items in [
      <MeInvoiceSendEmailResultItem>[],
      [
        const MeInvoiceSendEmailResultItem(
          transactionId: 'wrong',
          sendEmailStatus: 3,
        ),
      ],
      [
        const MeInvoiceSendEmailResultItem(
          transactionId: 'tx-1',
          sendEmailStatus: 3,
          errorCode: 'InvalidData',
        ),
      ],
      [
        const MeInvoiceSendEmailResultItem(
          transactionId: 'tx-1',
          sendEmailStatus: 3,
        ),
        const MeInvoiceSendEmailResultItem(
          transactionId: 'tx-1',
          sendEmailStatus: 2,
        ),
      ],
    ]) {
      test('ambiguous per-invoice results are undetermined $items', () {
        expect(
          MeInvoiceDeliveryClassifier.classify(
            MeInvoiceResult.ok(items),
            transactionId: 'tx-1',
          ),
          isA<DeliveryProviderUndetermined>(),
        );
      });
    }

    test('auth credential rejection maps to DefiniteFailure', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed('missing_MISA_MEINVOICE_APP_ID'),
      );

      expect(outcome, isA<DeliveryProviderDefiniteFailure>());
      expect(
        (outcome as DeliveryProviderDefiniteFailure).safeErrorCode,
        'PROVIDER_AUTH_FAILED',
      );
    });

    test('TokenExpiredCode maps to DefiniteFailure', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed('TokenExpiredCode'),
      );

      expect(outcome, isA<DeliveryProviderDefiniteFailure>());
      expect(
        (outcome as DeliveryProviderDefiniteFailure).safeErrorCode,
        'PROVIDER_AUTH_FAILED',
      );
    });

    test(
      'validation business rejection maps to DefiniteFailure with safe code',
      () {
        final outcome = MeInvoiceDeliveryClassifier.classify(
          transactionId: 'tx-1',
          const MeInvoiceResult.failed(
            'InvalidData: raw vendor message with secrets',
          ),
        );

        expect(outcome, isA<DeliveryProviderDefiniteFailure>());
        final failure = outcome as DeliveryProviderDefiniteFailure;
        expect(failure.safeErrorCode, 'InvalidData');
        expect(failure.safeErrorCode, isNot(contains('secrets')));
      },
    );

    test('429 rateLimited before acceptance maps to RetryableFailure', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed(
          'meinvoice_429_rate_limited',
          rateLimited: true,
        ),
      );

      expect(outcome, isA<DeliveryProviderRetryableFailure>());
      expect(
        (outcome as DeliveryProviderRetryableFailure).safeErrorCode,
        'meinvoice_429_rate_limited',
      );
    });

    test('timeout maps to Undetermined', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed('meinvoice_network_timeout'),
      );

      expect(outcome, isA<DeliveryProviderUndetermined>());
    });

    test('connection loss maps to Undetermined', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed('meinvoice_network: connection reset'),
      );

      expect(outcome, isA<DeliveryProviderUndetermined>());
    });

    test('5xx maps to Undetermined', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed('meinvoice_5xx'),
      );

      expect(outcome, isA<DeliveryProviderUndetermined>());
    });

    test('malformed response maps to Undetermined', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed(
          'meinvoice_invalid_response: not a json object',
        ),
      );

      expect(outcome, isA<DeliveryProviderUndetermined>());
    });

    test('unknown provider codes default to Undetermined never definite', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.failed(
          'WeirdVendorCode: do not treat as definite',
        ),
      );

      expect(outcome, isA<DeliveryProviderUndetermined>());
      expect(
        (outcome as DeliveryProviderUndetermined).safeErrorCode,
        'WeirdVendorCode',
      );
      expect(outcome, isNot(isA<DeliveryProviderDefiniteFailure>()));
    });

    test(
      'codes containing auth/forbidden but not on allowlist stay Undetermined',
      () {
        for (final code in [
          'AuthorizationPending',
          'ForbiddenThing',
          'auth_soft_fail',
          'reauth_required_hint',
        ]) {
          final outcome = MeInvoiceDeliveryClassifier.classify(
            transactionId: 'tx-1',
            MeInvoiceResult.failed(code),
          );

          expect(
            outcome,
            isA<DeliveryProviderUndetermined>(),
            reason: '$code must not become DefiniteFailure via substring',
          );
          expect(outcome, isNot(isA<DeliveryProviderDefiniteFailure>()));
        }
      },
    );

    test(
      'wrapped meinvoice_401: UnAuthorize maps via closed vendor-token allowlist',
      () {
        final outcome = MeInvoiceDeliveryClassifier.classify(
          transactionId: 'tx-1',
          const MeInvoiceResult.failed('meinvoice_401: UnAuthorize'),
        );

        expect(outcome, isA<DeliveryProviderDefiniteFailure>());
        expect(
          (outcome as DeliveryProviderDefiniteFailure).safeErrorCode,
          'PROVIDER_AUTH_FAILED',
        );
      },
    );

    test('success with unexpected data shape is Undetermined', () {
      final outcome = MeInvoiceDeliveryClassifier.classify(
        transactionId: 'tx-1',
        const MeInvoiceResult.ok(<MeInvoiceSendEmailResultItem>[]),
      );

      expect(outcome, isA<DeliveryProviderUndetermined>());
    });
  });
}
