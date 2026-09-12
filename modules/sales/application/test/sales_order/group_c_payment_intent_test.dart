import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';

void main() {
  group('TH-05 Group C checkout payment intent validation', () {
    test('S08 SCN-01 reports unpaid when there are no payment intents', () {
      final decision = CheckoutPaymentIntentValidator().validate(
        currencyCode: 'VND',
        amountDue: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        paymentIntents: const <PaymentIntentInput>[],
      );

      expect(decision.totalPaymentIntent.amountMinor, 0);
      expect(decision.remainingAmount.amountMinor, 1000000);
      expect(decision.previewStatus, 'unpaid');
      expect(decision.blockers, isEmpty);
    });

    test('S08 SCN-02 reports partially paid from payment intent total', () {
      final decision = CheckoutPaymentIntentValidator().validate(
        currencyCode: 'VND',
        amountDue: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        paymentIntents: const <PaymentIntentInput>[
          PaymentIntentInput(
            method: SalesPaymentMethod.cash,
            amount: MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
          ),
        ],
      );

      expect(decision.totalPaymentIntent.amountMinor, 400000);
      expect(decision.remainingAmount.amountMinor, 600000);
      expect(decision.previewStatus, 'partially_paid');
      expect(decision.blockers, isEmpty);
    });

    test('S08 SCN-03 reports paid when intents equal amount due', () {
      final decision = CheckoutPaymentIntentValidator().validate(
        currencyCode: 'VND',
        amountDue: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        paymentIntents: const <PaymentIntentInput>[
          PaymentIntentInput(
            method: SalesPaymentMethod.cash,
            amount: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          ),
        ],
      );

      expect(decision.remainingAmount.amountMinor, 0);
      expect(decision.previewStatus, 'paid');
      expect(decision.blockers, isEmpty);
    });

    test('S08 SCN-04 blocks total payment intent above amount due', () {
      final decision = CheckoutPaymentIntentValidator().validate(
        currencyCode: 'VND',
        amountDue: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        paymentIntents: const <PaymentIntentInput>[
          PaymentIntentInput(
            method: SalesPaymentMethod.cash,
            amount: MoneyDto(amountMinor: 1100000, currencyCode: 'VND'),
          ),
        ],
      );

      expect(decision.totalPaymentIntent.amountMinor, 1100000);
      expect(decision.remainingAmount.amountMinor, 0);
      expect(
        decision.blockers.map((blocker) => blocker.code),
        contains('PAYMENT_INTENT_EXCEEDS_AMOUNT_DUE'),
      );
    });

    test('rejects non-positive and currency-mismatched payment intents', () {
      final decision = CheckoutPaymentIntentValidator().validate(
        currencyCode: 'VND',
        amountDue: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        paymentIntents: const <PaymentIntentInput>[
          PaymentIntentInput(
            method: SalesPaymentMethod.cash,
            amount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          ),
          PaymentIntentInput(
            method: SalesPaymentMethod.manualBankTransfer,
            amount: MoneyDto(amountMinor: 100000, currencyCode: 'USD'),
            reference: 'BANK-1',
          ),
        ],
      );

      expect(
        decision.blockers.map((blocker) => blocker.code),
        contains('PAYMENT_INTENT_AMOUNT_INVALID'),
      );
      expect(
        decision.blockers.map((blocker) => blocker.code),
        contains('PAYMENT_INTENT_CURRENCY_MISMATCH'),
      );
    });

    test('allows zero amount due without payment intents', () {
      final decision = CheckoutPaymentIntentValidator().validate(
        currencyCode: 'VND',
        amountDue: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        paymentIntents: const <PaymentIntentInput>[],
      );

      expect(decision.remainingAmount.amountMinor, 0);
      expect(decision.previewStatus, 'paid');
      expect(decision.blockers, isEmpty);
    });

    test('S08 precheck blocks payment intent total above recalculated amount due', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(),
      );

      final result = await service.precheck(
        PrecheckSalesOrderCheckoutQuery(
          storeId: 'store-1',
          currencyCode: 'VND',
          lines: const <CheckoutLineInput>[
            CheckoutLineInput(
              productId: 'product-1',
              productUnitId: 'unit-1',
              quantity: QuantityDto(quantityMicros: QuantityDto.scale),
              unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            ),
          ],
          paymentIntents: const <PaymentIntentInput>[
            PaymentIntentInput(
              method: SalesPaymentMethod.cash,
              amount: MoneyDto(amountMinor: 1100000, currencyCode: 'VND'),
            ),
          ],
        ),
      );

      expect(result.canFinalize, isFalse);
      expect(
        result.blockers.map((blocker) => blocker.code),
        contains(CheckoutBlockerCodes.paymentIntentExceedsAmountDue),
      );
    });
  });
}
