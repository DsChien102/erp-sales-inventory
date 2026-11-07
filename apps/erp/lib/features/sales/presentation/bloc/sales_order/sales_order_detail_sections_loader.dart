import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:vet45_sales_application/application.dart';

import '../../models/sales_order/sales_order_actions_vm.dart';
import '../../models/sales_order/sales_order_history_vm.dart';
import '../../support/sales_order_detail_mapper.dart';
import 'sales_order_detail_state.dart';

typedef SalesOrderDetailStateEmitter =
    void Function(SalesOrderDetailState Function(SalesOrderDetailState current));

/// Loads S17/S18 dependent sections after S16 core success.
final class SalesOrderDetailSectionsLoader {
  SalesOrderDetailSectionsLoader({
    required this.orderId,
    required this.salesModule,
    required this.paymentRepository,
    required this.isClosed,
    required this.currentGeneration,
    required this.currentSourceVersion,
    required this.readState,
    required this.emitTransform,
  });

  final String orderId;
  final ISalesModule salesModule;
  final SalesPaymentRepository paymentRepository;
  final bool Function() isClosed;
  final int Function() currentGeneration;
  final int? Function() currentSourceVersion;
  final SalesOrderDetailState Function() readState;
  final SalesOrderDetailStateEmitter emitTransform;

  Future<void> loadAll({
    required int generation,
    required int sourceVersion,
    required String tenantId,
    required String actorId,
    bool isCancelled = false,
  }) {
    return Future.wait<void>([
      loadPayment(
        generation: generation,
        sourceVersion: sourceVersion,
        tenantId: tenantId,
        actorId: actorId,
      ),
      loadHistory(
        generation: generation,
        sourceVersion: sourceVersion,
        tenantId: tenantId,
        actorId: actorId,
      ),
      loadActions(
        generation: generation,
        sourceVersion: sourceVersion,
        tenantId: tenantId,
        actorId: actorId,
      ),
      // S27: cancellation detail only exists once the order is cancelled.
      if (isCancelled)
        loadCancellation(
          generation: generation,
          sourceVersion: sourceVersion,
          tenantId: tenantId,
          actorId: actorId,
        ),
    ]);
  }

  Future<void> loadCancellation({
    required int generation,
    required int sourceVersion,
    required String tenantId,
    required String actorId,
  }) async {
    if (!_stillCurrent(generation, sourceVersion)) return;
    emitTransform(
      (state) => state.copyWith(
        cancellationStatus: SalesOrderDetailSectionStatus.loading,
        clearCancellation: true,
        clearCancellationErrorMessage: true,
      ),
    );

    try {
      final dto = await salesModule.executeQueryAsync<SalesOrderCancellationDetailDto>(
        GetSalesOrderCancellationQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: orderId,
          expectedSourceVersion: sourceVersion,
        ),
      );
      if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;
      emitTransform(
        (state) => state.copyWith(
          cancellationStatus: SalesOrderDetailSectionStatus.loaded,
          cancellation: SalesOrderDetailMapper.toCancellationVm(dto),
          clearCancellationErrorMessage: true,
        ),
      );
    } catch (error) {
      if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;
      final contract = error is SalesContractException ? error : null;
      // A cancelled order whose projection has not yet materialized is pending,
      // not an error; do not discard the already-loaded core detail.
      final status = switch (contract?.code) {
        'PERMISSION_DENIED' || 'DATA_SCOPE_DENIED' => SalesOrderDetailSectionStatus.blocked,
        'PROJECTION_PENDING' ||
        'NOT_FOUND' ||
        'IMPACT_PENDING' => SalesOrderDetailSectionStatus.projectionPending,
        _ => SalesOrderDetailSectionStatus.error,
      };
      final message = contract?.message;
      final hasMessage = message != null && message.isNotEmpty;
      emitTransform(
        (state) => state.copyWith(
          cancellationStatus: status,
          cancellationErrorMessage: hasMessage ? message : null,
          clearCancellationErrorMessage: !hasMessage,
          clearCancellation: true,
        ),
      );
    }
  }

  Future<void> loadActions({
    required int generation,
    required int sourceVersion,
    required String tenantId,
    required String actorId,
  }) async {
    if (!_stillCurrent(generation, sourceVersion)) return;
    emitTransform(
      (state) => state.copyWith(
        actionsStatus: SalesOrderDetailSectionStatus.loading,
        clearActions: true,
        clearActionsErrorMessage: true,
        clearPrecheckBlockerMessages: true,
        clearPostSaleFeedbackMessage: true,
      ),
    );

    try {
      final dto = await salesModule.executeQueryAsync<AvailablePostSaleActionsDto>(
        GetAvailablePostSaleActionsQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: orderId,
          expectedSourceVersion: sourceVersion,
        ),
      );
      if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;
      emitTransform(
        (state) => state.copyWith(
          actionsStatus: SalesOrderDetailSectionStatus.loaded,
          actions: SalesOrderActionsVm(
            canCancel: dto.canCancel,
            canReturnExchange: dto.canReturnExchange,
          ),
          clearActionsErrorMessage: true,
        ),
      );
    } catch (error) {
      if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;
      emitTransform((state) => _sectionFailure(state, error, section: _SectionKind.actions));
    }
  }

  Future<void> loadPayment({
    required int generation,
    required int sourceVersion,
    required String tenantId,
    required String actorId,
  }) async {
    if (!_stillCurrent(generation, sourceVersion)) return;
    emitTransform(
      (state) => state.copyWith(
        paymentStatus: SalesOrderDetailSectionStatus.loading,
        clearPayment: true,
        clearPaymentErrorMessage: true,
      ),
    );

    SalesOrderPaymentSummaryDto? summary;
    SalesOrderSettlementDto? settlement;
    SalesPaymentTransactionsDto? transactions;
    Object? firstError;

    Future<void> runOne(Future<void> Function() work) async {
      try {
        await work();
      } catch (error) {
        firstError ??= error;
      }
    }

    await Future.wait<void>([
      runOne(() async {
        summary = await paymentRepository.getSummary(
          salesOrderId: orderId,
          expectedSourceVersion: sourceVersion,
        );
      }),
      runOne(() async {
        settlement = await paymentRepository.getSettlement(
          salesOrderId: orderId,
          expectedSourceVersion: sourceVersion,
        );
      }),
      runOne(() async {
        transactions = await paymentRepository.getTransactions(
          salesOrderId: orderId,
          expectedSourceVersion: sourceVersion,
        );
      }),
    ]);

    if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;

    final error = firstError;
    if (error != null || summary == null || settlement == null || transactions == null) {
      emitTransform(
        (state) => _sectionFailure(
          state,
          error ?? Exception('payment incomplete'),
          section: _SectionKind.payment,
        ),
      );
      return;
    }

    emitTransform(
      (state) => state.copyWith(
        paymentStatus: SalesOrderDetailSectionStatus.loaded,
        payment: SalesOrderDetailMapper.toPaymentVm(
          summary: summary!,
          settlement: settlement!,
          transactions: transactions!,
        ),
        clearPaymentErrorMessage: true,
      ),
    );
  }

  Future<void> loadHistory({
    required int generation,
    required int sourceVersion,
    required String tenantId,
    required String actorId,
  }) async {
    if (!_stillCurrent(generation, sourceVersion)) return;
    emitTransform(
      (state) => state.copyWith(
        historyStatus: SalesOrderDetailSectionStatus.loading,
        clearHistory: true,
        clearHistoryErrorMessage: true,
      ),
    );

    SalesOrderTimelineDto? timeline;
    SalesOrderReturnSummaryDto? returns;
    Object? firstError;
    var timelineOk = false;
    var returnsOk = false;

    Future<void> runOne(Future<void> Function() work) async {
      try {
        await work();
      } catch (error) {
        firstError ??= error;
      }
    }

    await Future.wait<void>([
      runOne(() async {
        timeline = await salesModule.executeQueryAsync<SalesOrderTimelineDto>(
          GetSalesOrderTimelineQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: orderId,
            expectedSourceVersion: sourceVersion,
          ),
        );
        timelineOk = true;
      }),
      runOne(() async {
        returns = await salesModule.executeQueryAsync<SalesOrderReturnSummaryDto>(
          GetSalesOrderReturnSummaryQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: orderId,
            expectedSourceVersion: sourceVersion,
          ),
        );
        returnsOk = true;
      }),
    ]);

    if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;

    SalesOrderHistoryVm? partial;
    if (timelineOk && timeline != null) {
      partial = SalesOrderDetailMapper.mergeTimeline(current: partial, timeline: timeline!);
    }
    if (returnsOk && returns != null) {
      partial = SalesOrderDetailMapper.mergeReturns(current: partial, returns: returns!);
    }

    final error = firstError;
    if (error != null || !timelineOk || !returnsOk) {
      emitTransform((state) {
        final failed = _sectionFailure(
          state,
          error ?? Exception('history incomplete'),
          section: _SectionKind.history,
        );
        if (failed.historyStatus == SalesOrderDetailSectionStatus.blocked) {
          return failed.copyWith(clearHistory: true);
        }
        return failed.copyWith(history: partial);
      });
      return;
    }

    emitTransform(
      (state) => state.copyWith(
        historyStatus: SalesOrderDetailSectionStatus.loaded,
        history: SalesOrderDetailMapper.toHistoryVm(
          timeline: timeline!,
          returns: returns!,
        ),
        clearHistoryErrorMessage: true,
      ),
    );
  }

  Future<void> loadMoreTransactions({
    required int generation,
    required int sourceVersion,
    required String tenantId,
    required String actorId,
  }) async {
    final current = readState().payment;
    final cursor = current?.nextTransactionsCursor;
    if (current == null || !current.hasMoreTransactions || cursor == null) return;
    if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;

    try {
      final page = await paymentRepository.getTransactions(
        salesOrderId: orderId,
        expectedSourceVersion: sourceVersion,
        cursor: cursor,
      );
      if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;
      emitTransform(
        (state) => state.copyWith(
          payment: SalesOrderDetailMapper.mergeTransactionsPage(
            current: state.payment ?? current,
            page: page,
          ),
          paymentStatus: SalesOrderDetailSectionStatus.loaded,
          clearPaymentErrorMessage: true,
        ),
      );
    } catch (_) {
      if (!_stillCurrent(generation, sourceVersion) || isClosed()) return;
      emitTransform(
        (state) => state.copyWith(
          payment: (state.payment ?? current).copyWith(transactionsLoadMoreError: true),
          paymentStatus: SalesOrderDetailSectionStatus.loaded,
        ),
      );
    }
  }

  bool _stillCurrent(int generation, int sourceVersion) {
    return !isClosed() &&
        currentGeneration() == generation &&
        currentSourceVersion() == sourceVersion;
  }

  SalesOrderDetailState _sectionFailure(
    SalesOrderDetailState state,
    Object error, {
    required _SectionKind section,
  }) {
    // Hai kiểu lỗi cùng lúc tới 8-A4: AppException (thanh toán) và
    // SalesContractException (lịch sử / thao tác / huỷ). AppException không
    // mang câu thô của server (TH-05 6.4).
    final contract = error is SalesContractException ? error : null;
    final code = error is AppException ? error.code : contract?.code;
    final status = switch (code) {
      'PERMISSION_DENIED' ||
      'NO_PERMISSION' ||
      'DATA_SCOPE_DENIED' => SalesOrderDetailSectionStatus.blocked,
      'PROJECTION_PENDING' => SalesOrderDetailSectionStatus.projectionPending,
      _ => SalesOrderDetailSectionStatus.error,
    };
    final message = contract?.message;
    final hasMessage = message != null && message.isNotEmpty;
    return switch (section) {
      _SectionKind.payment => state.copyWith(
        paymentStatus: status,
        paymentErrorMessage: hasMessage ? message : null,
        clearPaymentErrorMessage: !hasMessage,
        clearPayment: status == SalesOrderDetailSectionStatus.blocked,
      ),
      _SectionKind.history => state.copyWith(
        historyStatus: status,
        historyErrorMessage: hasMessage ? message : null,
        clearHistoryErrorMessage: !hasMessage,
        clearHistory: status == SalesOrderDetailSectionStatus.blocked,
      ),
      _SectionKind.actions => state.copyWith(
        actionsStatus: status,
        actionsErrorMessage: hasMessage ? message : null,
        clearActionsErrorMessage: !hasMessage,
        clearActions: status == SalesOrderDetailSectionStatus.blocked,
      ),
    };
  }
}

enum _SectionKind { payment, history, actions }
