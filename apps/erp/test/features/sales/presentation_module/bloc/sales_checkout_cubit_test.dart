import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/presentation.dart';
import '../../support/fake_sales_checkout_repository.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('SalesCheckoutCubit Group C precheck', () {
    test('load does not run checkout precheck automatically', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = SalesCheckoutCubit(
        args: _draftArgs(),
        repository: module,
        executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
        activeStoreContext: const _ActiveStoreContext('store-9'),
        debounceDuration: Duration.zero,
      );

      await cubit.load();

      expect(module.precheckCalls, isEmpty);
      expect(module.finalizeCalls, isEmpty);
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck, isNull);
      await cubit.close();
    });

    test('explicit precheck sends full snapshot through the repository', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = SalesCheckoutCubit(
        args: _draftArgs(),
        repository: module,
        executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
        activeStoreContext: const _ActiveStoreContext('store-9'),
        debounceDuration: Duration.zero,
      );

      await cubit.precheckNow();

      final query = module.precheckCalls.single;
      expect(query.storeId, 'store-9');
      expect(query.customerId, 'partner-7');
      expect(query.lines, hasLength(1));
      expect(query.paymentIntents.single.amount.amountMinor, 1000000);
      expect(query.expectedSourceVersion, 3);
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck, same(module.precheckResult));
      await cubit.close();
    });

    test('load never executes FinalizeSalesOrderCommand', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);

      await cubit.load();

      expect(module.finalizeCalls, isEmpty);
      await cubit.close();
    });

    test('explicit precheck emits ready only when canFinalize and blockers empty', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck!.canFinalize, isTrue);
      expect(cubit.state.precheck!.blockers, isEmpty);
      await cubit.close();
    });

    test('explicit precheck emits blocked when backend returns blockers', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _blockedResult());
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.status, SalesCheckoutStatus.blocked);
      expect(cubit.state.precheck, same(module.precheckResult));
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('dependency unavailable maps to failure without success', () async {
      final module = FakeSalesCheckoutRepository()
        ..precheckError = const AppException(
          'DEPENDENCY_UNAVAILABLE',
          serverMessage: 'Pricing dependency unavailable.',
        );
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.status, SalesCheckoutStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại.',
      );
      expect(cubit.state.vm.cashPaidMinor, 1000000);
      expect(module.finalizeCalls, isEmpty);
      await cubit.close();
    });

    test('permission denied maps to failure', () async {
      final module = FakeSalesCheckoutRepository()
        ..precheckError = const AppException('NO_PERMISSION', serverMessage: 'Denied.');
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
      final module = FakeSalesCheckoutRepository()
        ..precheckError = const AppException('DEPENDENCY_UNAVAILABLE');
      final cubit = _cubit(module: module);

      await cubit.precheckNow();
      expect(cubit.state.status, SalesCheckoutStatus.failure);

      module.precheckError = null;
      module.precheckResult = _readyResult();
      await cubit.retryPrecheck();

      expect(module.precheckCalls, hasLength(2));
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(cubit.state.precheck, same(module.precheckResult));
      await cubit.close();
    });

    test('mixed payment maps cash and manual bank transfer intents', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);

      cubit.selectPaymentMode(SalesPaymentMode.mixed);
      cubit.updateCashAmount(400000);
      cubit.updateBankAmount(600000);
      cubit.updateTransactionCode(' TX-99 ');
      await cubit.precheckNow();

      final query = module.precheckCalls.last;
      expect(query.paymentIntents, hasLength(2));
      expect(query.paymentIntents[0].method, SalesPaymentMethod.cash);
      expect(query.paymentIntents[0].amount.amountMinor, 400000);
      expect(query.paymentIntents[1].method, SalesPaymentMethod.manualBankTransfer);
      expect(query.paymentIntents[1].reference, 'TX-99');
      await cubit.close();
    });

    test('receivable due date is sent with explicit precheck', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);

      cubit.updateCashAmount(400000);
      cubit.updateDueDate(DateTime(2026, 8, 30));
      await cubit.precheckNow();

      final query = module.precheckCalls.last;
      expect(query.paymentDueDate, DateTime(2026, 8, 30));
      await cubit.close();
    });

    test('zero-value entries are omitted from the query', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);
      cubit.selectPaymentMode(SalesPaymentMode.mixed);
      cubit.updateCashAmount(0);
      cubit.updateBankAmount(0);

      await cubit.precheckNow();

      final query = module.precheckCalls.last;
      expect(query.paymentIntents, isEmpty);
      await cubit.close();
    });

    test('editing payment does not run or schedule another precheck', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(
        module: module,
        debounceDuration: const Duration(days: 1),
      );
      await cubit.precheckNow();
      expect(cubit.state.precheck, isNotNull);

      cubit.updateCashAmount(500000);

      expect(cubit.state.precheck, isNull);
      expect(cubit.state.status, SalesCheckoutStatus.ready);
      expect(module.precheckCalls, hasLength(1));
      await cubit.close();
    });

    test('walk-in single-method payments stay locked to the exact order total', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
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
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module, isWalkIn: true);

      cubit.selectPaymentMode(SalesPaymentMode.mixed);
      cubit.updateCashAmount(400000);
      cubit.updateBankAmount(500000);

      await cubit.finalizeCheckout();

      expect(module.precheckCalls, isEmpty);
      expect(module.finalizeCalls, isEmpty);
      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.idle);
      await cubit.close();
    });
  });

  group('SalesCheckoutCubit Group D attempt', () {
    test('finalize runs one precheck before sending one immutable command', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);

      await cubit.load();
      await Future.wait([cubit.finalizeCheckout(), cubit.finalizeCheckout()]);

      expect(module.precheckCalls, hasLength(1));
      expect(module.finalizeCalls, hasLength(1));
      final command = module.finalizeCalls.single;
      expect(command.sourceDraftId, 'draft-source-1');
      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.succeeded);
      expect(cubit.state.checkoutResult!.salesOrderId, 'order-1');
      await cubit.close();
    });

    test('partial-payment finalize sends receivable due date in immutable command', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);

      cubit.updateCashAmount(400000);
      cubit.updateDueDate(DateTime(2026, 8, 30));
      await cubit.finalizeCheckout();

      final command = module.finalizeCalls.single;
      expect(command.paymentDueDate, DateTime(2026, 8, 30));
      await cubit.close();
    });

    test('uncertain result recovers by the same attempt id', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeResults.add(
          const CheckoutResultDto(
            idempotencyKey: 'attempt-1',
            salesOrderId: '',
            salesOrderVersion: 0,
            status: CheckoutResultStatus.uncertain,
          ),
        );
      final cubit = _cubit(module: module);
      await cubit.finalizeCheckout();

      final command = module.finalizeCalls.single;
      final statusQuery = module.getResultCalls.last;
      expect(statusQuery.idempotencyKey, command.idempotencyKey);
      expect(statusQuery.storeId, command.storeId);
      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.succeeded);
      await cubit.close();
    });

    test('same-attempt retry reuses the exact command object', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult());
      final cubit = _cubit(module: module);
      await cubit.finalizeCheckout();
      await cubit.retryCurrentAttempt();

      expect(module.finalizeCalls, hasLength(2));
      expect(identical(module.finalizeCalls[0], module.finalizeCalls[1]), isTrue);
      await cubit.close();
    });

    test('blocked_customer_invalid_message', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeResults.add(
          const CheckoutResultDto(
            idempotencyKey: 'k',
            salesOrderId: '',
            salesOrderVersion: 0,
            status: CheckoutResultStatus.blocked,
            blockedCode: 'CUSTOMER_INVALID',
          ),
        );
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.blocked);
      expect(cubit.state.attemptErrorMessage, 'Khách hàng không còn hoạt động.');
      await cubit.close();
    });

    test('blocked_due_date_invalid_message', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeResults.add(
          const CheckoutResultDto(
            idempotencyKey: 'k',
            salesOrderId: '',
            salesOrderVersion: 0,
            status: CheckoutResultStatus.blocked,
            blockedCode: 'RECEIVABLE_DUE_DATE_INVALID',
          ),
        );
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.blocked);
      expect(cubit.state.attemptErrorMessage, 'Ngày hẹn thanh toán không được trước hôm nay.');
      await cubit.close();
    });

    test('price changed finalize tells the seller to return and refresh', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeResults.add(
          const CheckoutResultDto(
            idempotencyKey: 'k',
            salesOrderId: '',
            salesOrderVersion: 0,
            status: CheckoutResultStatus.blocked,
            blockedCode: 'PRICE_CHANGED',
          ),
        );
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.blocked);
      expect(
        cubit.state.attemptErrorMessage,
        'Giá đã thay đổi. Vui lòng quay lại đơn để cập nhật giá.',
      );
      await cubit.close();
    });

    test('blocked finalize precheck stops before command', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _blockedResult());
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(module.precheckCalls, hasLength(1));
      expect(module.finalizeCalls, isEmpty);
      expect(cubit.state.status, SalesCheckoutStatus.blocked);
      expect(cubit.state.precheck, same(module.precheckResult));
      await cubit.close();
    });

    test('finalize_unknown_error_shows_fallback_not_server_message', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeError = const AppException(
          'SYSTEM_ERROR',
          serverMessage: 'Sales checkout finalize failed.',
        );
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.failure);
      expect(cubit.state.attemptErrorMessage, 'Không thể hoàn tất đơn.');
      await cubit.close();
    });

    test('finalize_no_permission_shows_6_4_message', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeError = const AppException('NO_PERMISSION');
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(cubit.state.attemptErrorMessage, 'Bạn không còn quyền hoàn tất đơn.');
      await cubit.close();
    });

    test('finalize_network_error_recovers_via_get_checkout_result', () async {
      // Repository đã đổi NETWORK_ERROR của finalize thành UNCERTAIN_RESULT (Q6).
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeError = const AppException('UNCERTAIN_RESULT');
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.succeeded);
      expect(module.finalizeCalls, hasLength(1));
      expect(module.getResultCalls, hasLength(1));
      await cubit.close();
    });

    test('recover_keeps_trying_on_network_error', () async {
      final module = FakeSalesCheckoutRepository(precheckResult: _readyResult())
        ..finalizeError = const AppException('UNCERTAIN_RESULT')
        ..getResultResults.addAll([
          const AppException('NETWORK_ERROR'),
          const AppException('DEPENDENCY_UNAVAILABLE'),
        ]);
      final cubit = _cubit(module: module);

      await cubit.finalizeCheckout();

      expect(module.getResultCalls, hasLength(3));
      expect(cubit.state.attemptStatus, SalesCheckoutAttemptStatus.succeeded);
      await cubit.close();
    });

    test('precheck_checkout_blocked_shows_6_4_message', () async {
      final module = FakeSalesCheckoutRepository()
        ..precheckError = const AppException('CHECKOUT_BLOCKED', serverMessage: 'raw english');
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.errorMessage, 'Đơn chưa đủ điều kiện thanh toán.');
      await cubit.close();
    });

    test('precheck_network_error_shows_dependency_message', () async {
      final module = FakeSalesCheckoutRepository()
        ..precheckError = const AppException('NETWORK_ERROR');
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(
        cubit.state.errorMessage,
        'Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại.',
      );
      await cubit.close();
    });

    test('precheck_system_error_shows_fallback', () async {
      final module = FakeSalesCheckoutRepository()
        ..precheckError = const AppException('SYSTEM_ERROR', serverMessage: 'boom');
      final cubit = _cubit(module: module);

      await cubit.precheckNow();

      expect(cubit.state.errorMessage, 'Không thể kiểm tra thanh toán. Vui lòng thử lại.');
      await cubit.close();
    });
  });
}

SalesCheckoutCubit _cubit({
  required FakeSalesCheckoutRepository module,
  Duration debounceDuration = Duration.zero,
  bool isWalkIn = false,
}) {
  return SalesCheckoutCubit(
    args: _draftArgs(isWalkIn: isWalkIn),
    repository: module,
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
