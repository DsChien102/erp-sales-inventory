import '../../../iam/support/iam_test_session.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/presentation.dart' hide SalesOrderLifecycleStatus;
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

import '../../support/fake_return_exchange_repository.dart';
import '../../support/fake_sales_order_repository.dart';

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
    _Repos repos, {
    List<String> attemptIds = const ['attempt-1', 'attempt-2'],
  }) {
    final ids = attemptIds.iterator;
    return SalesReturnExchangeSettlementCubit(
      orderId: 'order-1',
      returnExchangeId: 'return-1',
      returnExchangeRepository: repos.returnExchange,
      orderRepository: repos.orders,
      session: testSessionController(tenantId: 'tenant-1', userId: 'actor-1'),
      attemptFactory: SalesReturnExchangeAttemptFactory(
        newAttemptId: () {
          ids.moveNext();
          return ids.current;
        },
      ),
    );
  }

  test('loadAndEvaluate loads detail before evaluate with source version', () async {
    final repos = _Repos(detail: detail());
    final cubit = build(repos);
    addTearDown(cubit.close);

    await cubit.loadAndEvaluate();

    expect(repos.calls, hasLength(3));
    expect(repos.calls[0], 'returnExchangeDetail');
    expect(repos.calls[1], 'orderDetail');
    expect(repos.calls[2], 'evaluate');
    final evaluate = repos.returnExchange.evaluateCalls.single;
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

  test('settlement_default_method_cash', () async {
    const initial = SalesReturnExchangeSettlementState(
      orderId: 'order-1',
      returnExchangeId: 'return-1',
    );
    expect(initial.paymentMethod, SalesPaymentMethod.cash);

    final repos = _Repos(detail: detail(plan: collectPlan));
    final cubit = build(repos);
    addTearDown(cubit.close);

    await cubit.loadAndEvaluate();
    expect(cubit.state.paymentMethod, SalesPaymentMethod.cash);
  });

  test('walk-in collect cannot leave an outstanding balance as debt', () async {
    final repos = _Repos(
      detail: detail(plan: collectPlan),
      valuation: valuationFor(collectPlan),
      walkIn: true,
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(cubit.state.isWalkIn, isTrue);
    expect(cubit.state.canConfirm, isTrue);

    cubit.updateSettledNow(100000);
    cubit.updatePaymentDueDate(DateTime(2026, 9, 30));

    expect(cubit.state.canConfirm, isFalse);
    expect(await cubit.confirm(), isNull);
    expect(repos.returnExchange.confirmCalls, isEmpty);
  });

  test('identified customer may defer collect shortfall with a due date', () async {
    final cubit = build(
      _Repos(
        detail: detail(plan: collectPlan),
        valuation: valuationFor(collectPlan),
      ),
    );
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(cubit.state.isWalkIn, isFalse);
    cubit.updateSettledNow(100000);
    expect(cubit.state.canConfirm, isFalse);
    cubit.updatePaymentDueDate(DateTime(2026, 9, 30));
    expect(cubit.state.canConfirm, isTrue);
  });

  test('maps collect and zero plans from backend DTO amounts only', () async {
    final collect = build(
      _Repos(
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
      _Repos(
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
      _Repos(
        detail: detail(status: ReturnExchangeStatus.blocked),
      ),
    );
    addTearDown(blockedDetail.close);
    await blockedDetail.loadAndEvaluate();
    expect(blockedDetail.state.status, SalesReturnExchangeSettlementStatus.blocked);
    expect(blockedDetail.state.canConfirm, isFalse);

    final blockedEval = build(
      _Repos(
        detail: detail(),
        evaluateError: const AppException(
          'RETURN_EXCHANGE_BLOCKED',
          serverMessage: 'Không đủ điều kiện quyết toán.',
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
    final repos = _Repos(detail: detail());
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    final first = cubit.confirm();
    final second = cubit.confirm();
    final outcomes = await Future.wait([first, second]);

    expect(outcomes.whereType<SalesReturnExchangeResult>(), hasLength(1));
    expect(repos.returnExchange.confirmCalls, hasLength(1));
    final command = repos.returnExchange.confirmCalls.single;
    expect(command.expectedVersion, 2);
    expect(command.idempotencyKey, 'return-exchange:confirm:attempt-1');
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.success);
  });

  test('processing result and IMPACT_PENDING navigate as processing', () async {
    final processing = build(
      _Repos(
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
      _Repos(
        detail: detail(),
        commandErrorsQueue: const [AppException('IMPACT_PENDING')],
      ),
    );
    addTearDown(pending.close);
    await pending.loadAndEvaluate();
    final pendingOutcome = await pending.confirm();
    expect(pendingOutcome?.kind, SalesReturnExchangeResultKind.processing);
    expect(pending.state.status, SalesReturnExchangeSettlementStatus.processing);
  });

  test('PRICE_CHANGED marks settlement stale without evaluating again', () async {
    final repos = _Repos(
      detail: detail(),
      evaluateError: const AppException('PRICE_CHANGED'),
    );
    final cubit = build(repos);
    addTearDown(cubit.close);

    await cubit.loadAndEvaluate();

    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.stale);
    expect(
      cubit.state.screenError,
      'Giá món đổi đã thay đổi. Vui lòng quay lại màn đổi/trả để cập nhật giá.',
    );
    expect(repos.returnExchange.evaluateCalls, hasLength(1));
  });

  test('PRICE_CHANGED on confirm marks stale without evaluating again', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [AppException('PRICE_CHANGED')],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    final evaluationsBefore = repos.returnExchange.evaluateCalls.length;

    expect(await cubit.confirm(), isNull);

    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.stale);
    expect(
      cubit.state.screenError,
      'Giá món đổi đã thay đổi. Vui lòng quay lại màn đổi/trả để cập nhật giá.',
    );
    expect(
      repos.returnExchange.evaluateCalls,
      hasLength(evaluationsBefore),
    );
    expect(repos.returnExchange.confirmCalls, hasLength(1));
  });

  test('STALE_VERSION reloads detail then requires new confirmation', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [AppException('STALE_VERSION')],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.stale);
    expect(repos.returnExchange.detailCalls.length, 2);
    expect(repos.returnExchange.confirmCalls, hasLength(1));
    expect(cubit.state.canConfirm, isTrue);
  });

  test('DEPENDENCY_UNAVAILABLE reuses confirm attempt on retry', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [
        AppException('DEPENDENCY_UNAVAILABLE'),
        null,
      ],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(
      cubit.state.status,
      SalesReturnExchangeSettlementStatus.retryableFailure,
    );

    final outcome = await cubit.confirm();
    expect(outcome?.kind, SalesReturnExchangeResultKind.confirmed);
    expect(repos.returnExchange.confirmCalls, hasLength(2));
    expect(
      repos.returnExchange.confirmCalls[0].idempotencyKey,
      repos.returnExchange.confirmCalls[1].idempotencyKey,
    );
  });

  test('permission failure is not retryable', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [AppException('NO_PERMISSION')],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.failure);
  });

  test('refund plan keeps the server split of refund and order debt reduction', () {
    const plan = ReturnExchangeSettlementPlanDto(
      currencyCode: 'VND',
      netDifferenceMinor: -400000,
      collectAmountMinor: 0,
      refundAmountMinor: 100000,
      receivableCreateAmountMinor: 0,
      receivableReverseAmountMinor: 300000,
      processedCollectMinor: 0,
      processedRefundMinor: 0,
      pendingReceivableCreateMinor: 0,
      pendingReceivableReverseMinor: 0,
      remainderCollectMinor: 0,
      remainderRefundMinor: 100000,
      sourceOrderVersion: 1,
      sourceSettlementVersion: 1,
    );

    final state = SalesReturnExchangeSettlementState(
      orderId: 'order-1',
      returnExchangeId: 'return-1',
      valuation: valuationFor(plan),
      status: SalesReturnExchangeSettlementStatus.ready,
    );

    expect(state.effectiveSettlement!.storeRefundMinor, 100000);
    expect(state.effectiveSettlement!.receivableReverseMinor, 300000);
    expect(state.canConfirm, isTrue);
  });

  test('confirm_retry_after_system_error_reuses_command_id', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [
        AppException('SYSTEM_ERROR', serverMessage: 'Temporary db error'),
        null,
      ],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(
      cubit.state.status,
      SalesReturnExchangeSettlementStatus.retryableFailure,
    );

    final outcome = await cubit.confirm();
    expect(outcome?.kind, SalesReturnExchangeResultKind.confirmed);
    expect(repos.returnExchange.confirmCalls, hasLength(2));
    final cmd1 = repos.returnExchange.confirmCalls[0];
    final cmd2 = repos.returnExchange.confirmCalls[1];
    expect(cmd1.commandId, cmd2.commandId);
    expect(cmd1.idempotencyKey, cmd2.idempotencyKey);
  });

  test('settlement_error_fallback', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [
        AppException('UNKNOWN_ERROR_CODE', serverMessage: 'Server blow up'),
      ],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.failure);
    expect(
      cubit.state.screenError,
      'Không quyết toán được phiếu đổi/trả. Vui lòng thử lại.',
    );
  });

  test('settlement_blocked_reads_details_blockers', () async {
    final repos = _Repos(
      detail: detail(),
      evaluateError: const AppException(
        'RETURN_EXCHANGE_BLOCKED',
        serverMessage: 'Blocked',
        details: {
          'blockers': [
            <String, dynamic>{
              'code': 'WINDOW_EXPIRED',
              'message': 'Expired',
              'field': 'lines',
            },
          ],
        },
      ),
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.blocked);
    expect(cubit.state.blockers, hasLength(1));
    expect(cubit.state.blockers.single.code, 'WINDOW_EXPIRED');
    expect(cubit.state.blockers.single.message, 'Không thể đổi/trả.');
  });

  test('settlement_blocked_without_details_is_empty', () async {
    final repos = _Repos(
      detail: detail(),
      evaluateError: const AppException(
        'RETURN_EXCHANGE_BLOCKED',
        serverMessage: 'Blocked',
      ),
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.blocked);
    expect(cubit.state.blockers, isEmpty);
    expect(cubit.state.screenError, 'Không thể đổi/trả.');
  });

  test('confirm_blocked_is_failure', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [
        AppException('RETURN_EXCHANGE_BLOCKED', serverMessage: 'Blocked'),
      ],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(await cubit.confirm(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.failure);
    expect(cubit.state.screenError, 'Không thể đổi/trả.');
  });

  // --- T6-2c: cấn trừ ---
  ReturnExchangeOffsetCandidateDto cand(String id, String code, int out) =>
      ReturnExchangeOffsetCandidateDto(
        salesOrderId: id,
        orderCode: code,
        completedAt: DateTime.utc(2026, 11, 1),
        outstandingMinor: out,
        offsetAmountMinor: 500000,
        overdueDays: 0,
        settlementVersion: 4,
      );

  ReturnExchangeSettlementPlanDto offsetPlan(
    List<ReturnExchangeOffsetCandidateDto> candidates,
  ) => ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -500000,
    collectAmountMinor: 0,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 500000,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
    offsetAmountMinor: 500000,
    offsetCandidates: candidates,
  );

  final twoCandidates = [
    cand('o2', 'DH-002', 2000000),
    cand('o3', 'DH-003', 6000000),
  ];

  test('load selects all offset candidates', () async {
    final repos = _Repos(detail: detail(plan: offsetPlan(twoCandidates)));
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    expect(cubit.state.selectedOffsetOrderIds, {'o2', 'o3'});
    expect(cubit.state.offsetPreview!.offsets.map((o) => o.amountMinor), [500000, 0]);
  });

  test('toggle recomputes preview', () async {
    final repos = _Repos(detail: detail(plan: offsetPlan(twoCandidates)));
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();

    cubit.toggleOffsetTarget('o2');
    expect(cubit.state.offsetPreview!.offsets.map((o) => o.amountMinor), [0, 500000]);
    cubit.toggleOffsetTarget('o3');
    expect(cubit.state.offsetPreview!.refundMinor, 500000);
    cubit.toggleOffsetTarget('o2');
    expect(cubit.state.offsetPreview!.offsets.map((o) => o.amountMinor), [500000, 0]);
  });

  test('confirm sends targets with positive share', () async {
    final repos = _Repos(detail: detail(plan: offsetPlan(twoCandidates)));
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    await cubit.confirm();
    expect(repos.returnExchange.confirmCalls.single.offsetTargetOrderIds, ['o2']);
  });

  test('confirm sends empty targets when none selected', () async {
    final repos = _Repos(detail: detail(plan: offsetPlan(twoCandidates)));
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    cubit.toggleOffsetTarget('o2');
    cubit.toggleOffsetTarget('o3');
    await cubit.confirm();
    expect(repos.returnExchange.confirmCalls.single.offsetTargetOrderIds, isEmpty);
  });

  test('stale with offset targets shows receivableChanged without reload', () async {
    final repos = _Repos(
      detail: detail(plan: offsetPlan(twoCandidates)),
      commandErrorsQueue: const [AppException('STALE_VERSION')],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    expect(await cubit.confirm(), isNull);

    expect(repos.returnExchange.evaluateCalls, hasLength(1));
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.stale);
    expect(cubit.state.receivableChanged, isTrue);
    expect(
      cubit.state.screenError,
      'Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.',
    );
  });

  test('reload after stale reselects new candidates', () async {
    final repos = _Repos(
      detail: detail(plan: offsetPlan(twoCandidates)),
      commandErrorsQueue: const [AppException('STALE_VERSION')],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    await cubit.confirm();

    repos.returnExchange.evaluateResults.add(
      valuationFor(offsetPlan([cand('o3', 'DH-003', 6000000)])),
    );
    await cubit.loadAndEvaluate();
    expect(cubit.state.selectedOffsetOrderIds, {'o3'});
    expect(cubit.state.receivableChanged, isFalse);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.ready);
  });

  test('OFFSET_TARGET_INVALID shows code message', () async {
    final repos = _Repos(
      detail: detail(plan: offsetPlan(twoCandidates)),
      commandErrorsQueue: const [AppException('OFFSET_TARGET_INVALID')],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    await cubit.confirm();
    expect(cubit.state.screenError, 'Đơn được chọn để cấn trừ không hợp lệ.');
    expect(cubit.state.receivableChanged, isTrue);
    expect(repos.returnExchange.evaluateCalls, hasLength(1));
  });

  test('retry keeps attempt when targets unchanged', () async {
    final repos = _Repos(
      detail: detail(plan: offsetPlan(twoCandidates)),
      commandErrorsQueue: const [AppException('NETWORK_ERROR'), null],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    await cubit.confirm();
    await cubit.confirm();
    final calls = repos.returnExchange.confirmCalls;
    expect(calls, hasLength(2));
    expect(calls[0].idempotencyKey, calls[1].idempotencyKey);
  });

  test('toggle after error makes new attempt', () async {
    final repos = _Repos(
      detail: detail(plan: offsetPlan(twoCandidates)),
      commandErrorsQueue: const [AppException('NETWORK_ERROR'), null],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    await cubit.confirm();
    cubit.toggleOffsetTarget('o2');
    await cubit.confirm();
    final calls = repos.returnExchange.confirmCalls;
    expect(calls[0].idempotencyKey, isNot(calls[1].idempotencyKey));
    expect(calls[1].offsetTargetOrderIds, ['o3']);
  });

  test('stale without offset targets keeps old behaviour', () async {
    final repos = _Repos(
      detail: detail(),
      commandErrorsQueue: const [AppException('STALE_VERSION')],
    );
    final cubit = build(repos);
    addTearDown(cubit.close);
    await cubit.loadAndEvaluate();
    await cubit.confirm();
    expect(repos.returnExchange.evaluateCalls, hasLength(2));
    expect(cubit.state.receivableChanged, isFalse);
    expect(cubit.state.status, SalesReturnExchangeSettlementStatus.stale);
  });
}

/// Ghi thứ tự lời gọi giữa hai repository (`calls`) và trả lỗi theo hàng đợi cho `confirm`.
final class _Repos {
  _Repos({
    required ReturnExchangeDetailDto detail,
    ReturnExchangeValuationDto? valuation,
    Object? evaluateError,
    ReturnExchangeResultDto? confirmResult,
    List<Object?> commandErrorsQueue = const <Object?>[],
    bool walkIn = false,
  }) {
    returnExchange = _OrderedReturnExchangeRepository(calls, commandErrorsQueue)
      ..detailResult = detail
      ..evaluateResult = valuation ?? detail.valuation
      ..evaluateError = evaluateError
      ..confirmResult = confirmResult;
    orders = _OrderedOrderRepository(calls)
      ..detailResult = SalesOrderDetailDto(
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
        customer: walkIn
            ? null
            : const CustomerSnapshotDto(
                customerId: 'cust-1',
                displayName: 'Nguyễn Văn An',
              ),
        lines: const [],
      );
  }

  final List<String> calls = <String>[];
  late final FakeReturnExchangeRepository returnExchange;
  late final FakeSalesOrderRepository orders;
}

final class _OrderedReturnExchangeRepository extends FakeReturnExchangeRepository {
  _OrderedReturnExchangeRepository(this._calls, this._confirmErrors);

  final List<String> _calls;
  final List<Object?> _confirmErrors;

  @override
  Future<ReturnExchangeDetailDto> getDetail({required String returnExchangeId}) {
    _calls.add('returnExchangeDetail');
    return super.getDetail(returnExchangeId: returnExchangeId);
  }

  @override
  Future<ReturnExchangeValuationDto> evaluate({
    required String returnExchangeId,
    required int expectedSourceVersion,
  }) {
    _calls.add('evaluate');
    return super.evaluate(
      returnExchangeId: returnExchangeId,
      expectedSourceVersion: expectedSourceVersion,
    );
  }

  @override
  Future<ReturnExchangeResultDto> confirm(ReturnExchangeConfirmRequest request) {
    final index = confirmCalls.length;
    confirmError = index < _confirmErrors.length ? _confirmErrors[index] : null;
    return super.confirm(request);
  }
}

final class _OrderedOrderRepository extends FakeSalesOrderRepository {
  _OrderedOrderRepository(this._calls);

  final List<String> _calls;

  @override
  Future<SalesOrderDetailDto> getDetail({required String salesOrderId}) {
    _calls.add('orderDetail');
    return super.getDetail(salesOrderId: salesOrderId);
  }
}
