import 'dart:async';

import 'package:erp/features/sales/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart' as app;
import 'package:vet45_shared_application/application.dart';

import '../../support/fake_return_exchange_repository.dart';
import '../../support/fake_sales_cancellation_repository.dart';
import '../../support/fake_sales_order_repository.dart';
import '../../support/fake_sales_payment_repository.dart';
import '../../support/fake_sales_receipt_repository.dart';
import '../../support/sales_contract_error.dart';

void main() {
  group('SalesOrderDetailCubit S16 core', () {
    test('load resolves tenant and actor and dispatches one GetSalesOrderDetailQuery', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final detailQueries = module.orders.detailCalls;
      expect(detailQueries, hasLength(1));
      final query = detailQueries.single;
      expect(query, 'order-1');
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.sourceVersion, 7);
      expect(cubit.state.core?.orderId, 'order-1');
    });

    test('exposes sourceVersion equal to dto.order.version', () async {
      final module = _Repos(detail: _detail(version: 11));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.sourceVersion, 11);
      expect(cubit.state.sourceVersion, module.detail.order.version);
    });

    test('permission denied maps to blocked and does not emit loaded core', () async {
      final module = _Repos.failing(salesContractError('PERMISSION_DENIED'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.core, isNull);
      expect(cubit.state.errorMessage, isNull);
    });

    test('permission denied with null message does not surface raw contract code', () async {
      final module = _Repos.failing(salesContractError('PERMISSION_DENIED'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.errorMessage, isNot(equals('PERMISSION_DENIED')));
    });

    test('query failure clears sourceVersion and currentReceiptId', () async {
      final module = _Repos.succeedThenFail(
        detail: _detail(version: 7),
        error: salesContractError('PERMISSION_DENIED'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.sourceVersion, 7);
      expect(cubit.state.currentReceiptId, 'receipt-1');

      await cubit.refresh();
      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.core, isNull);
      expect(cubit.state.sourceVersion, isNull);
      expect(cubit.state.currentReceiptId, isNull);
      expect(cubit.state.errorMessage, isNull);
    });

    test('data scope denied maps to blocked', () async {
      final module = _Repos.failing(salesContractError('DATA_SCOPE_DENIED'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.core, isNull);
    });

    test('not found maps to notFound', () async {
      final module = _Repos.failing(salesContractError('NOT_FOUND'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.notFound);
      expect(cubit.state.core, isNull);
    });

    test('projection pending maps to retryable pending', () async {
      final module = _Repos.failing(salesContractError('PROJECTION_PENDING'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.projectionPending);
      expect(cubit.state.core, isNull);
    });

    test('transport error maps to error', () async {
      final module = _Repos.failing(salesContractError('TRANSPORT_ERROR', message: 'network down'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.error);
      expect(cubit.state.core, isNull);
      expect(cubit.state.errorMessage, isNull);
    });

    test('malformed contract maps to error', () async {
      final module = _Repos.failing(const FormatException('malformed detail payload'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.error);
      expect(cubit.state.core, isNull);
    });

    test('second refresh generation suppresses first response', () async {
      final module = _Repos.stale();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      final first = cubit.load();
      await module.firstQueryStarted.future;
      final second = cubit.refresh();
      await module.secondQueryStarted.future;

      module.results[1].complete(_detail(version: 9, customerName: 'Khách mới'));
      await second;
      await _drain();
      module.results[0].complete(_detail(version: 1, customerName: 'Khách cũ'));
      await first;
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.requestGeneration, 2);
      expect(cubit.state.sourceVersion, 9);
      expect(cubit.state.core?.customerName, 'Khách mới');
    });
  });

  group('SalesOrderDetailCubit S17–S18 sections', () {
    test('after core success dispatches six dependent queries with shared sourceVersion', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.sourceVersion, 7);

      final paymentSummary = module.payments.summaryCalls.single;
      final settlement = module.payments.settlementCalls.single;
      final transactions = module.payments.transactionsCalls.single;
      final timeline = module.orders.timelineCalls.single;
      final returns = module.orders.returnSummaryCalls.single;
      final actions = module.orders.actionsCalls.single;

      expect(paymentSummary.salesOrderId, 'order-1');
      expect(paymentSummary.expectedSourceVersion, 7);
      expect(settlement.salesOrderId, 'order-1');
      expect(settlement.expectedSourceVersion, 7);
      expect(transactions.salesOrderId, 'order-1');
      expect(transactions.expectedSourceVersion, 7);
      expect(timeline.salesOrderId, 'order-1');
      expect(timeline.expectedSourceVersion, 7);
      expect(returns.salesOrderId, 'order-1');
      expect(returns.expectedSourceVersion, 7);
      expect(actions.salesOrderId, 'order-1');
      expect(actions.expectedSourceVersion, 7);

      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.payment?.paidCashAmountMinor, 400000);
      expect(cubit.state.payment?.paidBankAmountMinor, 600000);
      expect(cubit.state.payment?.dueDateFormatted, '30/08/2026');
      expect(cubit.state.history?.timeline, isNotEmpty);
      expect(cubit.state.history?.returns.single.slipNumber, 'DT-2026-00042');
      expect(cubit.state.actions?.canCancel, isTrue);
      expect(cubit.state.actions?.canReturnExchange, isTrue);
    });

    test('does not await dependents before emitting core loaded', () async {
      final module = _Repos.deferredSections();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      final loadFuture = cubit.load();
      await module.detailStarted.future;
      module.completeDetail(_detail(version: 7));
      await loadFuture;

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.loading);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.loading);
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.loading);
      expect(cubit.state.payment, isNull);
      expect(cubit.state.history, isNull);
      expect(cubit.state.actions, isNull);

      module.completeAllSections();
      await _drain();

      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.loaded);
    });

    test('partial payment failure keeps core and loads history', () async {
      final module = _Repos(
        paymentSummaryError: salesContractError(
          'TRANSPORT_ERROR',
          message: 'pay down',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.core, isNotNull);
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.error);
      // Q4: không hiện câu thô của server ở khối thanh toán.
      expect(cubit.state.paymentErrorMessage, isNull);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.history, isNotNull);
    });

    test('payment_section_permission_denied_is_blocked', () async {
      final module = _Repos(
        settlementError: salesContractError('PERMISSION_DENIED'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.blocked);
      expect(cubit.state.payment, isNull);
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
    });

    test('payment_section_projection_pending', () async {
      final module = _Repos(
        paymentSummaryError: salesContractError('PROJECTION_PENDING'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.projectionPending);
    });

    test('payment_section_error_never_shows_server_message', () async {
      final module = _Repos(
        settlementError: salesContractError(
          'DEPENDENCY_UNAVAILABLE',
          message: 'Sales order read failed.',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.error);
      expect(cubit.state.paymentErrorMessage, isNull);
    });

    test('per-section permission blocked does not clear core', () async {
      final module = _Repos(
        timelineError: salesContractError('PERMISSION_DENIED'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.blocked);
      expect(cubit.state.history, isNull);
    });

    test('section projection pending is retryable without clearing core', () async {
      final module = _Repos(
        settlementError: salesContractError('PROJECTION_PENDING'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.projectionPending);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.loaded);
    });

    test('retryPaymentSection reloads only payment queries', () async {
      final module = _Repos(
        paymentSummaryError: salesContractError(
          'TRANSPORT_ERROR',
          message: 'pay down',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.error);

      module.payments.summaryError = null;
      final beforeSummary = module.payments.summaryCalls.length;
      final beforeSettlement = module.payments.settlementCalls.length;
      final beforeTransactions = module.payments.transactionsCalls.length;
      final beforeTimeline = module.orders.timelineCalls.length;
      await cubit.retryPaymentSection();
      await _drain();

      expect(module.payments.summaryCalls.skip(beforeSummary), hasLength(1));
      expect(module.payments.settlementCalls.skip(beforeSettlement), hasLength(1));
      expect(module.payments.transactionsCalls.skip(beforeTransactions), hasLength(1));
      expect(module.orders.timelineCalls.skip(beforeTimeline), isEmpty);
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.loaded);
    });

    test('transaction load-more error retains existing rows', () async {
      final module = _Repos(
        transactions: _transactionsPage(
          items: [_cashTx(400000)],
          hasMore: true,
          nextCursor: 'cursor-2',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.payment?.transactions, hasLength(1));
      expect(cubit.state.payment?.hasMoreTransactions, isTrue);

      module.payments.transactionsError = salesContractError(
        'TRANSPORT_ERROR',
        message: 'page 2 failed',
      );
      await cubit.loadMoreTransactions();
      await _drain();

      expect(cubit.state.payment?.transactions, hasLength(1));
      expect(cubit.state.payment?.transactionsLoadMoreError, isTrue);
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.loaded);
    });

    test('source-version refresh invalidates dependent section results', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.sourceVersion, 7);
      expect(cubit.state.payment?.paidCashAmountMinor, 400000);
      expect(cubit.state.history?.timeline.single.title, contains('Xác nhận'));

      module.orders.detailResult = _detail(version: 8);
      module.payments.summaryResult = _paymentSummary(paid: 800000, outstanding: 450000);
      module.payments.transactionsResult = _transactionsPage(
        items: [_cashTx(800000)],
        hasMore: false,
      );
      module.orders.timelineResult = _timeline(
        entries: [
          app.SalesOrderTimelineEntryDto(
            eventId: 'event-2',
            eventType: 'payment_recorded',
            occurredAt: DateTime.utc(2026, 8, 13, 4, 0),
            sourceVersion: 8,
            actor: const app.ActorSnapshotDto(actorId: 'seller-1', displayName: 'Minh Anh'),
            description: 'Thanh toán bổ sung',
            amount: const app.MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
          ),
        ],
      );

      await cubit.refresh();
      await _drain();

      expect(cubit.state.sourceVersion, 8);
      expect(cubit.state.payment?.paidCashAmountMinor, 800000);
      expect(cubit.state.history?.timeline.single.description, 'Thanh toán bổ sung');

      final paymentQueries = module.payments.summaryCalls;
      expect(paymentQueries.last.expectedSourceVersion, 8);
      final timelineQueries = module.orders.timelineCalls;
      expect(timelineQueries.last.expectedSourceVersion, 8);
    });
  });

  group('SalesOrderDetailCubit S19 receipt', () {
    test('loads known receipt via GetSalesReceiptQuery with source version', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.currentReceiptId, 'receipt-1');

      await cubit.ensureReceipt();

      final queries = module.receipts.getCalls;
      expect(queries, hasLength(1));
      expect(queries.single.receiptId, 'receipt-1');
      expect(queries.single.expectedSourceVersion, 7);
      expect(module.commands, isEmpty);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
      expect(cubit.state.receiptStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
    });

    test('generates receipt with source version and idempotency when no receipt id', () async {
      final module = _Repos(detail: _detail(currentReceiptId: null));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.currentReceiptId, isNull);

      await cubit.ensureReceipt();

      expect(module.receipts.getCalls, isEmpty);
      expect(module.receipts.generateCalls, hasLength(1));
      final command = module.receipts.generateCalls.single;
      expect(command.salesOrderId, 'order-1');
      expect(command.expectedVersion, 7);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
      expect(cubit.state.currentReceiptId, 'receipt-1');
    });

    test('viewReceipt returns ready typed receipt for route extra', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final receipt = await cubit.viewReceipt();

      expect(receipt, isNotNull);
      expect(receipt!.receiptId, 'receipt-1');
      expect(receipt.document.receiptNumber, 'PBH-20260812-0129');
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
      expect(identical(receipt, cubit.state.receipt.value), isTrue);
    });

    test('viewOriginalReceipt reads the as-sold receipt without the stored receipt flow', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);
      await cubit.load();
      await _drain();

      final document = await cubit.viewOriginalReceipt();

      final query = module.receipts.originalCalls.single;
      expect(query, 'order-1');
      expect(document.receiptNumber, _receipt().document.receiptNumber);
      expect(module.receipts.getCalls, isEmpty);
      expect(module.commands, isEmpty);
    });

    test('prints on the device before recording receipt activity', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);
      final events = <String>[];

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      await cubit.printReceipt((document) async {
        events.add('device:${document.receiptNumber}');
      });

      expect(events, ['device:PBH-20260812-0129']);
      expect(module.receipts.printedCalls, hasLength(1));
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
    });

    test('shares on the device before recording receipt activity', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);
      final events = <String>[];

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      await cubit.shareReceipt((_) async => events.add('device:share'));

      expect(events, ['device:share']);
      expect(module.receipts.sharedCalls, hasLength(1));
    });

    test('device failure sends no audit command and retains receipt', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      await cubit.printReceipt((_) => Future<void>.error(Exception('printer unavailable')));

      expect(module.receipts.printedCalls, isEmpty);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.error);
      expect(cubit.state.receipt.issue, SalesTransactionResultIssue.transportFailure);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.receiptStatus, SalesOrderDetailSectionStatus.error);
    });

    test('audit failure produces activity warning and retains receipt', () async {
      final module = _Repos(
        printedError: Exception('audit unavailable'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      await cubit.printReceipt((_) async {});

      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.activityWarning);
      expect(cubit.state.receipt.hasPrintActivityWarning, isTrue);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.receiptStatus, SalesOrderDetailSectionStatus.loaded);
    });

    test('permission and projection receipt errors stay in receipt section', () async {
      final permissionModule = _Repos(
        getReceiptError: salesContractError('PERMISSION_DENIED'),
      );
      final permissionCubit = _buildCubit(module: permissionModule);
      addTearDown(permissionCubit.close);

      await permissionCubit.load();
      await _drain();
      await permissionCubit.ensureReceipt();

      expect(permissionCubit.state.status, SalesOrderDetailStatus.loaded);
      expect(permissionCubit.state.core, isNotNull);
      expect(permissionCubit.state.receipt.status, SalesReceiptOperationStatus.error);
      expect(permissionCubit.state.receipt.issue, SalesTransactionResultIssue.permissionDenied);
      expect(permissionCubit.state.receiptStatus, SalesOrderDetailSectionStatus.blocked);

      final projectionModule = _Repos(
        detail: _detail(currentReceiptId: null),
        generateError: salesContractError('PROJECTION_PENDING'),
      );
      final projectionCubit = _buildCubit(module: projectionModule);
      addTearDown(projectionCubit.close);

      await projectionCubit.load();
      await _drain();
      await projectionCubit.ensureReceipt();

      expect(projectionCubit.state.status, SalesOrderDetailStatus.loaded);
      expect(projectionCubit.state.receipt.issue, SalesTransactionResultIssue.projectionPending);
      expect(projectionCubit.state.receiptStatus, SalesOrderDetailSectionStatus.projectionPending);

      final dependencyModule = _Repos(
        getReceiptError: salesContractError('DEPENDENCY_UNAVAILABLE'),
      );
      final dependencyCubit = _buildCubit(module: dependencyModule);
      addTearDown(dependencyCubit.close);

      await dependencyCubit.load();
      await _drain();
      await dependencyCubit.ensureReceipt();

      expect(dependencyCubit.state.status, SalesOrderDetailStatus.loaded);
      expect(
        dependencyCubit.state.receipt.issue,
        SalesTransactionResultIssue.dependencyUnavailable,
      );
      expect(dependencyCubit.state.receiptStatus, SalesOrderDetailSectionStatus.error);
    });

    test('refresh source version invalidates stale receipt', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
      expect(cubit.state.sourceVersion, 7);

      module.orders.detailResult = _detail(version: 8, currentReceiptId: 'receipt-2');
      await cubit.refresh();
      await _drain();

      expect(cubit.state.sourceVersion, 8);
      expect(cubit.state.currentReceiptId, 'receipt-2');
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.idle);
      expect(cubit.state.receipt.value, isNull);
      expect(cubit.state.receiptStatus, SalesOrderDetailSectionStatus.idle);
    });

    test('refresh drops in-flight receipt so stale result does not land', () async {
      final module = _Repos.deferredReceipt();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.sourceVersion, 7);
      expect(cubit.state.currentReceiptId, 'receipt-1');

      final ensureFuture = cubit.ensureReceipt();
      await module.receiptStarted.future;
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.generating);

      module.orders.detailResult = _detail(version: 8, currentReceiptId: 'receipt-2');
      await cubit.refresh();
      await _drain();

      expect(cubit.state.requestGeneration, 2);
      expect(cubit.state.sourceVersion, 8);
      expect(cubit.state.currentReceiptId, 'receipt-2');
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.idle);
      expect(cubit.state.receipt.value, isNull);

      module.completeReceipt(_receipt());
      await ensureFuture;
      await _drain();

      expect(cubit.state.requestGeneration, 2);
      expect(cubit.state.sourceVersion, 8);
      expect(cubit.state.currentReceiptId, 'receipt-2');
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.idle);
      expect(cubit.state.receipt.value, isNull);
      expect(cubit.state.receiptStatus, SalesOrderDetailSectionStatus.idle);
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
    });
  });

  group('SalesOrderDetailCubit S21 post-sale actions', () {
    test('available actions loads with expectedSourceVersion from DTO flags', () async {
      final module = _Repos(
        actions: const app.AvailablePostSaleActionsDto(
          canCancel: false,
          canReturnExchange: true,
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final query = module.orders.actionsCalls.single;
      expect(query.expectedSourceVersion, 7);
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.actions?.canCancel, isFalse);
      expect(cubit.state.actions?.canReturnExchange, isTrue);
      // Must not invent flags from lifecycle alone (core is completed → all true on VM getters).
      expect(cubit.state.core?.canCancel, isTrue);
      expect(cubit.state.actions?.canCancel, isFalse);
    });

    test('cancelled core still dispatches available-actions query', () async {
      final module = _Repos(
        detail: _detail(lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled),
        actions: const app.AvailablePostSaleActionsDto(
          canCancel: false,
          canReturnExchange: false,
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.core?.isCancelled, isTrue);
      expect(module.orders.actionsCalls, hasLength(1));
      expect(cubit.state.actions?.canCancel, isFalse);
      expect(cubit.state.actions?.canReturnExchange, isFalse);
    });

    test('S27 cancelled order loads cancellation section from authoritative detail', () async {
      final module = _Repos(
        detail: _detail(lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final query = module.orders.cancellationCalls.single;
      expect(query.expectedSourceVersion, cubit.state.sourceVersion);
      expect(cubit.state.cancellationStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.cancellation?.cancellationId, 'cancel-9');
      expect(cubit.state.cancellation?.cancelledByActorId, 'actor-77');
      expect(cubit.state.cancellation?.reason, 'Khách nhập trùng đơn');
      // Core commercial data is untouched by the cancellation section.
      expect(cubit.state.core?.orderNumber, 'SO-2026-00125');
    });

    test('S27 non-cancelled order does not query cancellation', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(
        module.orders.cancellationCalls,
        isEmpty,
      );
      expect(cubit.state.cancellationStatus, SalesOrderDetailSectionStatus.idle);
    });

    test('S27 NOT_FOUND becomes projection-pending without discarding core', () async {
      final module = _Repos(
        detail: _detail(lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled),
      )..orders.cancellationError = salesContractError('NOT_FOUND');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(
        cubit.state.cancellationStatus,
        SalesOrderDetailSectionStatus.projectionPending,
      );
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.core, isNotNull);
    });

    test('requestCancel dispatches PrecheckSalesOrderCancellationQuery', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      final before = module.cancellations.precheckCalls.length;

      final intent = await cubit.requestCancel();

      expect(intent, SalesPostSaleNavigationIntent.cancel);
      expect(
        module.cancellations.precheckCalls.skip(before),
        hasLength(1),
      );
    });

    test('confirmCancellation submits ConfirmSalesOrderCancellationCommand', () async {
      final module = _Repos();
      final cubit = _buildCubit(
        module: module,
        cancellationAttemptFactory: SalesOrderCancellationAttemptFactory(
          newAttemptId: () => 'attempt-cancel-1',
        ),
      );
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final error = await cubit.confirmCancellation(note: 'Khách đổi ý');

      expect(error, isNull);
      final command = module.cancellations.confirmCalls.single;
      expect(command.salesOrderId, 'order-1');
      expect(command.reasonText, 'Khách đổi ý');
      expect(command.expectedOrderVersion, 7);
      expect(command.expectedSettlementVersion, 1);
    });

    test('confirmCancellation accepts an empty reason', () async {
      final module = _Repos();
      final cubit = _buildCubit(
        module: module,
        cancellationAttemptFactory: SalesOrderCancellationAttemptFactory(
          newAttemptId: () => 'attempt-cancel-2',
        ),
      );
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final error = await cubit.confirmCancellation(note: '  ');

      expect(error, isNull);
      final command = module.cancellations.confirmCalls.single;

      expect(command.reasonText, '');
    });

    test('confirmCancellation returns blocker message when precheck denies', () async {
      final module = _Repos(
        cancellationPrecheck: app.CancellationPrecheckDto(
          allowed: false,
          sourceVersion: 7,
          sourceSettlementVersion: 1,
          blockers: const [
            app.SalesBlockerDto(
              code: 'PAYMENT_ALREADY_COLLECTED',
              message: 'Net confirmed collection must be zero before cancellation.',
            ),
          ],
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final error = await cubit.confirmCancellation(note: '');

      expect(error, 'Đơn đã có thanh toán, vui lòng đổi/trả');
      expect(module.cancellations.confirmCalls, isEmpty);
    });

    test('confirmCancellation returns message when command fails', () async {
      final module = _Repos(
        cancellationConfirmError: salesContractError(
          'CANCELLATION_BLOCKED',
          message: 'Không thể huỷ đơn này.',
        ),
      );
      final cubit = _buildCubit(
        module: module,
        cancellationAttemptFactory: SalesOrderCancellationAttemptFactory(
          newAttemptId: () => 'attempt-cancel-3',
        ),
      );
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final error = await cubit.confirmCancellation(note: '');

      expect(error, 'Huỷ đơn thất bại. Vui lòng thử lại.');
    });

    test('requestReturnExchange dispatches PrecheckReturnExchangeQuery', () async {
      final module = _Repos();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      final before = module.returnExchange.precheckCalls.length;

      final intent = await cubit.requestReturnExchange();

      expect(intent, SalesPostSaleNavigationIntent.returnExchange);
      expect(
        module.returnExchange.precheckCalls.skip(before),
        hasLength(1),
      );
    });

    test('blocked cancel precheck returns no intent and exposes typed messages', () async {
      final module = _Repos(
        cancellationPrecheck: app.CancellationPrecheckDto(
          allowed: false,
          sourceVersion: 7,
          sourceSettlementVersion: 1,
          blockers: const [
            app.SalesBlockerDto(
              code: 'RETURN_EXCHANGE_CONFLICT',
              message: 'Active return exchange conflict.',
            ),
          ],
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final intent = await cubit.requestCancel();

      expect(intent, isNull);
      expect(cubit.state.precheckBlockerMessages, ['Đơn đã có phiếu đổi/trả, không thể hủy.']);
      expect(cubit.state.postSaleFeedbackMessage, 'Đơn đã có phiếu đổi/trả, không thể hủy.');
    });

    test('post_sale_cancel_blocked_localized', () async {
      final module = _Repos(
        cancellationPrecheck: app.CancellationPrecheckDto(
          allowed: false,
          sourceVersion: 7,
          sourceSettlementVersion: 1,
          blockers: const [
            app.SalesBlockerDto(
              code: 'PAYMENT_ALREADY_COLLECTED',
              message: 'Net confirmed collection must be zero before cancellation.',
            ),
          ],
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final intent = await cubit.requestCancel();
      expect(intent, isNull);
      expect(cubit.state.postSaleFeedbackMessage, 'Đơn đã có thanh toán, vui lòng đổi/trả');
    });

    test('post_sale_precheck_error_never_shows_server_message', () async {
      final module = _Repos(
        cancellationPrecheckError: salesContractError(
          'SYSTEM_ERROR',
          message: 'Internal DB deadlock',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final intent = await cubit.requestCancel();
      expect(intent, isNull);
      expect(
        cubit.state.postSaleFeedbackMessage,
        'Không thể kiểm tra điều kiện thao tác. Vui lòng thử lại.',
      );
      expect(cubit.state.postSaleFeedbackMessage!.contains('Internal DB'), isFalse);
    });

    test('confirm_cancellation_blocked_localized', () async {
      final module = _Repos(
        cancellationPrecheck: app.CancellationPrecheckDto(
          allowed: false,
          sourceVersion: 7,
          sourceSettlementVersion: 1,
          blockers: const [
            app.SalesBlockerDto(
              code: 'RETURN_EXCHANGE_CONFLICT',
              message: 'Return exchange active conflict.',
            ),
          ],
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final error = await cubit.confirmCancellation(note: '');
      expect(error, 'Đơn đã có phiếu đổi/trả, không thể hủy.');
    });

    test('confirm_cancellation_error_uses_fallback', () async {
      final module = _Repos(
        cancellationConfirmError: salesContractError(
          'SYSTEM_ERROR',
          message: 'Raw server database crash',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final error = await cubit.confirmCancellation(note: '');
      expect(error, 'Huỷ đơn thất bại. Vui lòng thử lại.');
    });

    test('STALE_VERSION on cancel precheck invalidates actions and reloads core', () async {
      final module = _Repos(
        cancellationPrecheckError: salesContractError('STALE_VERSION'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      final detailCallsBefore = module.orders.detailCalls.length;

      final intent = await cubit.requestCancel();
      await _drain();

      expect(intent, isNull);
      expect(
        module.orders.detailCalls.length,
        greaterThan(detailCallsBefore),
      );
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.postSaleFeedbackMessage, contains('đã thay đổi'));
    });

    test('permission denied on cancel precheck disables only cancel action', () async {
      final module = _Repos(
        cancellationPrecheckError: salesContractError('PERMISSION_DENIED'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.actions?.canCancel, isTrue);

      final intent = await cubit.requestCancel();

      expect(intent, isNull);
      expect(cubit.state.actions?.canCancel, isFalse);
      expect(cubit.state.actions?.canReturnExchange, isTrue);
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.core, isNotNull);
    });
  });

  group('C12 error copy & state mappings', () {
    test('core_error_never_carries_server_message NOT_FOUND', () async {
      final module = _Repos.failing(salesContractError('NOT_FOUND', message: 'Raw order not found.'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.notFound);
      expect(cubit.state.errorMessage, isNull);
    });

    test('core_error_never_carries_server_message NO_PERMISSION', () async {
      final module = _Repos.failing(salesContractError('PERMISSION_DENIED', message: 'Raw scope denied.'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.errorMessage, isNull);
    });

    test('core_error_never_carries_server_message SYSTEM_ERROR', () async {
      final module = _Repos.failing(salesContractError('SYSTEM_ERROR', message: 'Raw database failure.'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.error);
      expect(cubit.state.errorMessage, isNull);
    });

    test('history_error_never_carries_server_message', () async {
      final module = _Repos(
        timelineError: salesContractError(
          'TIMELINE_UNAVAILABLE',
          message: 'Raw timeline error.',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.error);
      expect(cubit.state.historyErrorMessage, isNull);
    });

    test('actions_error_never_carries_server_message', () async {
      final module = _Repos(
        actionsError: salesContractError(
          'ACTIONS_UNAVAILABLE',
          message: 'Raw actions error.',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.error);
      expect(cubit.state.actionsErrorMessage, isNull);
    });

    test('cancellation_impact_pending_is_projection_pending', () async {
      final module = _Repos(
        detail: _detail(lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled),
        cancellationDetailError: salesContractError(
          'IMPACT_PENDING',
          message: 'Pending cancellation projection',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.cancellationStatus, SalesOrderDetailSectionStatus.projectionPending);
      expect(cubit.state.cancellationErrorMessage, isNull);
    });
  });
}

Future<void> _drain() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

SalesOrderDetailCubit _buildCubit({
  required _Repos module,
  SalesOrderCancellationAttemptFactory? cancellationAttemptFactory,
}) {
  return SalesOrderDetailCubit(
    orderId: 'order-1',
    orderRepository: module.orders,
    receiptRepository: module.receipts,
    paymentRepository: module.payments,
    cancellationRepository: module.cancellations,
    returnExchangeRepository: module.returnExchange,
    executionContext: const _ExecutionContext('tenant-1', 'actor-1'),
    cancellationAttemptFactory: cancellationAttemptFactory,
  );
}

app.SalesOrderCancellationDetailDto _cancellationDetail({
  app.SalesOrderCancellationStatus status = app.SalesOrderCancellationStatus.confirmed,
}) {
  return app.SalesOrderCancellationDetailDto(
    result: app.SalesOrderCancellationResultDto(
      cancellationId: 'cancel-9',
      salesOrderId: 'order-1',
      salesOrderVersion: 8,
      status: status,
    ),
    reason: const app.CancellationReasonDto(
      reasonText: 'Khách nhập trùng đơn',
    ),
    cancelledAt: DateTime.utc(2026, 8, 12, 4, 0),
    cancelledByActorId: 'actor-77',
    netConfirmedCollectionMinor: 0,
  );
}

app.SalesOrderCancellationResultDto _cancellationConfirmResult({
  app.SalesOrderCancellationStatus status = app.SalesOrderCancellationStatus.confirmed,
}) {
  return app.SalesOrderCancellationResultDto(
    cancellationId: 'cancel-9',
    salesOrderId: 'order-1',
    salesOrderVersion: 8,
    status: status,
  );
}

app.SalesOrderDetailDto _detail({
  int version = 7,
  String customerName = 'Đại lý An Bình',
  String? currentReceiptId = 'receipt-1',
  app.SalesOrderLifecycleStatus lifecycleStatus = app.SalesOrderLifecycleStatus.completed,
}) {
  return app.SalesOrderDetailDto(
    order: app.SalesOrderDto(
      salesOrderId: 'order-1',
      orderNumber: 'SO-2026-00125',
      version: version,
      lifecycleStatus: lifecycleStatus,
      lockStatus: app.SalesOrderLockStatus.unlocked,
      total: const app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
    ),
    committedAt: DateTime.utc(2026, 8, 12, 3, 15),
    store: const app.StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM-01',
      displayName: 'Chi nhánh Quận 1',
    ),
    seller: const app.ActorSnapshotDto(actorId: 'seller-1', displayName: 'Minh Anh'),
    customer: app.CustomerSnapshotDto(
      customerId: 'customer-1',
      displayName: customerName,
      phoneNumber: '0903456789',
    ),
    lines: const [
      app.SalesOrderLineDto(
        lineId: 'line-1',
        product: app.ProductSnapshotDto(
          productId: 'product-1',
          sku: 'SKU-1',
          displayName: 'Vaccine A',
        ),
        unit: app.ProductUnitSnapshotDto(
          productUnitId: 'unit-1',
          unitCode: 'VIAL',
          unitName: 'Lọ',
        ),
        quantity: app.QuantityDto(quantityMicros: app.QuantityDto.scale),
        unitPrice: app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
        lineTotal: app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
      ),
    ],
    orderNote: 'Giao giờ hành chính',
    currentReceiptId: currentReceiptId,
  );
}

app.SalesOrderPaymentSummaryDto _paymentSummary({
  int paid = 1000000,
  int outstanding = 250000,
}) {
  return app.SalesOrderPaymentSummaryDto(
    status: outstanding > 0
        ? app.SalesSettlementStatus.partiallyPaid
        : app.SalesSettlementStatus.paid,
    orderTotal: const app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
    paidTotal: app.MoneyDto(amountMinor: paid, currencyCode: 'VND'),
    outstandingTotal: app.MoneyDto(amountMinor: outstanding, currencyCode: 'VND'),
    dueAt: DateTime.utc(2026, 8, 30),
  );
}

app.SalesOrderSettlementDto _settlement() {
  return const app.SalesOrderSettlementDto(
    settlementId: 'settlement-1',
    salesOrderId: 'order-1',
    version: 7,
    status: app.SalesSettlementStatus.partiallyPaid,
    orderTotal: app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
    paidTotal: app.MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    refundedTotal: app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    outstanding: app.MoneyDto(amountMinor: 250000, currencyCode: 'VND'),
    dueAt: null,
  );
}

app.SalesPaymentTransactionDto _cashTx(int amountMinor) {
  return app.SalesPaymentTransactionDto(
    transactionId: 'tx-cash-$amountMinor',
    method: app.SalesPaymentMethod.cash,
    amount: app.MoneyDto(amountMinor: amountMinor, currencyCode: 'VND'),
    status: app.SalesPaymentStatus.confirmed,
    recordedAt: DateTime.utc(2026, 8, 12, 3, 20),
  );
}

app.SalesPaymentTransactionDto _bankTx(int amountMinor) {
  return app.SalesPaymentTransactionDto(
    transactionId: 'tx-bank-$amountMinor',
    method: app.SalesPaymentMethod.manualBankTransfer,
    amount: app.MoneyDto(amountMinor: amountMinor, currencyCode: 'VND'),
    status: app.SalesPaymentStatus.confirmed,
    recordedAt: DateTime.utc(2026, 8, 12, 3, 21),
  );
}

app.SalesPaymentTransactionsDto _transactionsPage({
  required List<app.SalesPaymentTransactionDto> items,
  required bool hasMore,
  String? nextCursor,
}) {
  return app.SalesPaymentTransactionsDto(
    page: app.OpaqueCursorPageDto<app.SalesPaymentTransactionDto>(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    ),
  );
}

app.SalesOrderTimelineDto _timeline({List<app.SalesOrderTimelineEntryDto>? entries}) {
  return app.SalesOrderTimelineDto(
    salesOrderId: 'order-1',
    entries:
        entries ??
        [
          app.SalesOrderTimelineEntryDto(
            eventId: 'event-1',
            eventType: 'sales_order_confirmed',
            occurredAt: DateTime.utc(2026, 8, 12, 3, 15),
            sourceVersion: 7,
            actor: const app.ActorSnapshotDto(actorId: 'seller-1', displayName: 'Minh Anh'),
            description: 'Xác nhận đơn hàng',
            amount: const app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
          ),
        ],
  );
}

app.SalesOrderReturnSummaryDto _returnSummary() {
  return app.SalesOrderReturnSummaryDto(
    salesOrderId: 'order-1',
    returns: [
      app.ReturnExchangeSummaryDto(
        returnExchangeId: 're-42',
        referenceNumber: 'DT-2026-00042',
        status: app.ReturnExchangeStatus.completed,
        completedAt: DateTime.utc(2026, 8, 14, 9, 30),
        settlementDifference: const app.MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
      ),
    ],
  );
}

/// Gom các fake repository; mỗi kịch bản (lỗi, treo, phản hồi cũ) là một hàm dựng.
final class _Repos {
  _Repos({
    app.SalesOrderDetailDto? detail,
    Object? paymentSummaryError,
    Object? settlementError,
    Object? timelineError,
    Object? actionsError,
    Object? cancellationDetailError,
    Object? cancellationPrecheckError,
    Object? cancellationConfirmError,
    app.SalesPaymentTransactionsDto? transactions,
    app.AvailablePostSaleActionsDto? actions,
    app.CancellationPrecheckDto? cancellationPrecheck,
    app.ReturnExchangePrecheckDto? returnExchangePrecheck,
    app.SalesOrderCancellationResultDto? cancellationConfirmResult,
    Object? getReceiptError,
    Object? generateError,
    Object? printedError,
    Object? sharedError,
  }) {
    orders
      ..detailResult = detail ?? _detail()
      ..timelineResult = _timeline()
      ..timelineError = timelineError
      ..returnSummaryResult = _returnSummary()
      ..actionsResult = actions ?? _availableActions()
      ..actionsError = actionsError
      ..cancellationResult = _cancellationDetail()
      ..cancellationError = cancellationDetailError;
    payments
      ..summaryResult = _paymentSummary()
      ..summaryError = paymentSummaryError
      ..settlementResult = _settlement()
      ..settlementError = settlementError
      ..transactionsResult =
          transactions ??
          _transactionsPage(items: [_cashTx(400000), _bankTx(600000)], hasMore: false);
    receipts
      ..getResult = _receipt()
      ..getError = getReceiptError
      ..generateResult = _receipt()
      ..generateError = generateError
      ..printedResult = _receipt()
      ..printedError = printedError
      ..sharedResult = _receipt()
      ..sharedError = sharedError
      ..originalResult = _receipt().document;
    cancellations
      ..precheckResult =
          cancellationPrecheck ??
          app.CancellationPrecheckDto(
            allowed: true,
            sourceVersion: 7,
            sourceSettlementVersion: 1,
            blockers: const [],
          )
      ..precheckError = cancellationPrecheckError
      ..confirmResult = cancellationConfirmResult ?? _cancellationConfirmResult()
      ..confirmError = cancellationConfirmError;
    returnExchange.precheckResult =
        returnExchangePrecheck ??
        app.ReturnExchangePrecheckDto(allowed: true, sourceVersion: 7, blockers: const []);
  }

  /// Mọi lần đọc đều ném [error].
  factory _Repos.failing(Object error) {
    final repos = _Repos();
    repos.orders
      ..detailError = error
      ..timelineError = error
      ..returnSummaryError = error
      ..actionsError = error
      ..cancellationError = error;
    repos.payments
      ..summaryError = error
      ..settlementError = error
      ..transactionsError = error;
    repos.receipts.getError = error;
    repos.cancellations.precheckError = error;
    repos.returnExchange.precheckError = error;
    return repos;
  }

  /// Lần đọc chi tiết đầu thành công, các lần sau ném [error]; các khối còn lại rỗng.
  factory _Repos.succeedThenFail({
    required app.SalesOrderDetailDto detail,
    required Object error,
  }) {
    final repos = _Repos()._withEmptySections();
    var detailCalls = 0;
    repos.orders.detailHook = () async {
      detailCalls++;
      if (detailCalls > 1) throw error;
      return detail;
    };
    return repos;
  }

  /// Mỗi lần đọc chi tiết trả một Completer riêng ([results]) để test hoàn tất lệch thứ tự.
  factory _Repos.stale() {
    final repos = _Repos()._withEmptySections();
    repos.orders.detailHook = () {
      final completer = Completer<app.SalesOrderDetailDto>();
      repos.results.add(completer);
      if (repos.results.length == 1) repos.firstQueryStarted.complete();
      if (repos.results.length == 2) repos.secondQueryStarted.complete();
      return completer.future;
    };
    return repos;
  }

  /// Chi tiết và sáu khối phụ chỉ trả khi test gọi [completeDetail] / [completeAllSections].
  factory _Repos.deferredSections() {
    final repos = _Repos();
    repos.orders.detailHook = () {
      if (!repos.detailStarted.isCompleted) repos.detailStarted.complete();
      return repos._detailCompleter.future;
    };
    repos.orders.sectionsGate = repos._sectionsGate.future;
    repos.payments.sectionsGate = repos._sectionsGate.future;
    return repos;
  }

  /// Đọc phiếu bán hàng treo tới khi test gọi [completeReceipt].
  factory _Repos.deferredReceipt() {
    final repos = _Repos();
    repos.receipts.getStarted = repos.receiptStarted;
    repos.receipts.getGate = repos._receiptGate.future;
    return repos;
  }

  final _Orders orders = _Orders();
  final _Payments payments = _Payments();
  final _Receipts receipts = _Receipts();
  final FakeSalesCancellationRepository cancellations = FakeSalesCancellationRepository();
  final FakeReturnExchangeRepository returnExchange = FakeReturnExchangeRepository();

  final List<Completer<app.SalesOrderDetailDto>> results = [];
  final Completer<void> firstQueryStarted = Completer();
  final Completer<void> secondQueryStarted = Completer();
  final Completer<void> detailStarted = Completer();
  final Completer<void> receiptStarted = Completer();
  final Completer<app.SalesOrderDetailDto> _detailCompleter = Completer();
  final Completer<void> _sectionsGate = Completer();
  final Completer<void> _receiptGate = Completer();

  app.SalesOrderDetailDto get detail => orders.detailResult!;

  /// Các lệnh ghi đã gọi (phiếu bán hàng, huỷ đơn).
  List<Object> get commands => [
    ...receipts.generateCalls,
    ...receipts.printedCalls,
    ...receipts.sharedCalls,
    ...cancellations.confirmCalls,
  ];

  void completeDetail(app.SalesOrderDetailDto dto) => _detailCompleter.complete(dto);

  void completeAllSections() => _sectionsGate.complete();

  void completeReceipt(app.SalesReceiptDto receipt) {
    if (!_receiptGate.isCompleted) _receiptGate.complete();
  }

  _Repos _withEmptySections() {
    payments.transactionsResult = _transactionsPage(items: const [], hasMore: false);
    orders
      ..timelineResult = _timeline(entries: const [])
      ..returnSummaryResult = app.SalesOrderReturnSummaryDto(
        salesOrderId: 'order-1',
        returns: const [],
      );
    return this;
  }
}

/// `detailHook` thay kết quả đọc chi tiết; `sectionsGate` giữ các khối phụ tới khi hoàn tất.
final class _Orders extends FakeSalesOrderRepository {
  Future<app.SalesOrderDetailDto> Function()? detailHook;
  Future<void>? sectionsGate;

  @override
  Future<app.SalesOrderDetailDto> getDetail({required String salesOrderId}) {
    final hook = detailHook;
    if (hook == null) return super.getDetail(salesOrderId: salesOrderId);
    detailCalls.add(salesOrderId);
    return hook();
  }

  @override
  Future<app.SalesOrderTimelineDto> getTimeline({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    await sectionsGate;
    return super.getTimeline(
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    );
  }

  @override
  Future<app.SalesOrderReturnSummaryDto> getReturnSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    await sectionsGate;
    return super.getReturnSummary(
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    );
  }

  @override
  Future<app.AvailablePostSaleActionsDto> getAvailableActions({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    await sectionsGate;
    return super.getAvailableActions(
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    );
  }
}

final class _Payments extends FakeSalesPaymentRepository {
  Future<void>? sectionsGate;

  @override
  Future<app.SalesOrderPaymentSummaryDto> getSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    await sectionsGate;
    return super.getSummary(
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    );
  }

  @override
  Future<app.SalesOrderSettlementDto> getSettlement({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    await sectionsGate;
    return super.getSettlement(
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    );
  }

  @override
  Future<app.SalesPaymentTransactionsDto> getTransactions({
    required String salesOrderId,
    int? expectedSourceVersion,
    String? cursor,
    int pageSize = 25,
  }) async {
    await sectionsGate;
    return super.getTransactions(
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
      cursor: cursor,
      pageSize: pageSize,
    );
  }
}

final class _Receipts extends FakeSalesReceiptRepository {
  Completer<void>? getStarted;
  Future<void>? getGate;

  @override
  Future<app.SalesReceiptDto> get({required String receiptId, int? expectedSourceVersion}) async {
    final started = getStarted;
    if (started != null && !started.isCompleted) started.complete();
    await getGate;
    return super.get(receiptId: receiptId, expectedSourceVersion: expectedSourceVersion);
  }
}

app.SalesReceiptDto _receipt() => app.SalesReceiptDto(
  receiptId: 'receipt-1',
  salesOrderId: 'order-1',
  version: 1,
  status: app.SalesReceiptStatus.generated,
  generatedAt: DateTime.utc(2026, 8, 12, 2, 41),
  document: app.SalesReceiptDocumentDto(
    receiptNumber: 'PBH-20260812-0129',
    orderNumber: 'SO-2026-00125',
    soldAt: DateTime.utc(2026, 8, 12, 2, 41),
    store: const app.StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM-01',
      displayName: 'Chi nhánh Quận 1',
    ),
    seller: const app.ActorSnapshotDto(actorId: 'seller-1', displayName: 'Minh Anh'),
    lines: const <app.SalesReceiptLineDto>[],
    subtotal: const app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
    discountTotal: const app.MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    orderTotal: const app.MoneyDto(amountMinor: 1250000, currencyCode: 'VND'),
    paidTotal: const app.MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    outstandingTotal: const app.MoneyDto(amountMinor: 250000, currencyCode: 'VND'),
    payments: const <app.PaymentIntentSummaryDto>[],
  ),
);

app.AvailablePostSaleActionsDto _availableActions({
  bool canCancel = true,
  bool canReturnExchange = true,
}) {
  return app.AvailablePostSaleActionsDto(
    canCancel: canCancel,
    canReturnExchange: canReturnExchange,
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
