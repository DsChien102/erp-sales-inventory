import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart'
    hide SalesOrderLifecycleStatus;
import 'package:vet45_shared_application/application.dart';

void main() {
  SalesReturnExchangeDetailCubit build(
    _RecordingSalesModule module, {
    List<String> attemptIds = const ['attempt-1', 'attempt-2'],
  }) {
    final ids = attemptIds.iterator;
    return SalesReturnExchangeDetailCubit(
      orderId: 'order-1',
      returnExchangeId: 'return-1',
      salesModule: module,
      executionContext: const _ExecutionContext(),
      attemptFactory: SalesReturnExchangeAttemptFactory(
        newAttemptId: () {
          ids.moveNext();
          return ids.current;
        },
      ),
    );
  }

  test('load composes detail, order and return summary', () async {
    final module = _RecordingSalesModule();
    final cubit = build(module);
    addTearDown(cubit.close);

    await cubit.load();

    expect(module.queries.whereType<GetReturnExchangeDetailQuery>(), hasLength(1));
    expect(module.queries.whereType<GetSalesOrderDetailQuery>(), hasLength(1));
    expect(
      module.queries.whereType<GetSalesOrderReturnSummaryQuery>(),
      hasLength(1),
    );
    expect(cubit.state.status, SalesReturnExchangeDetailStatus.loaded);
    expect(cubit.state.detail?.referenceNumber, 'RE-1');
    expect(cubit.state.orderNumber, 'SO-1');
    expect(cubit.state.customerDisplayName, 'Khách A');
    expect(cubit.state.canComplete, isFalse);
  });

  test('NOT_FOUND and PROJECTION_PENDING map to dedicated statuses', () async {
    final notFound = build(
      _RecordingSalesModule(
        detailError: const SalesContractException('NOT_FOUND'),
      ),
    );
    addTearDown(notFound.close);
    await notFound.load();
    expect(notFound.state.status, SalesReturnExchangeDetailStatus.notFound);

    final pending = build(
      _RecordingSalesModule(
        detailError: const SalesContractException('PROJECTION_PENDING'),
      ),
    );
    addTearDown(pending.close);
    await pending.load();
    expect(pending.state.status, SalesReturnExchangeDetailStatus.projectionPending);
  });

  test('completeIfReady does nothing when completionReady is false', () async {
    final module = _RecordingSalesModule();
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    expect(await cubit.completeIfReady(), isFalse);
    expect(module.commands, isEmpty);
  });

  test('completeIfReady dispatches complete attempt then reloads', () async {
    final module = _RecordingSalesModule(
      detail: _detail(completionReady: true, version: 4),
      completeResult: const ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'order-1',
        version: 5,
        status: ReturnExchangeStatus.completed,
      ),
      reloadDetailAfterComplete: _detail(
        completionReady: false,
        version: 5,
        status: ReturnExchangeStatus.completed,
      ),
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state.canComplete, isTrue);
    expect(await cubit.completeIfReady(), isTrue);
    expect(module.commands.whereType<CompleteReturnExchangeCommand>(), hasLength(1));
    final command = module.commands.single as CompleteReturnExchangeCommand;
    expect(command.expectedVersion, 4);
    expect(command.idempotencyKey, 'return-exchange:complete:attempt-1');
    expect(cubit.state.detail?.status, ReturnExchangeStatus.completed);
    expect(
      cubit.state.orderDetail?.order.lifecycleStatus,
      SalesOrderLifecycleStatus.completed,
    );
  });

  test('IMPACT_PENDING during complete keeps processing without false success', () async {
    final module = _RecordingSalesModule(
      detail: _detail(completionReady: true),
      commandErrorsQueue: const [SalesContractException('IMPACT_PENDING')],
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    expect(await cubit.completeIfReady(), isFalse);
    expect(
      cubit.state.status,
      SalesReturnExchangeDetailStatus.projectionPending,
    );
  });

  test('stale generation ignores older load response', () async {
    final gate = Completer<void>();
    final module = _RecordingSalesModule(detailGate: gate);
    final cubit = build(module);
    addTearDown(cubit.close);

    final first = cubit.load();
    await Future<void>.delayed(Duration.zero);
    final second = cubit.load();
    gate.complete();
    await Future.wait<void>([first, second]);

    expect(
      module.queries.whereType<GetReturnExchangeDetailQuery>().length,
      greaterThanOrEqualTo(2),
    );
    expect(cubit.state.status, SalesReturnExchangeDetailStatus.loaded);
  });
}

ReturnExchangeDetailDto _detail({
  bool completionReady = false,
  int version = 2,
  ReturnExchangeStatus status = ReturnExchangeStatus.confirmed,
}) {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -100000,
    collectAmountMinor: 0,
    refundAmountMinor: 100000,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 100000,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );
  const valuation = ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 200000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -100000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 7,
  );
  return ReturnExchangeDetailDto(
    result: ReturnExchangeResultDto(
      returnExchangeId: 'return-1',
      salesOrderId: 'order-1',
      version: version,
      status: status,
    ),
    referenceNumber: 'RE-1',
    entrySource: ReturnExchangeEntrySource.standard,
    createdAt: DateTime.utc(2026, 8, 13),
    confirmedByActorId: 'actor-1',
    confirmedAt: DateTime.utc(2026, 8, 13, 10),
    completedAt: status == ReturnExchangeStatus.completed
        ? DateTime.utc(2026, 8, 13, 11)
        : null,
    lines: const [
      ReturnExchangeDetailLineDto(
        lineId: 'line-1',
        kind: ReturnExchangeLineKind.returnLine,
        product: ProductSnapshotDto(
          productId: 'product-1',
          sku: 'SKU-1',
          displayName: 'Sản phẩm trả',
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: 'unit-1',
          unitCode: 'BOX',
          unitName: 'Hộp',
        ),
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        lineTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        originalSalesOrderLineId: 'sol-1',
        reasonCode: 'DAMAGED',
        conditionCode: 'OPENED',
      ),
    ],
    valuation: valuation,
    settlementPlan: plan,
    completionReady: completionReady,
  );
}

SalesOrderDetailDto _orderDetail() => SalesOrderDetailDto(
  order: SalesOrderDto(
    salesOrderId: 'order-1',
    orderNumber: 'SO-1',
    version: 7,
    lifecycleStatus: SalesOrderLifecycleStatus.completed,
    lockStatus: SalesOrderLockStatus.unlocked,
    total: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
  ),
  committedAt: DateTime.utc(2026, 8, 12),
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Khách A',
  ),
  lines: const [],
);

final class _RecordingSalesModule implements ISalesModule {
  _RecordingSalesModule({
    ReturnExchangeDetailDto? detail,
    this.detailError,
    this.completeResult,
    this.reloadDetailAfterComplete,
    this.commandErrorsQueue = const <Object?>[],
    this.detailGate,
  }) : detail = detail ?? _detail();

  ReturnExchangeDetailDto detail;
  final Object? detailError;
  final ReturnExchangeResultDto? completeResult;
  final ReturnExchangeDetailDto? reloadDetailAfterComplete;
  final List<Object?> commandErrorsQueue;
  final Completer<void>? detailGate;
  int _commandCall = 0;
  int _detailReads = 0;

  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetReturnExchangeDetailQuery) {
      final gate = detailGate;
      if (gate != null) await gate.future;
      _detailReads++;
      final error = detailError;
      if (error != null && _detailReads == 1) throw error;
      if (_detailReads > 1 && reloadDetailAfterComplete != null) {
        return reloadDetailAfterComplete as TResult;
      }
      return detail as TResult;
    }
    if (query is GetSalesOrderDetailQuery) return _orderDetail() as TResult;
    if (query is GetSalesOrderReturnSummaryQuery) {
      return SalesOrderReturnSummaryDto(
            salesOrderId: 'order-1',
            returns: const [],
          )
          as TResult;
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    final index = _commandCall++;
    final error = index < commandErrorsQueue.length ? commandErrorsQueue[index] : null;
    if (error != null) throw error;
    if (command is CompleteReturnExchangeCommand) {
      return (completeResult ??
              ReturnExchangeResultDto(
                returnExchangeId: 'return-1',
                salesOrderId: 'order-1',
                version: detail.result.version + 1,
                status: ReturnExchangeStatus.completed,
              ))
          as TResult;
    }
    throw UnsupportedError('unexpected command ${command.runtimeType}');
  }
}

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'actor-1';
}
