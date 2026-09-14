import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';

void main() {
  group('TH-05 Group C receivable requirement decisioning', () {
    test('S10 SCN-01 allows partial payment for eligible identified customer', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(),
        receivablePolicy: FakeCheckoutReceivablePolicyPort(),
      );

      final result = await service.precheck(_query(paymentMinor: 400000));

      expect(result.canFinalize, isTrue);
      expect(result.receivableRequirement.isRequired, isTrue);
      expect(result.receivableRequirement.amount.amountMinor, 600000);
      expect(result.receivableRequirement.customerId, 'customer-1');
    });

    test('S10 SCN-02 allows no payment for eligible identified customer', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(),
        receivablePolicy: FakeCheckoutReceivablePolicyPort(),
      );

      final result = await service.precheck(_query(paymentMinor: 0));

      expect(result.canFinalize, isTrue);
      expect(result.receivableRequirement.isRequired, isTrue);
      expect(result.receivableRequirement.amount.amountMinor, 1000000);
    });

    test('S10 SCN-03 blocks walk-in customer when outstanding remains', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(),
        receivablePolicy: FakeCheckoutReceivablePolicyPort(),
      );

      final result = await service.precheck(
        _query(customerId: null, paymentMinor: 400000),
      );

      expect(result.canFinalize, isFalse);
      expect(
        result.blockers.map((blocker) => blocker.code),
        contains('WALK_IN_RECEIVABLE_BLOCKED'),
      );
      expect(result.receivableRequirement.isRequired, isTrue);
      expect(result.receivableRequirement.customerId, isNull);
    });

    test('S10 SCN-04 blocks customer or actor not eligible for receivable', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(),
        receivablePolicy: FakeCheckoutReceivablePolicyPort.notEligible(),
      );

      final result = await service.precheck(_query(paymentMinor: 400000));

      expect(result.canFinalize, isFalse);
      expect(result.blockers.map((blocker) => blocker.code), contains('RECEIVABLE_NOT_ALLOWED'));
    });

    test(
      'S10 SCN-05 blocks due-date-required policy because frozen query has no due-date field',
      () async {
        final service = CheckoutPrecheckService(
          referencePrecheck: FakeCheckoutReferencePrecheckPort(),
          receivablePolicy: FakeCheckoutReceivablePolicyPort.requiresDueDate(),
        );

        final result = await service.precheck(_query(paymentMinor: 400000));

        expect(result.canFinalize, isFalse);
        expect(
          result.blockers.map((blocker) => blocker.code),
          contains('RECEIVABLE_DUE_DATE_REQUIRED'),
        );
      },
    );

    test('S10 SCN-05b passes supplied receivable due date to policy', () async {
      final policy = _RecordingReceivablePolicy();
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(),
        receivablePolicy: policy,
      );

      final result = await service.precheck(
        _query(paymentMinor: 400000, paymentDueDate: DateTime(2026, 8, 30)),
      );

      expect(result.canFinalize, isTrue);
      expect(policy.lastDueDate, DateTime(2026, 8, 30));
    });

    test('S10 SCN-06 does not require receivable when order is fully paid', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(),
        receivablePolicy: FakeCheckoutReceivablePolicyPort.notEligible(),
      );

      final result = await service.precheck(_query(paymentMinor: 1000000));

      expect(result.canFinalize, isTrue);
      expect(result.receivableRequirement.isRequired, isFalse);
      expect(result.receivableRequirement.amount.amountMinor, 0);
      expect(result.blockers, isEmpty);
    });
  });
}

PrecheckSalesOrderCheckoutQuery _query({
  String? customerId = 'customer-1',
  required int paymentMinor,
  DateTime? paymentDueDate,
}) {
  return PrecheckSalesOrderCheckoutQuery(
    storeId: 'store-1',
    customerId: customerId,
    currencyCode: 'VND',
    paymentDueDate: paymentDueDate,
    lines: const <CheckoutLineInput>[
      CheckoutLineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
    ],
    paymentIntents: <PaymentIntentInput>[
      if (paymentMinor > 0)
        PaymentIntentInput(
          method: SalesPaymentMethod.cash,
          amount: MoneyDto(amountMinor: paymentMinor, currencyCode: 'VND'),
        ),
    ],
  );
}

final class _RecordingReceivablePolicy implements ICheckoutReceivablePolicyPort {
  DateTime? lastDueDate;

  @override
  Future<CheckoutReceivablePolicyDecision> evaluate({
    required String storeId,
    required String customerId,
    required MoneyDto outstanding,
    DateTime? dueDate,
  }) async {
    lastDueDate = dueDate;
    return CheckoutReceivablePolicyDecision(
      allowed: true,
      requiresDueDate: false,
      blockers: const <SalesBlockerDto>[],
    );
  }
}
