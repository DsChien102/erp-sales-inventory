import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart' hide SalesOrderLifecycleStatus;
import 'package:vet45_shared_application/application.dart';

void main() {
  const refundPlan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -400000,
    collectAmountMinor: 0,
    refundAmountMinor: 400000,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 150000,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 150000,
    remainderCollectMinor: 0,
    remainderRefundMinor: 400000,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  const collectPlan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: 300000,
    collectAmountMinor: 300000,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 200000,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 200000,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 300000,
    remainderRefundMinor: 0,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  const zeroPlan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: 0,
    collectAmountMinor: 0,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 0,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  ReturnExchangeValuationDto valuationFor(ReturnExchangeSettlementPlanDto plan) {
    return ReturnExchangeValuationDto(
      returnValue: MoneyDto(
        amountMinor: plan.refundAmountMinor + plan.collectAmountMinor + 100000,
        currencyCode: 'VND',
      ),
      exchangeValue: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      settlementDifference: MoneyDto(
        amountMinor: plan.netDifferenceMinor,
        currencyCode: 'VND',
      ),
      settlementPlan: plan,
      sourceOrderVersion: plan.sourceOrderVersion,
    );
  }

  ReturnExchangeDetailDto detail({
    int version = 2,
    ReturnExchangeStatus status = ReturnExchangeStatus.draft,
    ReturnExchangeSettlementPlanDto plan = refundPlan,
  }) {
    final valuation = valuationFor(plan);
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
      confirmedByActorId: null,
      confirmedAt: null,
      completedAt: null,
      lines: const <ReturnExchangeDetailLineDto>[],
      valuation: valuation,
      settlementPlan: plan,
      completionReady: false,
    );
  }

  SalesReturnExchangeSettlementCubit build(
    _RecordingSalesModule module, {
    List<String> attemptIds = const ['attempt-1', 'attempt-2'],
  }) {
    final ids = attemptIds.iterator;
    return SalesReturnExchangeSettlementCubit(
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

  test('loadAndEvaluate loads detail before evaluate with source version', () async {
    final module = _RecordingSalesModule(detail: detail());
    final cubit = build(module);
    addTearDown(cubit.close);

    await cubit.loadAndEvaluate();

    expect(module.queries, hasLength(3));
    expect(module.queries[0], isA<GetReturnExchangeDetailQuery>());
    expect(module.queries[1], isA<GetSalesOrderDetailQuery>());
    expect(module.queries[2], isA<EvaluateReturnPricingImpactQuery>());
    final evaluate = module.queries[2] as EvaluateReturnPricingImpactQuery;
    expect(evaluate.returnExchangeId, 'return-1');
    expect(evaluate.expectedSourceVersion, 7);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.ready);
    expect(cubit.state.orderNumber, 'DH-000129');
    expect(cubit.state.customerDisplayName, 'Nguyễn Văn An');
    expect(cubit.state.draftVersion, 2);
    expect(cubit.state.settlement?.storeRefundMinor, 400000);
    expect(cubit.state.settlement?.customerCollectMinor, 0);
    expect(cubit.state.settlement?.receivableReverseMinor, 150000);
  });

  test('maps collect and zero plans from backend DTO amounts only', () async {
    final collect = build(
      _RecordingSalesModule(
        detail: detail(plan: collectPlan),
        valuation: valuationFor(collectPlan),
      ),
    );
    addTearDown(collect.close);
    await collect.loadAndEvaluate();
    expect(collect.state.settlement?.customerCollectMinor, 300000);
    expect(collect.state.settlement?.storeRefundMinor, 0);
    expect(collect.state.settlement?.receivableCreateMinor, 200000);

    final zero = build(
      _RecordingSalesModule(
        detail: detail(plan: zeroPlan),
        valuation: valuationFor(zeroPlan),
      ),
    );
    addTearDown(zero.close);
    await zero.loadAndEvaluate();
    expect(zero.state.settlement?.netDifferenceMinor, 0);
    expect(zero.state.settlement?.storeRefundMinor, 0);
    expect(zero.state.settlement?.customerCollectMinor, 0);
  });

  test(
    'state derives effective settlement from valuation plan when cached settlement is absent',
    () {
      final state = SalesReturnExchangeSettlementState(
        orderId: 'order-1',
        returnExchangeId: 'return-1',
        valuation: valuationFor(refundPlan),
        status: SalesReturnExchangeSettlementStatus.ready,
      );

      expect(state.effectiveSettlement?.storeRefundMinor, 400000);
      expect(state.effectiveSettlement?.receivableReverseMinor, 150000);
      expect(state.canConfirm, isTrue);
    },
  );

  test('blocked detail or RETURN_EXCHANGE_BLOCKED stays blocked', () async {
    final blockedDetail = build(
      _RecordingSalesModule(
        detail: detail(status: ReturnExchangeStatus.blocked),
      ),
    );
    addTearDown(blockedDetail.close);
    await blockedDetail.loadAndEvaluate();
    expect(blockedDetail.state.status, SalesReturnExchangeSettlementStatus.blocked);
    expect(blockedDetail.state.canConfirm, isFalse);

    final blockedEval = build(
      _RecordingSalesModule(
        detail: detail(),
        evaluateError: const SalesContractException(
          'RETURN_EXCHANGE_BLOCKED',
          message: 'Không đủ điều kiện quyết toán.',
          details: {
            'blockers': [
              SalesBlockerDto(
                code: 'WINDOW_EXPIRED',
                message: 'Hết hạn đổi/trả.',
              ),
            ],
          },
        ),
      ),
    );
    addTearDown(blockedEval.close);
    await blockedEval.loadAndEvaluate();
    expect(blockedEval.state.status, SalesReturnExchangeSettlementStatus.blocked);
    expect(blockedEval.state.blockers.single.code, 'WINDOW_EXPIRED');
  });

  test('confirm dispatches immutable attempt once; double tap is ignored', () async {
    final module = _RecordingSalesModule(detail: detail());
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    final first = cubit.confirm();
    final second = cubit.confirm();
    final outcomes = await Future.wait([first, second]);

    expect(outcomes.whereType<SalesReturnExchangeResult>(), hasLength(1));
    expect(module.commands.whereType<ConfirmReturnExchangeCommand>(), hasLength(1));
    final command = module.commands.single as ConfirmReturnExchangeCommand;
    expect(command.expectedVersion, 2);
    expect(command.idempotencyKey, 'return-exchange:confirm:attempt-1');
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.success);
  });

  test('processing result and IMPACT_PENDING navigate as processing', () async {
    final processing = build(
      _RecordingSalesModule(
        detail: detail(),
        confirmResult: const ReturnExchangeResultDto(
          returnExchangeId: 'return-1',
          salesOrderId: 'order-1',
          version: 3,
          status: ReturnExchangeStatus.processing,
        ),
      ),
    );
    addTearDown(processing.close);
    await processing.loadAndEvaluate();
    final processingOutcome = await processing.confirm();
    expect(processingOutcome?.kind, SalesReturnExchangeResultKind.processing);
    expect(
      processing.state.status,
      SalesReturnExchangeSettlementStatus.processing,
    );

    final pending = build(
      _RecordingSalesModule(
        detail: detail(),
        commandErrorsQueue: const [SalesContractException('IMPACT_PENDING')],
      ),
    );
    addTearDown(pending.close);
    await pending.loadAndEvaluate();
    final pendingOutcome = await pending.confirm();
    expect(pendingOutcome?.kind, SalesReturnExchangeResultKind.processing);
    expect(pending.state.status, SalesReturnExchangeSettlementStatus.processing);
  });

  test('STALE_VERSION reloads detail then requires new confirmation', () async {
    final module = _RecordingSalesModule(
      detail: detail(),
      commandErrorsQueue: const [SalesContractException('STALE_VERSION')],
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.stale);
    expect(module.queries.whereType<GetReturnExchangeDetailQuery>().length, 2);
    expect(module.commands, hasLength(1));
    expect(cubit.state.canConfirm, isTrue);
  });

  test('DEPENDENCY_UNAVAILABLE reuses confirm attempt on retry', () async {
    final module = _RecordingSalesModule(
      detail: detail(),
      commandErrorsQueue: const [
        SalesContractException('DEPENDENCY_UNAVAILABLE'),
        null,
      ],
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(
      cubit.state.status,
      SalesReturnExchangeSettlementStatus.retryableFailure,
    );

    final outcome = await cubit.confirm();
    expect(outcome?.kind, SalesReturnExchangeResultKind.confirmed);
    expect(module.commands, hasLength(2));
    expect(
      (module.commands[0] as ConfirmReturnExchangeCommand).idempotencyKey,
      (module.commands[1] as ConfirmReturnExchangeCommand).idempotencyKey,
    );
  });

  test('permission failure is not retryable', () async {
    final module = _RecordingSalesModule(
      detail: detail(),
      commandErrorsQueue: const [SalesContractException('PERMISSION_DENIED')],
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.failure);
  });

  test('debt offset dynamic calculations follow state and authoritative amounts', () {
    const debtPlan = ReturnExchangeSettlementPlanDto(
      currencyCode: 'VND',
      netDifferenceMinor: -2350000,
      collectAmountMinor: 0,
      refundAmountMinor: 2350000,
      receivableCreateAmountMinor: 0,
      receivableReverseAmountMinor: 1200000,
      processedCollectMinor: 0,
      processedRefundMinor: 0,
      pendingReceivableCreateMinor: 0,
      pendingReceivableReverseMinor: 1200000,
      remainderCollectMinor: 0,
      remainderRefundMinor: 2350000,
      sourceOrderVersion: 1,
      sourceSettlementVersion: 1,
    );

    final withOffset = SalesReturnExchangeSettlementState(
      orderId: 'order-1',
      returnExchangeId: 'return-1',
      valuation: valuationFor(debtPlan),
      status: SalesReturnExchangeSettlementStatus.ready,
      offsetDebt: true,
    );

    expect(withOffset.actualOffsetMinor, 1200000);
    expect(withOffset.effectiveRefundMinor, 1150000);
    expect(withOffset.remainingDebtMinor, 0);

    final withoutOffset = withOffset.copyWith(offsetDebt: false);
    expect(withoutOffset.actualOffsetMinor, 0);
    expect(withoutOffset.effectiveRefundMinor, 2350000);
    expect(withoutOffset.remainingDebtMinor, 1200000);
  });

  test('updateOffsetDebt toggles state on the cubit', () {
    final cubit = build(_RecordingSalesModule(detail: detail(plan: refundPlan)));
    addTearDown(cubit.close);

    expect(cubit.state.offsetDebt, isTrue);
    cubit.updateOffsetDebt(false);
    expect(cubit.state.offsetDebt, isFalse);
    cubit.updateOffsetDebt(true);
    expect(cubit.state.offsetDebt, isTrue);
  });
}

final class _RecordingSalesModule implements ISalesModule {
  _RecordingSalesModule({
    required this.detail,
    ReturnExchangeValuationDto? valuation,
    this.evaluateError,
    this.confirmResult,
    this.commandErrorsQueue = const <Object?>[],
  }) : valuation = valuation ?? detail.valuation;

  final ReturnExchangeDetailDto detail;
  final ReturnExchangeValuationDto valuation;
  final Object? evaluateError;
  final ReturnExchangeResultDto? confirmResult;
  final List<Object?> commandErrorsQueue;
  int _commandCall = 0;

  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetReturnExchangeDetailQuery) return detail as TResult;
    if (query is GetSalesOrderDetailQuery) {
      return SalesOrderDetailDto(
        order: SalesOrderDto(
          salesOrderId: detail.result.salesOrderId,
          orderNumber: 'DH-000129',
          version: 1,
          lifecycleStatus: SalesOrderLifecycleStatus.completed,
          lockStatus: SalesOrderLockStatus.unlocked,
          total: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        ),
        committedAt: DateTime.utc(2026, 1, 1),
        store: const StoreSnapshotDto(
          storeId: 'store-1',
          storeCode: 'ST01',
          displayName: 'Cửa hàng chính',
        ),
        seller: const ActorSnapshotDto(
          actorId: 'seller-1',
          displayName: 'Nhân viên bán hàng',
        ),
        customer: const CustomerSnapshotDto(
          customerId: 'cust-1',
          displayName: 'Nguyễn Văn An',
        ),
        lines: const [],
      ) as TResult;
    }
    if (query is EvaluateReturnPricingImpactQuery) {
      final error = evaluateError;
      if (error != null) throw error;
      return valuation as TResult;
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    final index = _commandCall++;
    final error = index < commandErrorsQueue.length ? commandErrorsQueue[index] : null;
    if (error != null) throw error;
    if (command is ConfirmReturnExchangeCommand) {
      return (confirmResult ??
              ReturnExchangeResultDto(
                returnExchangeId: detail.result.returnExchangeId,
                salesOrderId: detail.result.salesOrderId,
                version: detail.result.version + 1,
                status: ReturnExchangeStatus.confirmed,
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
