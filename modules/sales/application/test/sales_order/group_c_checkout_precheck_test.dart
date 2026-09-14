import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _DenyPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {
    throw const SalesContractException(
      'PERMISSION_DENIED',
      message: 'Denied in test.',
    );
  }
}

final class _RecordingCheckoutGateway implements ICheckoutGateway {
  _RecordingCheckoutGateway({required this.result});

  final CheckoutPrecheckDto result;
  PrecheckSalesOrderCheckoutQuery? precheckCalls;
  int precheckCount = 0;

  @override
  Future<CheckoutPrecheckDto> precheck(PrecheckSalesOrderCheckoutQuery query) async {
    precheckCalls = query;
    precheckCount += 1;
    return result;
  }

  @override
  Future<CheckoutResultDto> finalize(FinalizeSalesOrderCommand command) {
    throw UnsupportedError('finalize is Group D; Group C must not reach it');
  }

  @override
  Future<CheckoutResultDto> getResult(GetCheckoutResultQuery query) {
    throw UnsupportedError('getResult is Group D; Group C must not reach it');
  }
}

CheckoutPrecheckDto _readyResult() {
  return CheckoutPrecheckDto(
    canFinalize: true,
    blockers: const <SalesBlockerDto>[],
    monetarySummary: const CheckoutMonetarySummaryDto(
      subtotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      grandTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
    receivableRequirement: const ReceivableRequirementDto(
      isRequired: false,
      amount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    ),
  );
}

void main() {
  group('TH-05 Group C checkout live reference precheck', () {
    test(
      'S11 SCN-01 returns ready when references, pricing, payment, and inventory are valid',
      () async {
        final service = CheckoutPrecheckService(
          referencePrecheck: FakeCheckoutReferencePrecheckPort(),
        );

        final result = await service.precheck(_query());

        expect(result.canFinalize, isTrue);
        expect(result.blockers, isEmpty);
        expect(result.monetarySummary.grandTotal.amountMinor, 1000000);
      },
    );

    test('S11 SCN-02 blocks when pricing changes make payment intent invalid', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort(
          pricingSummary: _summary(950000),
          blockers: const <SalesBlockerDto>[
            SalesBlockerDto(
              code: 'PRICING_CHANGED',
              message: 'Pricing changed before checkout.',
              field: 'lines',
            ),
          ],
        ),
      );

      final result = await service.precheck(_query());

      expect(result.canFinalize, isFalse);
      expect(result.monetarySummary.grandTotal.amountMinor, 950000);
      expect(result.blockers.map((blocker) => blocker.code), contains('PRICING_CHANGED'));
      expect(
        result.blockers.map((blocker) => blocker.code),
        contains(CheckoutBlockerCodes.paymentIntentExceedsAmountDue),
      );
    });

    test('S11 SCN-03 blocks product that is no longer sellable', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort.productUnavailable(),
      );

      final result = await service.precheck(_query(paymentMinor: 0));

      expect(result.canFinalize, isFalse);
      expect(result.blockers.map((blocker) => blocker.code), contains('PRODUCT_NOT_SELLABLE'));
      expect(
        result.blockers.singleWhere((blocker) => blocker.code == 'PRODUCT_NOT_SELLABLE').field,
        'lines[0]',
      );
    });

    test('S11 SCN-04 blocks insufficient inventory under no-negative-stock policy', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort.inventoryUnavailable(),
      );

      final result = await service.precheck(_query(paymentMinor: 0));

      expect(result.canFinalize, isFalse);
      expect(result.blockers.map((blocker) => blocker.code), contains('INVENTORY_UNAVAILABLE'));
    });

    test('S11 SCN-06 blocks dependency unavailable instead of returning ready', () async {
      final service = CheckoutPrecheckService(
        referencePrecheck: FakeCheckoutReferencePrecheckPort.dependencyUnavailable(),
      );

      final result = await service.precheck(_query(paymentMinor: 0));

      expect(result.canFinalize, isFalse);
      expect(result.blockers.map((blocker) => blocker.code), contains('DEPENDENCY_UNAVAILABLE'));
    });

    test(
      'S11 default reference precheck fails closed when no live provider is wired',
      () async {
        final service = CheckoutPrecheckService();

        final result = await service.precheck(_query(paymentMinor: 0));

        expect(result.canFinalize, isFalse);
        expect(
          result.blockers.map((blocker) => blocker.code),
          contains(CheckoutBlockerCodes.dependencyUnavailable),
        );
        expect(result.monetarySummary.grandTotal.amountMinor, 0);
      },
    );

    test('S11 handler enforces permission then delegates the exact query', () async {
      final gateway = _RecordingCheckoutGateway(result: _readyResult());
      final query = _query(paymentMinor: 400000);
      final handler = PrecheckSalesOrderCheckoutQueryHandler(
        permissionChecker: _AllowPermissionChecker(),
        checkoutGateway: gateway,
      );

      final result = await handler.handle(query);

      expect(result.canFinalize, isTrue);
      expect(gateway.precheckCalls, same(query));
    });

    test('S11 denied permission never reaches the gateway', () async {
      final gateway = _RecordingCheckoutGateway(result: _readyResult());
      final handler = PrecheckSalesOrderCheckoutQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        checkoutGateway: gateway,
      );

      await expectLater(
        handler.handle(_query(paymentMinor: 0)),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.precheckCalls, isNull);
    });
  });
}

PrecheckSalesOrderCheckoutQuery _query({int paymentMinor = 1000000}) {
  return PrecheckSalesOrderCheckoutQuery(
    storeId: 'store-1',
    customerId: 'customer-1',
    currencyCode: 'VND',
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

CheckoutMonetarySummaryDto _summary(int grandTotal) {
  return CheckoutMonetarySummaryDto(
    subtotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
    discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    grandTotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
  );
}
