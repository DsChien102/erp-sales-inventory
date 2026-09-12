import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('SalesCheckoutCubit Group C precheck', () {
    test('load does not run checkout precheck automatically', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = SalesCheckoutCubit(
        args: _draftArgs(),
        salesModule: module,
        executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
        activeStoreContext: const _ActiveStoreContext('store-9'),
        debounceDuration: Duration.zero,
      );

      await cubit.load();

      expect(module.queries, isEmpty);
      expect(module.commands, isEmpty);
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck, isNull);
      await cubit.close();
    });

    test('explicit precheck sends full snapshot through ISalesModule query', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = SalesCheckoutCubit(
        args: _draftArgs(),
        salesModule: module,
        executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
        activeStoreContext: const _ActiveStoreContext('store-9'),
        debounceDuration: Duration.zero,
      );

      await cubit.precheckNow();

      final query = module.queries.single as PrecheckSalesOrderCheckoutQuery;
      expect(query.tenantId, 'tenant-1');
      expect(query.actorId, 'actor-1');
      expect(query.storeId, 'store-9');
      expect(query.customerId, 'partner-7');
      expect(query.lines, hasLength(1));
      expect(query.paymentIntents.single.amount.amountMinor, 1000000);
      expect(query.expectedSourceVersion, 3);
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck, same(module.result));
      await cubit.close();
    });

    test('load never executes FinalizeSalesOrderCommand', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);

      await cubit.load();

      expect(module.commands, isEmpty);
      await cubit.close();
    });

    test('explicit precheck emits ready only when canFinalize and blockers empty', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck!.canFinalize, isTrue);
      expect(cubit.state.precheck!.blockers, isEmpty);
      await cubit.close();
    });

    test('explicit precheck emits blocked when backend returns blockers', () async {
      final module = _RecordingSalesModule(result: _blockedResult());
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.status, SalesCheckoutStatus.blocked);
      expect(cubit.state.precheck, same(module.result));
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('dependency unavailable maps to failure without success', () async {
      final module = _RecordingSalesModule(
        error: const SalesContractException(
          'DEPENDENCY_UNAVAILABLE',
          message: 'Pricing dependency unavailable.',
        ),
      );
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.status, SalesCheckoutStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại.',
      );
      expect(cubit.state.vm.cashPaidMinor, 1000000);
      expect(module.commands, isEmpty);
      await cubit.close();
    });

    test('permission denied maps to failure', () async {
      final module = _RecordingSalesModule(
        error: const SalesContractException(
          'PERMISSION_DENIED',
          message: 'Denied.',
        ),
      );
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.status, SalesCheckoutStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Bạn không còn quyền kiểm tra thanh toán.',
      );
      await cubit.close();
    });

    test('retryPrecheck re-runs query with same snapshot inputs', () async {
      final module = _RecordingSalesModule(
        error: const SalesContractException('DEPENDENCY_UNAVAILABLE'),
      );
      final cubit = _cubit(module: module);

      await cubit.precheckNow();
      expect(cubit.state.status, SalesCheckoutStatus.failure);

      module.error = null;
      module.result = _readyResult();
      await cubit.retryPrecheck();

      expect(module.queries, hasLength(2));
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck, same(module.result));
      await cubit.close();
    });

    test('mixed payment maps cash and manual bank transfer intents', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);

      cubit.selectPaymentMode(SalesPaymentMode.mixed);
      cubit.updateCashAmount(400000);
      cubit.updateBankAmount(600000);
      cubit.updateTransactionCode(' TX-99 ');
      await cubit.precheckNow();

      final query = module.queries.last as PrecheckSalesOrderCheckoutQuery;
      expect(query.paymentIntents, hasLength(2));
      expect(query.paymentIntents[0].method, SalesPaymentMethod.cash);
      expect(query.paymentIntents[0].amount.amountMinor, 400000);
      expect(query.paymentIntents[1].method, SalesPaymentMethod.manualBankTransfer);
      expect(query.paymentIntents[1].reference, 'TX-99');
      await cubit.close();
    });

    test('receivable due date is sent with explicit precheck', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);

      cubit.updateCashAmount(400000);
      cubit.updateDueDate(DateTime(2026, 8, 30));
      await cubit.precheckNow();

      final query = module.queries.last as PrecheckSalesOrderCheckoutQuery;
      expect(query.paymentDueDate, DateTime(2026, 8, 30));
      await cubit.close();
    });

    test('zero-value entries are omitted from the query', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);
      cubit.selectPaymentMode(SalesPaymentMode.mixed);
      cubit.updateCashAmount(0);
      cubit.updateBankAmount(0);

      await cubit.precheckNow();

      final query = module.queries.last as PrecheckSalesOrderCheckoutQuery;
      expect(query.paymentIntents, isEmpty);
      await cubit.close();
    });

    test('editing payment does not run or schedule another precheck', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(
        module: module,
        debounceDuration: const Duration(days: 1),
      );
      await cubit.precheckNow();
      expect(cubit.state.precheck, isNotNull);

      cubit.updateCashAmount(500000);

      expect(cubit.state.precheck, isNull);
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(module.queries, hasLength(1));
      await cubit.close();
    });

    test('walk-in single-method payments stay locked to the exact order total', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module, isWalkIn: true);

      cubit.updateCashAmount(1200000);
      expect(cubit.state.vm.cashPaidMinor, 1000000);

      cubit.selectPaymentMode(SalesPaymentMode.bankTransfer);
      cubit.updateBankAmount(1200000);
      expect(cubit.state.vm.bankPaidMinor, 1000000);
      expect(cubit.state.vm.cashPaidMinor, 0);
      await cubit.close();
    });

    test('walk-in mixed payment cannot finalize unless split total matches order total', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module, isWalkIn: true);

      cubit.selectPaymentMode(SalesPaymentMode.mixed);
      cubit.updateCashAmount(400000);
      cubit.updateBankAmount(500000);

      await cubit.finalizeCheckout();

      expect(module.queries, isEmpty);
      expect(module.commands, isEmpty);
      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.idle);
      await cubit.close();
    });
  });

  group('SalesCheckoutCubit Group D attempt', () {
    test('finalize runs one precheck before sending one immutable command', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);

      await cubit.load();
      await Future.wait([cubit.finalizeCheckout(), cubit.finalizeCheckout()]);

      expect(module.queries.whereType<PrecheckSalesOrderCheckoutQuery>(), hasLength(1));
      expect(module.commands, hasLength(1));
      final command = module.commands.single as FinalizeSalesOrderCommand;
      expect(command.sourceDraftId, 'draft-source-1');
      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.succeeded);
      expect(cubit.state.checkoutResult!.salesOrderId, 'order-1');
      await cubit.close();
    });

    test('partial-payment finalize sends receivable due date in immutable command', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);

      cubit.updateCashAmount(400000);
      cubit.updateDueDate(DateTime(2026, 8, 30));
      await cubit.finalizeCheckout();

      final command = module.commands.single as FinalizeSalesOrderCommand;
      expect(command.paymentDueDate, DateTime(2026, 8, 30));
      await cubit.close();
    });

    test('uncertain result recovers by the same attempt id', () async {
      final module = _RecordingSalesModule(
        result: _readyResult(),
        commandResult: const CheckoutResultDto(
          idempotencyKey: 'attempt-1',
          salesOrderId: '',
          salesOrderVersion: 0,
          status: CheckoutResultStatus.uncertain,
        ),
      );
      final cubit = _cubit(module: module);
      await cubit.finalizeCheckout();

      final command = module.commands.single as FinalizeSalesOrderCommand;
      final statusQuery = module.queries.last as GetCheckoutResultQuery;
      expect(statusQuery.idempotencyKey, command.idempotencyKey);
      expect(statusQuery.storeId, command.storeId);
      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.succeeded);
      await cubit.close();
    });

    test('same-attempt retry reuses the exact command object', () async {
      final module = _RecordingSalesModule(result: _readyResult());
      final cubit = _cubit(module: module);
      await cubit.finalizeCheckout();
      await cubit.retryCurrentAttempt();

      expect(module.commands, hasLength(2));
      expect(identical(module.commands[0], module.commands[1]), isTrue);
      await cubit.close();
    });

    test('blocked finalize precheck stops before command', () async {
      final module = _RecordingSalesModule(result: _blockedResult());
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(module.queries.whereType<PrecheckSalesOrderCheckoutQuery>(), hasLength(1));
      expect(module.commands, isEmpty);
      expect(cubit.state.status, SalesCheckoutStatus.blocked);
      expect(cubit.state.precheck, same(module.result));
      await cubit.close();
    });
  });
}

SalesCheckoutCubit _cubit({
  required ISalesModule module,
  Duration debounceDuration = Duration.zero,
  bool isWalkIn = false,
}) {
  return SalesCheckoutCubit(
    args: _draftArgs(isWalkIn: isWalkIn),
    salesModule: module,
    executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
    activeStoreContext: const _ActiveStoreContext('store-9'),
    debounceDuration: debounceDuration,
  );
}

SalesCheckoutDraftArgs _draftArgs({bool isWalkIn = false}) {
  return SalesCheckoutDraftArgs(
    runtimeDraftId: 'draft-1',
    sourceDraftId: 'draft-source-1',
    customerId: isWalkIn ? null : 'partner-7',
    customerDisplayName: isWalkIn ? 'Khách lẻ' : 'Phòng khám A',
    customerPhone: isWalkIn ? null : '0903000000',
    isWalkIn: isWalkIn,
    currencyCode: 'VND',
    provisionalTotalAmountMinor: 1000000,
    expectedSourceVersion: 3,
    commercialSnapshot: _commercialSnapshot(),
    lines: const [
      CheckoutLineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
    ],
  );
}

SalesCommercialSnapshotInput _commercialSnapshot() => SalesCommercialSnapshotInput(
  store: const StoreSnapshotDto(
    storeId: 'store-9',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
  customer: const CustomerSnapshotDto(
    customerId: 'partner-7',
    displayName: 'Phòng khám A',
    phoneNumber: '0903000000',
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

CheckoutPrecheckDto _readyResult({int grandTotal = 1000000}) {
  return CheckoutPrecheckDto(
    canFinalize: true,
    blockers: const <SalesBlockerDto>[],
    monetarySummary: CheckoutMonetarySummaryDto(
      subtotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
      discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      grandTotal: MoneyDto(amountMinor: grandTotal, currencyCode: 'VND'),
    ),
    receivableRequirement: const ReceivableRequirementDto(
      isRequired: false,
      amount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    ),
  );
}

CheckoutPrecheckDto _blockedResult({String code = 'INVENTORY_UNAVAILABLE'}) {
  return CheckoutPrecheckDto(
    canFinalize: false,
    blockers: [
      SalesBlockerDto(
        code: code,
        message: 'Insufficient stock.',
        field: 'lines[0]',
      ),
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
}

final class _RecordingSalesModule implements ISalesModule {
  _RecordingSalesModule({
    CheckoutPrecheckDto? result,
    CheckoutResultDto? commandResult,
    this.error,
  }) : result = result ?? _readyResult(),
       commandResult =
           commandResult ??
           const CheckoutResultDto(
             idempotencyKey: 'attempt-1',
             salesOrderId: 'order-1',
             salesOrderVersion: 1,
             status: CheckoutResultStatus.succeeded,
           );

  CheckoutPrecheckDto result;
  Object? error;
  CheckoutResultDto commandResult;
  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    return commandResult as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    if (query is GetCheckoutResultQuery) {
      final statusQuery = query as GetCheckoutResultQuery;
      return CheckoutResultDto(
            idempotencyKey: statusQuery.idempotencyKey,
            salesOrderId: 'order-1',
            salesOrderVersion: 1,
            status: CheckoutResultStatus.succeeded,
          )
          as TResult;
    }
    return result as TResult;
  }
}

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext(this.tenantId, this.userId);

  final String tenantId;
  final String userId;

  @override
  String get correlationId => 'corr-test';

  @override
  Future<String> requireTenantId() async => tenantId;

  @override
  Future<String> requireUserId() async => userId;
}

final class _ActiveStoreContext implements ISalesActiveStoreContext {
  const _ActiveStoreContext(this.storeId);

  final String storeId;

  @override
  String? get activeStoreId => storeId;

  @override
  Future<String> requireActiveStoreId() async => storeId;
}
