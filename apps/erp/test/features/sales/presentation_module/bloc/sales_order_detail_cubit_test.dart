import 'dart:async';

import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart' as app;
import 'package:vet45_shared_application/application.dart';

import '../../support/module_backed_sales_repositories.dart';

void main() {
  group('SalesOrderDetailCubit S16 core', () {
    test('load resolves tenant and actor and dispatches one GetSalesOrderDetailQuery', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final detailQueries = module.queries.whereType<app.GetSalesOrderDetailQuery>();
      expect(detailQueries, hasLength(1));
      final query = detailQueries.single;
      expect(query.tenantId, 'tenant-1');
      expect(query.actorId, 'actor-1');
      expect(query.salesOrderId, 'order-1');
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.sourceVersion, 7);
      expect(cubit.state.core?.orderId, 'order-1');
    });

    test('exposes sourceVersion equal to dto.order.version', () async {
      final module = _RecordingSalesModule(detail: _detail(version: 11));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.sourceVersion, 11);
      expect(cubit.state.sourceVersion, module.detail.order.version);
    });

    test('permission denied maps to blocked and does not emit loaded core', () async {
      final module = _ContractErrorModule('PERMISSION_DENIED');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.core, isNull);
      expect(cubit.state.errorMessage, isNull);
    });

    test('permission denied with null message does not surface raw contract code', () async {
      final module = _ContractErrorModule('PERMISSION_DENIED');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.errorMessage, isNot(equals('PERMISSION_DENIED')));
    });

    test('query failure clears sourceVersion and currentReceiptId', () async {
      final module = _SucceedThenFailModule(
        detail: _detail(version: 7),
        error: const app.SalesContractException('PERMISSION_DENIED'),
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
      final module = _ContractErrorModule('DATA_SCOPE_DENIED');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.core, isNull);
    });

    test('not found maps to notFound', () async {
      final module = _ContractErrorModule('NOT_FOUND');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.notFound);
      expect(cubit.state.core, isNull);
    });

    test('projection pending maps to retryable pending', () async {
      final module = _ContractErrorModule('PROJECTION_PENDING');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.projectionPending);
      expect(cubit.state.core, isNull);
    });

    test('transport error maps to error', () async {
      final module = _ContractErrorModule('TRANSPORT_ERROR', message: 'network down');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.error);
      expect(cubit.state.core, isNull);
      expect(cubit.state.errorMessage, isNull);
    });

    test('malformed contract maps to error', () async {
      final module = _ThrowingModule(const FormatException('malformed detail payload'));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.error);
      expect(cubit.state.core, isNull);
    });

    test('second refresh generation suppresses first response', () async {
      final module = _StaleAwareModule();
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
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.sourceVersion, 7);

      final paymentSummary = module.queries
          .whereType<app.GetSalesOrderPaymentSummaryQuery>()
          .single;
      final settlement = module.queries.whereType<app.GetSalesOrderSettlementQuery>().single;
      final transactions = module.queries
          .whereType<app.GetSalesOrderPaymentTransactionsQuery>()
          .single;
      final timeline = module.queries.whereType<app.GetSalesOrderTimelineQuery>().single;
      final returns = module.queries.whereType<app.GetSalesOrderReturnSummaryQuery>().single;
      final actions = module.queries.whereType<app.GetAvailablePostSaleActionsQuery>().single;

      expect(paymentSummary.tenantId, 'tenant-1');
      expect(paymentSummary.actorId, 'actor-1');
      expect(paymentSummary.salesOrderId, 'order-1');
      expect(paymentSummary.expectedSourceVersion, 7);
      expect(settlement.tenantId, 'tenant-1');
      expect(settlement.actorId, 'actor-1');
      expect(settlement.salesOrderId, 'order-1');
      expect(settlement.expectedSourceVersion, 7);
      expect(transactions.tenantId, 'tenant-1');
      expect(transactions.actorId, 'actor-1');
      expect(transactions.salesOrderId, 'order-1');
      expect(transactions.expectedSourceVersion, 7);
      expect(timeline.tenantId, 'tenant-1');
      expect(timeline.actorId, 'actor-1');
      expect(timeline.salesOrderId, 'order-1');
      expect(timeline.expectedSourceVersion, 7);
      expect(returns.tenantId, 'tenant-1');
      expect(returns.actorId, 'actor-1');
      expect(returns.salesOrderId, 'order-1');
      expect(returns.expectedSourceVersion, 7);
      expect(actions.tenantId, 'tenant-1');
      expect(actions.actorId, 'actor-1');
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
      final module = _DeferredSectionsModule();
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
      final module = _RecordingSalesModule(
        paymentSummaryError: const app.SalesContractException(
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
      final module = _RecordingSalesModule(
        settlementError: const app.SalesContractException('PERMISSION_DENIED'),
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
      final module = _RecordingSalesModule(
        paymentSummaryError: const app.SalesContractException('PROJECTION_PENDING'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.projectionPending);
    });

    test('payment_section_error_never_shows_server_message', () async {
      final module = _RecordingSalesModule(
        settlementError: const app.SalesContractException(
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
      final module = _RecordingSalesModule(
        timelineError: const app.SalesContractException('PERMISSION_DENIED'),
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
      final module = _RecordingSalesModule(
        settlementError: const app.SalesContractException('PROJECTION_PENDING'),
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
      final module = _RecordingSalesModule(
        paymentSummaryError: const app.SalesContractException(
          'TRANSPORT_ERROR',
          message: 'pay down',
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.error);

      module.paymentSummaryError = null;
      final before = module.queries.length;
      await cubit.retryPaymentSection();
      await _drain();

      final newQueries = module.queries.skip(before).toList();
      expect(newQueries.whereType<app.GetSalesOrderPaymentSummaryQuery>(), hasLength(1));
      expect(newQueries.whereType<app.GetSalesOrderSettlementQuery>(), hasLength(1));
      expect(newQueries.whereType<app.GetSalesOrderPaymentTransactionsQuery>(), hasLength(1));
      expect(newQueries.whereType<app.GetSalesOrderTimelineQuery>(), isEmpty);
      expect(cubit.state.paymentStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.historyStatus, SalesOrderDetailSectionStatus.loaded);
    });

    test('transaction load-more error retains existing rows', () async {
      final module = _RecordingSalesModule(
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

      module.transactionsError = const app.SalesContractException(
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
      final module = _VersionedRefreshModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.sourceVersion, 7);
      expect(cubit.state.payment?.paidCashAmountMinor, 400000);
      expect(cubit.state.history?.timeline.single.title, contains('Xác nhận'));

      module.nextDetail = _detail(version: 8);
      module.nextPaymentSummary = _paymentSummary(paid: 800000, outstanding: 450000);
      module.nextTransactions = _transactionsPage(
        items: [_cashTx(800000)],
        hasMore: false,
      );
      module.nextTimeline = _timeline(
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

      final paymentQueries = module.queries.whereType<app.GetSalesOrderPaymentSummaryQuery>();
      expect(paymentQueries.last.expectedSourceVersion, 8);
      final timelineQueries = module.queries.whereType<app.GetSalesOrderTimelineQuery>();
      expect(timelineQueries.last.expectedSourceVersion, 8);
    });
  });

  group('SalesOrderDetailCubit S19 receipt', () {
    test('loads known receipt via GetSalesReceiptQuery with source version', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.currentReceiptId, 'receipt-1');

      await cubit.ensureReceipt();

      final queries = module.queries.whereType<app.GetSalesReceiptQuery>();
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
      final module = _RecordingSalesModule(detail: _detail(currentReceiptId: null));
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.currentReceiptId, isNull);

      await cubit.ensureReceipt();

      expect(module.queries.whereType<app.GetSalesReceiptQuery>(), isEmpty);
      expect(module.commands.whereType<app.GenerateSalesReceiptCommand>(), hasLength(1));
      final command = module.commands.whereType<app.GenerateSalesReceiptCommand>().single;
      expect(command.salesOrderId, 'order-1');
      expect(command.expectedVersion, 7);
      expect(command.idempotencyKey, 'sales-receipt:tenant-1:order-1:v7');
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
      expect(cubit.state.currentReceiptId, 'receipt-1');
    });

    test('viewReceipt returns ready typed receipt for route extra', () async {
      final module = _RecordingSalesModule();
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
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);
      await cubit.load();
      await _drain();

      final document = await cubit.viewOriginalReceipt();

      final query = module.queries.whereType<app.GetSalesOrderOriginalReceiptQuery>().single;
      expect(query.salesOrderId, 'order-1');
      expect(query.tenantId, 'tenant-1');
      expect(query.actorId, 'actor-1');
      expect(document.receiptNumber, _receipt().document.receiptNumber);
      expect(module.queries.whereType<app.GetSalesReceiptQuery>(), isEmpty);
      expect(module.commands, isEmpty);
    });

    test('prints on the device before recording receipt activity', () async {
      final module = _RecordingSalesModule();
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
      expect(module.commands.whereType<app.RecordSalesReceiptPrintedCommand>(), hasLength(1));
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
    });

    test('shares on the device before recording receipt activity', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);
      final events = <String>[];

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      await cubit.shareReceipt((_) async => events.add('device:share'));

      expect(events, ['device:share']);
      expect(module.commands.whereType<app.RecordSalesReceiptSharedCommand>(), hasLength(1));
    });

    test('device failure sends no audit command and retains receipt', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      await cubit.printReceipt((_) => Future<void>.error(Exception('printer unavailable')));

      expect(module.commands.whereType<app.RecordSalesReceiptPrintedCommand>(), isEmpty);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.error);
      expect(cubit.state.receipt.issue, SalesTransactionResultIssue.transportFailure);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
      expect(cubit.state.status, SalesOrderDetailStatus.loaded);
      expect(cubit.state.receiptStatus, SalesOrderDetailSectionStatus.error);
    });

    test('audit failure produces activity warning and retains receipt', () async {
      final module = _RecordingSalesModule(
        printedResponse: _Failure(Exception('audit unavailable')),
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
      final permissionModule = _RecordingSalesModule(
        getReceiptResponse: const _Failure(app.SalesContractException('PERMISSION_DENIED')),
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

      final projectionModule = _RecordingSalesModule(
        detail: _detail(currentReceiptId: null),
        generateResponse: const _Failure(app.SalesContractException('PROJECTION_PENDING')),
      );
      final projectionCubit = _buildCubit(module: projectionModule);
      addTearDown(projectionCubit.close);

      await projectionCubit.load();
      await _drain();
      await projectionCubit.ensureReceipt();

      expect(projectionCubit.state.status, SalesOrderDetailStatus.loaded);
      expect(projectionCubit.state.receipt.issue, SalesTransactionResultIssue.projectionPending);
      expect(projectionCubit.state.receiptStatus, SalesOrderDetailSectionStatus.projectionPending);

      final dependencyModule = _RecordingSalesModule(
        getReceiptResponse: const _Failure(
          app.SalesContractException('DEPENDENCY_UNAVAILABLE'),
        ),
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
      final module = _VersionedRefreshModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      await cubit.ensureReceipt();
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
      expect(cubit.state.sourceVersion, 7);

      module.nextDetail = _detail(version: 8, currentReceiptId: 'receipt-2');
      await cubit.refresh();
      await _drain();

      expect(cubit.state.sourceVersion, 8);
      expect(cubit.state.currentReceiptId, 'receipt-2');
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.idle);
      expect(cubit.state.receipt.value, isNull);
      expect(cubit.state.receiptStatus, SalesOrderDetailSectionStatus.idle);
    });

    test('refresh drops in-flight receipt so stale result does not land', () async {
      final module = _DeferredReceiptModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      expect(cubit.state.sourceVersion, 7);
      expect(cubit.state.currentReceiptId, 'receipt-1');

      final ensureFuture = cubit.ensureReceipt();
      await module.receiptStarted.future;
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.generating);

      module.nextDetail = _detail(version: 8, currentReceiptId: 'receipt-2');
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
      final module = _RecordingSalesModule(
        actions: const app.AvailablePostSaleActionsDto(
          canCancel: false,
          canReturnExchange: true,
        ),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final query = module.queries.whereType<app.GetAvailablePostSaleActionsQuery>().single;
      expect(query.expectedSourceVersion, 7);
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.actions?.canCancel, isFalse);
      expect(cubit.state.actions?.canReturnExchange, isTrue);
      // Must not invent flags from lifecycle alone (core is completed → all true on VM getters).
      expect(cubit.state.core?.canCancel, isTrue);
      expect(cubit.state.actions?.canCancel, isFalse);
    });

    test('cancelled core still dispatches available-actions query', () async {
      final module = _RecordingSalesModule(
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
      expect(module.queries.whereType<app.GetAvailablePostSaleActionsQuery>(), hasLength(1));
      expect(cubit.state.actions?.canCancel, isFalse);
      expect(cubit.state.actions?.canReturnExchange, isFalse);
    });

    test('S27 cancelled order loads cancellation section from authoritative detail', () async {
      final module = _RecordingSalesModule(
        detail: _detail(lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      final query = module.queries.whereType<app.GetSalesOrderCancellationQuery>().single;
      expect(query.expectedSourceVersion, cubit.state.sourceVersion);
      expect(cubit.state.cancellationStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.cancellation?.cancellationId, 'cancel-9');
      expect(cubit.state.cancellation?.cancelledByActorId, 'actor-77');
      expect(cubit.state.cancellation?.reason, 'Khách nhập trùng đơn');
      // Core commercial data is untouched by the cancellation section.
      expect(cubit.state.core?.orderNumber, 'SO-2026-00125');
    });

    test('S27 non-cancelled order does not query cancellation', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();

      expect(
        module.queries.whereType<app.GetSalesOrderCancellationQuery>(),
        isEmpty,
      );
      expect(cubit.state.cancellationStatus, SalesOrderDetailSectionStatus.idle);
    });

    test('S27 NOT_FOUND becomes projection-pending without discarding core', () async {
      final module = _RecordingSalesModule(
        detail: _detail(lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled),
      )..cancellationDetailError = const app.SalesContractException('NOT_FOUND');
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
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      final before = module.queries.length;

      final intent = await cubit.requestCancel();

      expect(intent, SalesPostSaleNavigationIntent.cancel);
      expect(
        module.queries.skip(before).whereType<app.PrecheckSalesOrderCancellationQuery>(),
        hasLength(1),
      );
    });

    test('confirmCancellation submits ConfirmSalesOrderCancellationCommand', () async {
      final module = _RecordingSalesModule();
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
      final command = module.commands.whereType<app.ConfirmSalesOrderCancellationCommand>().single;
      expect(command.salesOrderId, 'order-1');
      expect(command.reason.reasonText, 'Khách đổi ý');
      expect(command.expectedVersion, 7);
      expect(command.expectedSettlementVersion, 1);
    });

    test('confirmCancellation accepts an empty reason', () async {
      final module = _RecordingSalesModule();
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
      final command = module.commands.whereType<app.ConfirmSalesOrderCancellationCommand>().single;

      expect(command.reason.reasonText, '');
    });

    test('confirmCancellation returns blocker message when precheck denies', () async {
      final module = _RecordingSalesModule(
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
      expect(module.commands.whereType<app.ConfirmSalesOrderCancellationCommand>(), isEmpty);
    });

    test('confirmCancellation returns message when command fails', () async {
      final module = _RecordingSalesModule(
        cancellationConfirmError: const app.SalesContractException(
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
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      final before = module.queries.length;

      final intent = await cubit.requestReturnExchange();

      expect(intent, SalesPostSaleNavigationIntent.returnExchange);
      expect(
        module.queries.skip(before).whereType<app.PrecheckReturnExchangeQuery>(),
        hasLength(1),
      );
    });

    test('blocked cancel precheck returns no intent and exposes typed messages', () async {
      final module = _RecordingSalesModule(
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
      final module = _RecordingSalesModule(
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
      final module = _RecordingSalesModule(
        cancellationPrecheckError: const app.SalesContractException(
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
      final module = _RecordingSalesModule(
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
      final module = _RecordingSalesModule(
        cancellationConfirmError: const app.SalesContractException(
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
      final module = _RecordingSalesModule(
        cancellationPrecheckError: const app.SalesContractException('STALE_VERSION'),
      );
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await _drain();
      final detailCallsBefore = module.queries.whereType<app.GetSalesOrderDetailQuery>().length;

      final intent = await cubit.requestCancel();
      await _drain();

      expect(intent, isNull);
      expect(
        module.queries.whereType<app.GetSalesOrderDetailQuery>().length,
        greaterThan(detailCallsBefore),
      );
      expect(cubit.state.actionsStatus, SalesOrderDetailSectionStatus.loaded);
      expect(cubit.state.postSaleFeedbackMessage, contains('đã thay đổi'));
    });

    test('permission denied on cancel precheck disables only cancel action', () async {
      final module = _RecordingSalesModule(
        cancellationPrecheckError: const app.SalesContractException('PERMISSION_DENIED'),
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
      final module = _ContractErrorModule('NOT_FOUND', message: 'Raw order not found.');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.notFound);
      expect(cubit.state.errorMessage, isNull);
    });

    test('core_error_never_carries_server_message NO_PERMISSION', () async {
      final module = _ContractErrorModule('PERMISSION_DENIED', message: 'Raw scope denied.');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.blocked);
      expect(cubit.state.errorMessage, isNull);
    });

    test('core_error_never_carries_server_message SYSTEM_ERROR', () async {
      final module = _ContractErrorModule('SYSTEM_ERROR', message: 'Raw database failure.');
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesOrderDetailStatus.error);
      expect(cubit.state.errorMessage, isNull);
    });

    test('history_error_never_carries_server_message', () async {
      final module = _RecordingSalesModule(
        timelineError: const app.SalesContractException(
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
      final module = _RecordingSalesModule(
        actionsError: const app.SalesContractException(
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
      final module = _RecordingSalesModule(
        detail: _detail(lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled),
        cancellationDetailError: const app.SalesContractException(
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
  required app.ISalesModule module,
  SalesOrderCancellationAttemptFactory? cancellationAttemptFactory,
  SalesOrderRepository? orderRepository,
  SalesReceiptRepository? receiptRepository,
}) {
  return SalesOrderDetailCubit(
    orderId: 'order-1',
    orderRepository: orderRepository ?? ModuleBackedSalesOrderRepository(module),
    receiptRepository: receiptRepository ?? ModuleBackedSalesReceiptRepository(module),
    paymentRepository: ModuleBackedSalesPaymentRepository(module),
    cancellationRepository: ModuleBackedSalesCancellationRepository(module),
    returnExchangeRepository: ModuleBackedReturnExchangeRepository(module),
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

final class _RecordingSalesModule implements app.ISalesModule {
  _RecordingSalesModule({
    app.SalesOrderDetailDto? detail,
    this.paymentSummaryError,
    this.settlementError,
    this.timelineError,
    this.actionsError,
    this.cancellationDetailError,
    this.cancellationPrecheckError,
    this.cancellationConfirmError,
    app.SalesPaymentTransactionsDto? transactions,
    app.AvailablePostSaleActionsDto? actions,
    app.CancellationPrecheckDto? cancellationPrecheck,
    app.ReturnExchangePrecheckDto? returnExchangePrecheck,
    app.SalesOrderCancellationResultDto? cancellationConfirmResult,
    Object? getReceiptResponse,
    Object? generateResponse,
    Object? printedResponse,
    Object? sharedResponse,
  }) : transactionsError = null,
       returnSummaryError = null,
       returnExchangePrecheckError = null,
       detail = detail ?? _detail(),
       transactions =
           transactions ??
           _transactionsPage(
             items: [_cashTx(400000), _bankTx(600000)],
             hasMore: false,
           ),
       actions =
           actions ??
           const app.AvailablePostSaleActionsDto(
             canCancel: true,
             canReturnExchange: true,
           ),
       cancellationPrecheck =
           cancellationPrecheck ??
           app.CancellationPrecheckDto(
             allowed: true,
             sourceVersion: 7,
             sourceSettlementVersion: 1,
             blockers: const [],
           ),
       returnExchangePrecheck =
           returnExchangePrecheck ??
           app.ReturnExchangePrecheckDto(
             allowed: true,
             sourceVersion: 7,
             blockers: const [],
           ),
       cancellationConfirmResult = cancellationConfirmResult ?? _cancellationConfirmResult(),
       getReceiptResponse = getReceiptResponse ?? _receipt(),
       generateResponse = generateResponse ?? _receipt(),
       printedResponse = printedResponse ?? _receipt(),
       sharedResponse = sharedResponse ?? _receipt();

  app.SalesOrderDetailDto detail;
  Object? paymentSummaryError;
  Object? settlementError;
  Object? transactionsError;
  Object? timelineError;
  Object? returnSummaryError;
  Object? actionsError;
  Object? cancellationPrecheckError;
  Object? returnExchangePrecheckError;
  app.SalesPaymentTransactionsDto transactions;
  app.AvailablePostSaleActionsDto actions;
  app.CancellationPrecheckDto cancellationPrecheck;
  app.ReturnExchangePrecheckDto returnExchangePrecheck;
  Object getReceiptResponse;
  Object generateResponse;
  Object printedResponse;
  Object sharedResponse;
  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];
  app.SalesOrderCancellationDetailDto cancellationDetail = _cancellationDetail();
  Object? cancellationDetailError;
  Object? cancellationConfirmError;
  app.SalesOrderCancellationResultDto cancellationConfirmResult;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (command is app.GenerateSalesReceiptCommand) {
      return _unwrap(generateResponse);
    }
    if (command is app.RecordSalesReceiptPrintedCommand) {
      return _unwrap(printedResponse);
    }
    if (command is app.RecordSalesReceiptSharedCommand) {
      return _unwrap(sharedResponse);
    }
    if (command is app.ConfirmSalesOrderCancellationCommand) {
      final error = cancellationConfirmError;
      if (error != null) throw error;
      return cancellationConfirmResult as TResult;
    }
    throw UnsupportedError('unexpected command ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is app.GetSalesOrderDetailQuery) {
      return detail as TResult;
    }
    if (query is app.GetSalesOrderPaymentSummaryQuery) {
      final error = paymentSummaryError;
      if (error != null) throw error;
      return _paymentSummary() as TResult;
    }
    if (query is app.GetSalesOrderSettlementQuery) {
      final error = settlementError;
      if (error != null) throw error;
      return _settlement() as TResult;
    }
    if (query is app.GetSalesOrderPaymentTransactionsQuery) {
      final error = transactionsError;
      if (error != null) throw error;
      return transactions as TResult;
    }
    if (query is app.GetSalesOrderTimelineQuery) {
      final error = timelineError;
      if (error != null) throw error;
      return _timeline() as TResult;
    }
    if (query is app.GetSalesOrderReturnSummaryQuery) {
      final error = returnSummaryError;
      if (error != null) throw error;
      return _returnSummary() as TResult;
    }
    if (query is app.GetAvailablePostSaleActionsQuery) {
      final error = actionsError;
      if (error != null) throw error;
      return actions as TResult;
    }
    if (query is app.GetSalesOrderCancellationQuery) {
      final error = cancellationDetailError;
      if (error != null) throw error;
      return cancellationDetail as TResult;
    }
    if (query is app.PrecheckSalesOrderCancellationQuery) {
      final error = cancellationPrecheckError;
      if (error != null) throw error;
      return cancellationPrecheck as TResult;
    }
    if (query is app.PrecheckReturnExchangeQuery) {
      final error = returnExchangePrecheckError;
      if (error != null) throw error;
      return returnExchangePrecheck as TResult;
    }
    if (query is app.GetSalesOrderOriginalReceiptQuery) {
      return _receipt().document as TResult;
    }
    if (query is app.GetSalesReceiptQuery) {
      return _unwrap(getReceiptResponse);
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }

  TResult _unwrap<TResult>(Object response) {
    if (response is _Failure) throw response.error;
    return response as TResult;
  }
}

final class _Failure {
  const _Failure(this.error);
  final Object error;
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

final class _DeferredSectionsModule implements app.ISalesModule {
  final Completer<app.SalesOrderDetailDto> _detail = Completer();
  final Completer<void> detailStarted = Completer();
  final Map<Type, Completer<Object>> _sectionCompleters = {
    app.GetSalesOrderPaymentSummaryQuery: Completer<Object>(),
    app.GetSalesOrderSettlementQuery: Completer<Object>(),
    app.GetSalesOrderPaymentTransactionsQuery: Completer<Object>(),
    app.GetSalesOrderTimelineQuery: Completer<Object>(),
    app.GetSalesOrderReturnSummaryQuery: Completer<Object>(),
    app.GetAvailablePostSaleActionsQuery: Completer<Object>(),
  };

  void completeDetail(app.SalesOrderDetailDto dto) => _detail.complete(dto);

  void completeAllSections() {
    _sectionCompleters[app.GetSalesOrderPaymentSummaryQuery]!.complete(_paymentSummary());
    _sectionCompleters[app.GetSalesOrderSettlementQuery]!.complete(_settlement());
    _sectionCompleters[app.GetSalesOrderPaymentTransactionsQuery]!.complete(
      _transactionsPage(items: [_cashTx(400000), _bankTx(600000)], hasMore: false),
    );
    _sectionCompleters[app.GetSalesOrderTimelineQuery]!.complete(_timeline());
    _sectionCompleters[app.GetSalesOrderReturnSummaryQuery]!.complete(_returnSummary());
    _sectionCompleters[app.GetAvailablePostSaleActionsQuery]!.complete(_availableActions());
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is app.GetSalesOrderDetailQuery) {
      if (!detailStarted.isCompleted) detailStarted.complete();
      return _detail.future as Future<TResult>;
    }
    final completer = _sectionCompleters[query.runtimeType];
    if (completer == null) {
      throw UnsupportedError('unexpected query ${query.runtimeType}');
    }
    return completer.future.then((value) => value as TResult);
  }
}

final class _VersionedRefreshModule implements app.ISalesModule {
  _VersionedRefreshModule();

  app.SalesOrderDetailDto nextDetail = _detail(version: 7);
  app.SalesOrderPaymentSummaryDto nextPaymentSummary = _paymentSummary();
  app.SalesPaymentTransactionsDto nextTransactions = _transactionsPage(
    items: [_cashTx(400000), _bankTx(600000)],
    hasMore: false,
  );
  app.SalesOrderTimelineDto nextTimeline = _timeline();
  final List<Object> queries = <Object>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is app.GetSalesOrderDetailQuery) return nextDetail as TResult;
    if (query is app.GetSalesOrderPaymentSummaryQuery) {
      return nextPaymentSummary as TResult;
    }
    if (query is app.GetSalesOrderSettlementQuery) return _settlement() as TResult;
    if (query is app.GetSalesOrderPaymentTransactionsQuery) {
      return nextTransactions as TResult;
    }
    if (query is app.GetSalesOrderTimelineQuery) return nextTimeline as TResult;
    if (query is app.GetSalesOrderReturnSummaryQuery) return _returnSummary() as TResult;
    if (query is app.GetAvailablePostSaleActionsQuery) return _availableActions() as TResult;
    if (query is app.GetSalesReceiptQuery) return _receipt() as TResult;
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }
}

final class _DeferredReceiptModule implements app.ISalesModule {
  app.SalesOrderDetailDto nextDetail = _detail(version: 7);
  final Completer<app.SalesReceiptDto> _receiptCompleter = Completer();
  final Completer<void> receiptStarted = Completer();

  void completeReceipt(app.SalesReceiptDto receipt) {
    if (!_receiptCompleter.isCompleted) {
      _receiptCompleter.complete(receipt);
    }
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is app.GetSalesOrderDetailQuery) return nextDetail as TResult;
    if (query is app.GetSalesOrderPaymentSummaryQuery) return _paymentSummary() as TResult;
    if (query is app.GetSalesOrderSettlementQuery) return _settlement() as TResult;
    if (query is app.GetSalesOrderPaymentTransactionsQuery) {
      return _transactionsPage(
            items: [_cashTx(400000), _bankTx(600000)],
            hasMore: false,
          )
          as TResult;
    }
    if (query is app.GetSalesOrderTimelineQuery) return _timeline() as TResult;
    if (query is app.GetSalesOrderReturnSummaryQuery) return _returnSummary() as TResult;
    if (query is app.GetAvailablePostSaleActionsQuery) return _availableActions() as TResult;
    if (query is app.GetSalesReceiptQuery) {
      if (!receiptStarted.isCompleted) receiptStarted.complete();
      return _receiptCompleter.future as Future<TResult>;
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }
}

final class _ContractErrorModule implements app.ISalesModule {
  const _ContractErrorModule(this.code, {this.message});

  final String code;
  final String? message;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    throw app.SalesContractException(code, message: message);
  }
}

final class _SucceedThenFailModule implements app.ISalesModule {
  _SucceedThenFailModule({required this.detail, required this.error});

  final app.SalesOrderDetailDto detail;
  final Object error;
  int detailCalls = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is app.GetSalesOrderDetailQuery) {
      detailCalls++;
      if (detailCalls > 1) throw error;
      return detail as TResult;
    }
    // After first core success, section reads may race; return empty successes.
    if (query is app.GetSalesOrderPaymentSummaryQuery) return _paymentSummary() as TResult;
    if (query is app.GetSalesOrderSettlementQuery) return _settlement() as TResult;
    if (query is app.GetSalesOrderPaymentTransactionsQuery) {
      return _transactionsPage(items: const [], hasMore: false) as TResult;
    }
    if (query is app.GetSalesOrderTimelineQuery) {
      return _timeline(entries: const []) as TResult;
    }
    if (query is app.GetSalesOrderReturnSummaryQuery) {
      return app.SalesOrderReturnSummaryDto(salesOrderId: 'order-1', returns: const []) as TResult;
    }
    if (query is app.GetAvailablePostSaleActionsQuery) {
      return _availableActions() as TResult;
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }
}

final class _ThrowingModule implements app.ISalesModule {
  const _ThrowingModule(this.error);

  final Object error;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    throw error;
  }
}

final class _StaleAwareModule implements app.ISalesModule {
  final List<Completer<app.SalesOrderDetailDto>> results = [];
  final Completer<void> firstQueryStarted = Completer();
  final Completer<void> secondQueryStarted = Completer();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('unused');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is! app.GetSalesOrderDetailQuery) {
      // Ignore section reads for this stale-core scenario.
      return Future<TResult>.value(_emptySectionResult<TResult>(query));
    }
    final completer = Completer<app.SalesOrderDetailDto>();
    results.add(completer);
    if (results.length == 1) firstQueryStarted.complete();
    if (results.length == 2) secondQueryStarted.complete();
    return completer.future as Future<TResult>;
  }
}

T _emptySectionResult<T>(IQuery<T> query) {
  if (query is app.GetSalesOrderPaymentSummaryQuery) {
    return _paymentSummary() as T;
  }
  if (query is app.GetSalesOrderSettlementQuery) {
    return _settlement() as T;
  }
  if (query is app.GetSalesOrderPaymentTransactionsQuery) {
    return _transactionsPage(items: const [], hasMore: false) as T;
  }
  if (query is app.GetSalesOrderTimelineQuery) {
    return _timeline(entries: const []) as T;
  }
  if (query is app.GetSalesOrderReturnSummaryQuery) {
    return app.SalesOrderReturnSummaryDto(salesOrderId: 'order-1', returns: const []) as T;
  }
  if (query is app.GetAvailablePostSaleActionsQuery) {
    return _availableActions() as T;
  }
  throw UnsupportedError('unexpected query ${query.runtimeType}');
}

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
