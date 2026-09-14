import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowAllPermissionChecker implements IPermissionChecker {
  final List<String> requiredCodes = <String>[];

  @override
  Future<void> require(String permissionCode) async {
    requiredCodes.add(permissionCode);
  }
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

final class _FakeCheckoutGateway implements ICheckoutGateway {
  _FakeCheckoutGateway({
    CheckoutPrecheckDto? precheckResult,
    CheckoutResultDto? finalizeResult,
    CheckoutResultDto? statusResult,
    this.finalizeError,
  }) : _precheckResult = precheckResult,
       _finalizeResult = finalizeResult,
       _statusResult = statusResult;

  final CheckoutPrecheckDto? _precheckResult;
  final CheckoutResultDto? _finalizeResult;
  final CheckoutResultDto? _statusResult;
  final Object? finalizeError;

  int finalizeCalls = 0;
  int getResultCalls = 0;
  final List<String> calls = <String>[];

  @override
  Future<CheckoutPrecheckDto> precheck(PrecheckSalesOrderCheckoutQuery query) async {
    calls.add('precheck');
    return _precheckResult ?? _readyPrecheck();
  }

  @override
  Future<CheckoutResultDto> finalize(FinalizeSalesOrderCommand command) async {
    finalizeCalls += 1;
    calls.add('finalize');
    if (finalizeError != null) throw finalizeError!;
    return _finalizeResult ??
        CheckoutResultDto(
          idempotencyKey: command.id,
          salesOrderId: 'order-1',
          salesOrderVersion: 1,
          status: CheckoutResultStatus.succeeded,
        );
  }

  @override
  Future<CheckoutResultDto> getResult(
    GetCheckoutResultQuery query,
  ) async {
    getResultCalls += 1;
    return _statusResult ??
        CheckoutResultDto(
          idempotencyKey: query.idempotencyKey,
          salesOrderId: 'order-1',
          salesOrderVersion: 1,
          status: CheckoutResultStatus.succeeded,
        );
  }
}

void main() {
  group('TH-05 Group D authoritative checkout commit', () {
    test('SCN-01 finalizes through gateway after authoritative precheck passes', () async {
      final gateway = _FakeCheckoutGateway(
        finalizeResult: const CheckoutResultDto(
          idempotencyKey: 'cmd-1',
          salesOrderId: 'order-1',
          salesOrderVersion: 1,
          status: CheckoutResultStatus.succeeded,
        ),
      );
      final handler = FinalizeSalesOrderCommandHandler(
        checkoutGateway: gateway,
        permissionChecker: _AllowAllPermissionChecker(),
      );

      final result = await handler.handle(_command());

      expect(result.status, CheckoutResultStatus.succeeded);
      expect(result.salesOrderId, 'order-1');
      expect(gateway.finalizeCalls, 1);
      expect(gateway.calls, ['precheck', 'finalize']);
    });

    test('SCN-02 retry with same payload returns the same succeeded order', () async {
      final gateway = _FakeCheckoutGateway(
        finalizeResult: const CheckoutResultDto(
          idempotencyKey: 'cmd-1',
          salesOrderId: 'order-1',
          salesOrderVersion: 1,
          status: CheckoutResultStatus.succeeded,
        ),
      );
      final handler = FinalizeSalesOrderCommandHandler(
        checkoutGateway: gateway,
        permissionChecker: _AllowAllPermissionChecker(),
      );

      final first = await handler.handle(_command());
      final second = await handler.handle(_command());

      expect(first.salesOrderId, second.salesOrderId);
      expect(second.status, CheckoutResultStatus.succeeded);
      expect(gateway.finalizeCalls, 2);
    });

    test(
      'SCN-03 reused idempotency key with different payload surfaces IDEMPOTENCY_CONFLICT',
      () async {
        final gateway = _FakeCheckoutGateway(
          finalizeError: const SalesContractException(
            'IDEMPOTENCY_CONFLICT',
            message: 'Idempotency key was reused with a different payload.',
          ),
        );
        final handler = FinalizeSalesOrderCommandHandler(
          checkoutGateway: gateway,
          permissionChecker: _AllowAllPermissionChecker(),
        );

        await expectLater(
          () => handler.handle(_command()),
          throwsA(
            isA<SalesContractException>().having(
              (error) => error.code,
              'code',
              'IDEMPOTENCY_CONFLICT',
            ),
          ),
        );
      },
    );

    test('SCN-04 timeout after server commit is recovered via status query', () async {
      final gateway = _FakeCheckoutGateway(
        statusResult: const CheckoutResultDto(
          idempotencyKey: 'attempt-1',
          salesOrderId: 'order-1',
          salesOrderVersion: 1,
          status: CheckoutResultStatus.succeeded,
        ),
      );
      final handler = GetCheckoutResultQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        checkoutGateway: gateway,
      );

      final result = await handler.handle(_statusQuery());

      expect(result.status, CheckoutResultStatus.succeeded);
      expect(result.salesOrderId, 'order-1');
      expect(gateway.getResultCalls, 1);
    });

    test('SCN-05 blocked command-time precheck does not call finalize RPC', () async {
      final gateway = _FakeCheckoutGateway(precheckResult: _blockedPrecheck());
      final handler = FinalizeSalesOrderCommandHandler(
        checkoutGateway: gateway,
        permissionChecker: _AllowAllPermissionChecker(),
      );

      final result = await handler.handle(_command(paymentMinor: 0));

      expect(result.status, CheckoutResultStatus.blocked);
      expect(result.salesOrderId, isEmpty);
      expect(gateway.finalizeCalls, 0);
      expect(gateway.calls, ['precheck']);
    });

    test('SCN-06 uncertain gateway result is surfaced unchanged', () async {
      final gateway = _FakeCheckoutGateway(
        finalizeResult: const CheckoutResultDto(
          idempotencyKey: 'cmd-1',
          salesOrderId: '',
          salesOrderVersion: 0,
          status: CheckoutResultStatus.uncertain,
        ),
      );
      final handler = FinalizeSalesOrderCommandHandler(
        checkoutGateway: gateway,
        permissionChecker: _AllowAllPermissionChecker(),
      );

      final result = await handler.handle(_command());

      expect(result.status, CheckoutResultStatus.uncertain);
      expect(gateway.finalizeCalls, 1);
    });

    test('SCN-07 source draft converted returns succeeded with a non-empty order id', () async {
      final gateway = _FakeCheckoutGateway(
        finalizeResult: const CheckoutResultDto(
          idempotencyKey: 'cmd-1',
          salesOrderId: 'order-9',
          salesOrderVersion: 1,
          status: CheckoutResultStatus.succeeded,
        ),
      );
      final handler = FinalizeSalesOrderCommandHandler(
        checkoutGateway: gateway,
        permissionChecker: _AllowAllPermissionChecker(),
      );

      final result = await handler.handle(_command(expectedSourceVersion: 2));

      expect(result.status, CheckoutResultStatus.succeeded);
      expect(result.salesOrderId, 'order-9');
    });

    test('payment permission is required before gateway precheck', () async {
      final gateway = _FakeCheckoutGateway();
      final checker = _AllowAllPermissionChecker();
      final handler = FinalizeSalesOrderCommandHandler(
        checkoutGateway: gateway,
        permissionChecker: checker,
      );

      await handler.handle(_command());

      expect(checker.requiredCodes, [SalesPermissions.recordPayment]);
      expect(gateway.calls, ['precheck', 'finalize']);
    });

    test('status query enforces sales.order.view before touching the gateway', () async {
      final gateway = _FakeCheckoutGateway();
      final handler = GetCheckoutResultQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        checkoutGateway: gateway,
      );

      await expectLater(
        () => handler.handle(_statusQuery()),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.getResultCalls, 0);
    });
  });
}

CheckoutPrecheckDto _readyPrecheck() => CheckoutPrecheckDto(
  canFinalize: true,
  blockers: const [],
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

CheckoutPrecheckDto _blockedPrecheck() => CheckoutPrecheckDto(
  canFinalize: false,
  blockers: const [
    SalesBlockerDto(code: 'CHECKOUT_BLOCKED', message: 'Blocked.'),
  ],
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

FinalizeSalesOrderCommand _command({
  int paymentMinor = 1000000,
  int? expectedSourceVersion,
}) {
  return FinalizeSalesOrderCommand(
    id: 'cmd-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
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
    commercialSnapshot: _commercialSnapshot(),
    idempotencyKey: 'idem-1',
    payloadHash: 'hash-1',
    correlationId: 'corr-1',
    expectedSourceVersion: expectedSourceVersion,
  );
}

SalesCommercialSnapshotInput _commercialSnapshot() => SalesCommercialSnapshotInput(
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Nguyễn Văn An',
  ),
  lines: const [
    SalesReceiptLineDto(
      lineId: 'line-1',
      product: ProductSnapshotDto(
        productId: 'product-1',
        sku: null,
        displayName: 'Vaccine A',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-1',
        unitCode: null,
        unitName: 'Lọ',
      ),
      quantity: QuantityDto(quantityMicros: QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
  ],
);

GetCheckoutResultQuery _statusQuery() {
  return GetCheckoutResultQuery(
    storeId: 'store-1',
tenantId: 'tenant-1',
    actorId: 'actor-1',
    idempotencyKey: 'attempt-1',
  );
}
