import 'package:test/test.dart';
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_sales_domain/enums.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('SalesOrderCancellation', () {
    test('confirms with normalized reason and authoritative zero-net snapshot', () {
      final cancellation = SalesOrderCancellation.request(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
      );
      final precheck = CancellationPrecheckSnapshot(
        passed: true,
        sourceOrderVersion: 7,
        sourceSettlementVersion: 3,
        netConfirmedCollectionMinor: 0,
        blockerCodes: const <String>[],
      );

      cancellation.confirm(
        precheck: precheck,
        reason: CancellationReason.create(
          reasonText: ' Khách yêu cầu hủy ',
        ),
        actorId: 'actor-1',
        confirmedAt: DateTime.utc(2026, 8, 10),
      );

      expect(cancellation.status, SalesOrderCancellationStatus.confirmed);
      expect(cancellation.reason?.text, 'Khách yêu cầu hủy');
      expect(cancellation.lastPrecheck, same(precheck));
      expect(cancellation.confirmedBy, 'actor-1');
    });

    test('rejects confirmation when net confirmed collection is positive', () {
      final cancellation = SalesOrderCancellation.request(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
      );

      expect(
        () => cancellation.confirm(
          precheck: CancellationPrecheckSnapshot(
            passed: true,
            sourceOrderVersion: 7,
            sourceSettlementVersion: 3,
            netConfirmedCollectionMinor: 1,
          ),
          reason: CancellationReason.create(
            reasonText: '',
          ),
          actorId: 'actor-1',
          confirmedAt: DateTime.utc(2026, 8, 10),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('normalizes optional cancellation reason', () {
      expect(CancellationReason.create().text, isEmpty);
      expect(CancellationReason.create(reasonText: '   ').text, isEmpty);
      expect(CancellationReason.create(reasonText: ' Khách đổi ý ').text, 'Khách đổi ý');
    });

    test('blocked precheck marks cancellation blocked without confirmation', () {
      final cancellation = SalesOrderCancellation.request(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
      );
      final precheck = CancellationPrecheckSnapshot(
        passed: false,
        sourceOrderVersion: 7,
        sourceSettlementVersion: 3,
        netConfirmedCollectionMinor: 0,
        blockerCodes: const <String>['PAYMENT_ALREADY_COLLECTED'],
      );

      cancellation.confirm(
        precheck: precheck,
        reason: CancellationReason.create(
          reasonText: '',
        ),
        actorId: 'actor-1',
        confirmedAt: DateTime.utc(2026, 8, 10),
      );

      expect(cancellation.status, SalesOrderCancellationStatus.blocked);
      expect(cancellation.reason, isNull);
      expect(cancellation.confirmedBy, isNull);
      expect(cancellation.lastPrecheck, same(precheck));
    });

    test('rejects complete from requested status', () {
      final cancellation = SalesOrderCancellation.request(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
      );

      expect(
        () => cancellation.complete(),
        throwsA(isA<DomainException>()),
      );
    });

    test('completed cancellation has no reopen transition', () {
      final cancellation = SalesOrderCancellation.request(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
      );
      cancellation.confirm(
        precheck: CancellationPrecheckSnapshot(
          passed: true,
          sourceOrderVersion: 7,
          sourceSettlementVersion: 3,
          netConfirmedCollectionMinor: 0,
        ),
        reason: CancellationReason.create(
          reasonText: '',
        ),
        actorId: 'actor-1',
        confirmedAt: DateTime.utc(2026, 8, 10),
      );
      cancellation.markProcessing();
      cancellation.complete();

      expect(cancellation.status, SalesOrderCancellationStatus.completed);
      expect(
        () => cancellation.confirm(
          precheck: CancellationPrecheckSnapshot(
            passed: true,
            sourceOrderVersion: 7,
            sourceSettlementVersion: 3,
            netConfirmedCollectionMinor: 0,
          ),
          reason: CancellationReason.create(
            reasonText: '',
          ),
          actorId: 'actor-1',
          confirmedAt: DateTime.utc(2026, 8, 11),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('ReturnExchangeSettlementPlan', () {
    test('positive difference balances collect and receivable create', () {
      final plan = ReturnExchangeSettlementPlan.create(
        netDifferenceMinor: 100000,
        currencyCode: 'VND',
        collectAmount: Money(amountMinor: 40000, currencyCode: 'VND'),
        refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableCreateAmount: Money(amountMinor: 60000, currencyCode: 'VND'),
        receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
      );
      expect(plan.collectAmount.amountMinor, 40000);
      expect(plan.receivableCreateAmount.amountMinor, 60000);
    });

    test('rejects a plan that double counts customer obligation', () {
      expect(
        () => ReturnExchangeSettlementPlan.create(
          netDifferenceMinor: 100000,
          currencyCode: 'VND',
          collectAmount: Money(amountMinor: 100000, currencyCode: 'VND'),
          refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableCreateAmount: Money(amountMinor: 100000, currencyCode: 'VND'),
          receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('negative difference balances refund and receivable reverse', () {
      final plan = ReturnExchangeSettlementPlan.create(
        netDifferenceMinor: -80000,
        currencyCode: 'VND',
        collectAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        refundAmount: Money(amountMinor: 30000, currencyCode: 'VND'),
        receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableReverseAmount: Money(amountMinor: 50000, currencyCode: 'VND'),
      );
      expect(plan.refundAmount.amountMinor, 30000);
      expect(plan.receivableReverseAmount.amountMinor, 50000);
    });

    test('zero difference requires every component zero', () {
      final plan = ReturnExchangeSettlementPlan.create(
        netDifferenceMinor: 0,
        currencyCode: 'VND',
        collectAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
      );
      expect(plan.isBalanced, isTrue);

      expect(
        () => ReturnExchangeSettlementPlan.create(
          netDifferenceMinor: 0,
          currencyCode: 'VND',
          collectAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          refundAmount: Money(amountMinor: 1, currencyCode: 'VND'),
          receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('accepts mixed valid positive and negative plans', () {
      final positiveOnlyCollect = ReturnExchangeSettlementPlan.create(
        netDifferenceMinor: 25000,
        currencyCode: 'VND',
        collectAmount: Money(amountMinor: 25000, currencyCode: 'VND'),
        refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
      );
      expect(positiveOnlyCollect.collectAmount.amountMinor, 25000);

      final negativeOnlyReverse = ReturnExchangeSettlementPlan.create(
        netDifferenceMinor: -15000,
        currencyCode: 'VND',
        collectAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        receivableReverseAmount: Money(amountMinor: 15000, currencyCode: 'VND'),
      );
      expect(negativeOnlyReverse.receivableReverseAmount.amountMinor, 15000);
    });

    test('rejects cross-currency components', () {
      expect(
        () => ReturnExchangeSettlementPlan.create(
          netDifferenceMinor: 100000,
          currencyCode: 'VND',
          collectAmount: Money(amountMinor: 100000, currencyCode: 'USD'),
          refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('rejects negative component amounts', () {
      expect(
        () => ReturnExchangeSettlementPlan.create(
          netDifferenceMinor: 100000,
          currencyCode: 'VND',
          collectAmount: Money(amountMinor: -1, currencyCode: 'VND'),
          refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('SalesOrderReturnStatusCalculator', () {
    const calculator = SalesOrderReturnStatusCalculator();

    test('full return status is independent from order lifecycle', () {
      expect(
        calculator.calculate(
          totalSoldMicros: 2000000,
          totalCompletedReturnedMicros: 2000000,
        ),
        SalesOrderReturnStatus.fullyReturned,
      );
      // Return-status projection is a separate concept from SalesOrder lifecycle.
      expect(
        SalesOrderLifecycleStatus.values.contains(SalesOrderLifecycleStatus.completed),
        isTrue,
      );
      expect(
        SalesOrderLifecycleStatus.values.map((e) => e.name),
        isNot(contains('fullyReturned')),
      );
    });

    test('same completed quantities calculate partiallyReturned or fullyReturned', () {
      expect(
        calculator.calculate(
          totalSoldMicros: 2000000,
          totalCompletedReturnedMicros: 0,
        ),
        SalesOrderReturnStatus.none,
      );
      expect(
        calculator.calculate(
          totalSoldMicros: 2000000,
          totalCompletedReturnedMicros: 1000000,
        ),
        SalesOrderReturnStatus.partiallyReturned,
      );
      expect(
        calculator.calculate(
          totalSoldMicros: 2000000,
          totalCompletedReturnedMicros: 2000000,
        ),
        SalesOrderReturnStatus.fullyReturned,
      );
    });

    test('rejects negative inputs and returned total above sold total', () {
      expect(
        () => calculator.calculate(
          totalSoldMicros: -1,
          totalCompletedReturnedMicros: 0,
        ),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => calculator.calculate(
          totalSoldMicros: 1000,
          totalCompletedReturnedMicros: -1,
        ),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => calculator.calculate(
          totalSoldMicros: 1000,
          totalCompletedReturnedMicros: 1001,
        ),
        throwsA(isA<DomainException>()),
      );
    });
  });

  group('ReturnExchangeOrder', () {
    ReturnExchangeConfirmationSnapshot confirmationSnapshot({
      int sourceOrderVersion = 7,
      int sourceSettlementVersion = 3,
      int? pricingSourceVersion = 11,
      int? inventorySourceVersion = 5,
      String confirmedBy = 'actor-1',
      DateTime? confirmedAt,
      String? entrySource,
    }) {
      return ReturnExchangeConfirmationSnapshot(
        sourceOrderVersion: sourceOrderVersion,
        sourceSettlementVersion: sourceSettlementVersion,
        pricingSourceVersion: pricingSourceVersion,
        inventorySourceVersion: inventorySourceVersion,
        confirmedBy: confirmedBy,
        confirmedAt: confirmedAt ?? DateTime.utc(2026, 8, 10, 12),
        entrySource: entrySource,
      );
    }

    void prepareConfirmable(ReturnExchangeOrder order) {
      order.updateLines(
        lines: [
          ReturnExchangeLine(
            id: const ReturnExchangeLineId('rl-1'),
            kind: ReturnExchangeLineKind.returned,
            quantity: Quantity(quantityMicros: Quantity.scale),
            lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            sourceOrderLineId: 'ol-1',
          ),
        ],
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
      );
      order.applyValuation(
        valuation: ReturnExchangeValuation(
          returnedTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
          exchangeTotal: Money(amountMinor: 0, currencyCode: 'VND'),
          netDifferenceMinor: -10000,
        ),
        settlementPlan: ReturnExchangeSettlementPlan.create(
          netDifferenceMinor: -10000,
          currencyCode: 'VND',
          collectAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          refundAmount: Money(amountMinor: 10000, currencyCode: 'VND'),
          receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        ),
      );
    }

    test('confirm requires returned line within returnable qty', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      prepareConfirmable(order);
      order.confirm(
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
        confirmationSnapshot: confirmationSnapshot(),
      );
      expect(order.status, ReturnExchangeStatus.confirmed);
      expect(order.valuation, isNotNull);
      expect(order.settlementPlan, isNotNull);

      expect(
        () =>
            ReturnExchangeOrder.start(
              tenantId: const TenantId('t1'),
              salesOrderId: 'order-1',
              currencyCode: 'VND',
            )..confirm(
              returnableQuantityByOrderLineId: const {},
              confirmationSnapshot: confirmationSnapshot(),
            ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('confirm stores immutable confirmation evidence', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      prepareConfirmable(order);
      final snapshot = confirmationSnapshot(entrySource: null);
      order.confirm(
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
        confirmationSnapshot: snapshot,
      );

      expect(order.confirmationSnapshot, same(snapshot));
      expect(order.confirmationSnapshot!.sourceOrderVersion, greaterThan(0));
      expect(order.confirmationSnapshot!.sourceSettlementVersion, greaterThan(0));
      expect(order.confirmationSnapshot!.pricingSourceVersion, 11);
      expect(order.confirmationSnapshot!.inventorySourceVersion, 5);
      expect(order.confirmationSnapshot!.confirmedBy, 'actor-1');
      expect(order.confirmationSnapshot!.confirmedAt, DateTime.utc(2026, 8, 10, 12));
      expect(order.confirmationSnapshot!.entrySource, isNull);
      expect(order.domainEvents!.whereType<ReturnExchangeConfirmedEvent>(), hasLength(1));

      expect(
        () => ReturnExchangeConfirmationSnapshot(
          sourceOrderVersion: 0,
          sourceSettlementVersion: 3,
          confirmedBy: 'actor-1',
          confirmedAt: DateTime.utc(2026, 8, 10),
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test(
      'confirmed and completed cannot update discard or reconfirm; completion preserves snapshot',
      () {
        final order = ReturnExchangeOrder.start(
          tenantId: const TenantId('tenant-1'),
          salesOrderId: 'order-1',
          currencyCode: 'VND',
        );
        prepareConfirmable(order);
        final snapshot = confirmationSnapshot();
        order.confirm(
          returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
          confirmationSnapshot: snapshot,
        );

        expect(
          () => order.updateLines(
            lines: order.lines,
            returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
          ),
          throwsA(isA<BusinessRuleValidationException>()),
        );
        expect(
          () => order.cancel(),
          throwsA(isA<BusinessRuleValidationException>()),
        );
        expect(
          () => order.confirm(
            returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
            confirmationSnapshot: confirmationSnapshot(confirmedBy: 'other'),
          ),
          throwsA(isA<BusinessRuleValidationException>()),
        );

        order.markProcessing();
        expect(order.confirmationSnapshot, same(snapshot));
        order.complete();
        expect(order.status, ReturnExchangeStatus.completed);
        expect(order.confirmationSnapshot, same(snapshot));

        expect(
          () => order.confirm(
            returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
            confirmationSnapshot: confirmationSnapshot(),
          ),
          throwsA(isA<BusinessRuleValidationException>()),
        );
        expect(
          () => order.cancel(),
          throwsA(isA<BusinessRuleValidationException>()),
        );
        // No reopen transition exists on the aggregate API.
        expect(
          () => (order as dynamic).reopen(),
          throwsA(anything),
        );
      },
    );

    test('completion only accepts confirmed or processing', () {
      final draft = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      expect(() => draft.complete(), throwsA(isA<DomainException>()));

      final cancelled = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      cancelled.cancel();
      expect(() => cancelled.complete(), throwsA(isA<DomainException>()));
    });

    test('applyValuation stores plan and updateLines clears stale valuation evidence', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      order.updateLines(
        lines: [
          ReturnExchangeLine(
            id: const ReturnExchangeLineId('rl-1'),
            kind: ReturnExchangeLineKind.returned,
            quantity: Quantity(quantityMicros: Quantity.scale),
            lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            sourceOrderLineId: 'ol-1',
          ),
        ],
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
      );
      order.applyValuation(
        valuation: ReturnExchangeValuation(
          returnedTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
          exchangeTotal: Money(amountMinor: 0, currencyCode: 'VND'),
          netDifferenceMinor: -10000,
        ),
        settlementPlan: ReturnExchangeSettlementPlan.create(
          netDifferenceMinor: -10000,
          currencyCode: 'VND',
          collectAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          refundAmount: Money(amountMinor: 4000, currencyCode: 'VND'),
          receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableReverseAmount: Money(amountMinor: 6000, currencyCode: 'VND'),
        ),
      );
      expect(order.valuation?.netDifferenceMinor, -10000);
      expect(order.settlementPlan?.refundAmount.amountMinor, 4000);

      order.updateLines(
        lines: [
          ReturnExchangeLine(
            id: const ReturnExchangeLineId('rl-2'),
            kind: ReturnExchangeLineKind.returned,
            quantity: Quantity(quantityMicros: Quantity.scale),
            lineTotal: Money(amountMinor: 20000, currencyCode: 'VND'),
            sourceOrderLineId: 'ol-1',
          ),
        ],
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
      );
      expect(order.valuation, isNull);
      expect(order.settlementPlan, isNull);
    });

    test('applyValuation rejects difference mismatch and confirm requires both', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      order.updateLines(
        lines: [
          ReturnExchangeLine(
            id: const ReturnExchangeLineId('rl-1'),
            kind: ReturnExchangeLineKind.returned,
            quantity: Quantity(quantityMicros: Quantity.scale),
            lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            sourceOrderLineId: 'ol-1',
          ),
        ],
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
      );

      expect(
        () => order.applyValuation(
          valuation: ReturnExchangeValuation(
            returnedTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            exchangeTotal: Money(amountMinor: 0, currencyCode: 'VND'),
            netDifferenceMinor: -10000,
          ),
          settlementPlan: ReturnExchangeSettlementPlan.create(
            netDifferenceMinor: -5000,
            currencyCode: 'VND',
            collectAmount: Money(amountMinor: 0, currencyCode: 'VND'),
            refundAmount: Money(amountMinor: 5000, currencyCode: 'VND'),
            receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
            receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          ),
        ),
        throwsA(isA<DomainException>()),
      );

      expect(
        () => order.confirm(
          returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
          confirmationSnapshot: confirmationSnapshot(),
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('rejects over-return quantity', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      expect(
        () => order.updateLines(
          lines: [
            ReturnExchangeLine(
              id: const ReturnExchangeLineId('rl-1'),
              kind: ReturnExchangeLineKind.returned,
              quantity: Quantity(quantityMicros: Quantity.scale * 2),
              lineTotal: Money(amountMinor: 20000, currencyCode: 'VND'),
              sourceOrderLineId: 'ol-1',
            ),
          ],
          returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('rejects zero quantity and exchange lines that reference original lines', () {
      expect(
        () => ReturnExchangeOrder.start(
          tenantId: const TenantId('tenant-1'),
          salesOrderId: 'order-1',
          currencyCode: 'VND',
          lines: <ReturnExchangeLine>[
            ReturnExchangeLine(
              id: const ReturnExchangeLineId('line-1'),
              kind: ReturnExchangeLineKind.exchange,
              quantity: Quantity(quantityMicros: 0),
              lineTotal: Money(amountMinor: 0, currencyCode: 'VND'),
              sourceOrderLineId: 'source-line-1',
            ),
          ],
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('confirm rejects exchange-only tickets without a returned line', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      order.updateLines(
        lines: [
          ReturnExchangeLine(
            id: const ReturnExchangeLineId('ex-1'),
            kind: ReturnExchangeLineKind.exchange,
            quantity: Quantity(quantityMicros: Quantity.scale),
            lineTotal: Money(amountMinor: 15000, currencyCode: 'VND'),
          ),
        ],
        returnableQuantityByOrderLineId: const {},
      );
      order.applyValuation(
        valuation: ReturnExchangeValuation(
          returnedTotal: Money(amountMinor: 0, currencyCode: 'VND'),
          exchangeTotal: Money(amountMinor: 15000, currencyCode: 'VND'),
          netDifferenceMinor: 15000,
        ),
        settlementPlan: ReturnExchangeSettlementPlan.create(
          netDifferenceMinor: 15000,
          currencyCode: 'VND',
          collectAmount: Money(amountMinor: 15000, currencyCode: 'VND'),
          refundAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableCreateAmount: Money(amountMinor: 0, currencyCode: 'VND'),
          receivableReverseAmount: Money(amountMinor: 0, currencyCode: 'VND'),
        ),
      );

      expect(
        () => order.confirm(
          returnableQuantityByOrderLineId: const {},
          confirmationSnapshot: confirmationSnapshot(),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(order.status, ReturnExchangeStatus.draft);
    });

    test(
      'valuation sign convention is exchangeValue minus returnValue for settlementDifference',
      () {
        final refundCase = ReturnExchangeValuation(
          returnedTotal: Money(amountMinor: 100000, currencyCode: 'VND'),
          exchangeTotal: Money(amountMinor: 40000, currencyCode: 'VND'),
          netDifferenceMinor: -60000,
        );
        expect(refundCase.netDifferenceMinor, -60000);
        expect(refundCase.customerReceivesRefund, isTrue);
        expect(
          refundCase.exchangeTotal.amountMinor - refundCase.returnedTotal.amountMinor,
          refundCase.netDifferenceMinor,
        );

        final collectCase = ReturnExchangeValuation(
          returnedTotal: Money(amountMinor: 40000, currencyCode: 'VND'),
          exchangeTotal: Money(amountMinor: 70000, currencyCode: 'VND'),
          netDifferenceMinor: 30000,
        );
        expect(collectCase.customerOwes, isTrue);
        expect(
          collectCase.exchangeTotal.amountMinor - collectCase.returnedTotal.amountMinor,
          collectCase.netDifferenceMinor,
        );
      },
    );

    test('technical discard is idempotent and confirmed work cannot be discarded', () {
      final draft = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      draft.cancel();
      final versionAfterFirstDiscard = draft.version;
      draft.cancel();
      expect(draft.version, versionAfterFirstDiscard);
      expect(draft.status, ReturnExchangeStatus.cancelled);

      final confirmed = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      prepareConfirmable(confirmed);
      confirmed.confirm(
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
        confirmationSnapshot: confirmationSnapshot(),
      );
      expect(
        () => confirmed.cancel(),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(confirmed.status, ReturnExchangeStatus.confirmed);
    });

    test('returned lines require sourceOrderLineId', () {
      expect(
        () => ReturnExchangeOrder.start(
          tenantId: const TenantId('tenant-1'),
          salesOrderId: 'order-1',
          currencyCode: 'VND',
          lines: [
            ReturnExchangeLine(
              id: const ReturnExchangeLineId('rl-1'),
              kind: ReturnExchangeLineKind.returned,
              quantity: Quantity(quantityMicros: Quantity.scale),
              lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            ),
          ],
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('updateLines aggregates repeated returned lines before enforcing remaining quantity', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      order.updateLines(
        lines: [
          ReturnExchangeLine(
            id: const ReturnExchangeLineId('rl-1'),
            kind: ReturnExchangeLineKind.returned,
            quantity: Quantity(quantityMicros: Quantity.scale),
            lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            sourceOrderLineId: 'ol-1',
          ),
          ReturnExchangeLine(
            id: const ReturnExchangeLineId('rl-2'),
            kind: ReturnExchangeLineKind.returned,
            quantity: Quantity(quantityMicros: Quantity.scale),
            lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            sourceOrderLineId: 'ol-1',
          ),
        ],
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale * 2},
      );
      expect(order.lines, hasLength(2));

      expect(
        () => order.updateLines(
          lines: [
            ReturnExchangeLine(
              id: const ReturnExchangeLineId('rl-3'),
              kind: ReturnExchangeLineKind.returned,
              quantity: Quantity(quantityMicros: Quantity.scale),
              lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
              sourceOrderLineId: 'ol-1',
            ),
            ReturnExchangeLine(
              id: const ReturnExchangeLineId('rl-4'),
              kind: ReturnExchangeLineKind.returned,
              quantity: Quantity(quantityMicros: Quantity.scale),
              lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
              sourceOrderLineId: 'ol-1',
            ),
          ],
          returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('non-draft update throws', () {
      final order = ReturnExchangeOrder.start(
        tenantId: const TenantId('tenant-1'),
        salesOrderId: 'order-1',
        currencyCode: 'VND',
      );
      prepareConfirmable(order);
      order.confirm(
        returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
        confirmationSnapshot: confirmationSnapshot(),
      );

      expect(
        () => order.updateLines(
          lines: [
            ReturnExchangeLine(
              id: const ReturnExchangeLineId('rl-2'),
              kind: ReturnExchangeLineKind.returned,
              quantity: Quantity(quantityMicros: Quantity.scale),
              lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
              sourceOrderLineId: 'ol-1',
            ),
          ],
          returnableQuantityByOrderLineId: {'ol-1': Quantity.scale},
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('start with non-empty invalid lines fails before emitting a started event', () {
      ReturnExchangeOrder? started;
      Object? caught;
      try {
        started = ReturnExchangeOrder.start(
          tenantId: const TenantId('tenant-1'),
          salesOrderId: 'order-1',
          currencyCode: 'VND',
          lines: [
            ReturnExchangeLine(
              id: const ReturnExchangeLineId('line-1'),
              kind: ReturnExchangeLineKind.exchange,
              quantity: Quantity(quantityMicros: 0),
              lineTotal: Money(amountMinor: 0, currencyCode: 'VND'),
              sourceOrderLineId: 'source-line-1',
            ),
          ],
        );
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<BusinessRuleValidationException>());
      expect(started, isNull);
    });
  });
}
