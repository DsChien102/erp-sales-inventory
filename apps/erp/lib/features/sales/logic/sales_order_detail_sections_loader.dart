import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_actions_vm.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_history_vm.dart';
import 'package:erp/features/sales/presentation/support/sales_order_detail_mapper.dart';
import 'package:erp/features/sales/data/models.dart';

import 'sales_order_detail_state.dart';

typedef SalesOrderDetailStateEmitter =
    void Function(SalesOrderDetailState Function(SalesOrderDetailState current));

/// Loads S17/S18 dependent sections after S16 core success.
final class SalesOrderDetailSectionsLoader {
  SalesOrderDetailSectionsLoader({
    required this.orderId,
    required this.orderRepository,
    required this.paymentRepository,
    required this.isClosed,
    required this.currentGeneration,
    required this.currentSourceVersion,
    required this.readState,
    required this.emitTransform,
  });

  final String orderId;
  final SalesOrderRepository orderRepository;
  final SalesPaymentRepository paymentRepository;
  final bool Function() isClosed;
  final int Function() currentGeneration;
  final int? Function() currentSourceVersion;
  final SalesOrderDetailState Function() readState;
  final SalesOrderDetailStateEmitter emitTransform;

  Future<void> loadAll({
    required int generation,
    required int sourceVersion,
    bool isCancelled = false,
  }) {
    return Future.wait<void>([
      loadPayment(
        generation: generation,
        sourceVersion: sourceVersion,
      ),
      loadHistory(
        generation: generation,
        sourceVersion: sourceVersion,
      ),
      loadActions(
        generation: generation,
        sourceVersion: sourceVersion,
      ),
      // S27: cancellation detail only exists once the order is cancelled.
      if (isCancelled)
        loadCancellation(
          generation: generation,
          sourceVersion: sourceVersion,
        ),
    ]);
  }

  Future<void> loadCancellation({
    required int generation,
    required int sourceVersion,
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
      final dto = await orderRepository.getCancellation(
        salesOrderId: orderId,
        expectedSourceVersion: sourceVersion,
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
      final code = error is AppException ? error.code : null;
      // A cancelled order whose projection has not yet materialized is pending,
      // not an error; do not discard the already-loaded core detail.
      final status = switch (code) {
        'NO_PERMISSION' || 'DATA_SCOPE_DENIED' => SalesOrderDetailSectionStatus.blocked,
        'PROJECTION_PENDING' ||
        'NOT_FOUND' ||
        'IMPACT_PENDING' => SalesOrderDetailSectionStatus.projectionPending,
        _ => SalesOrderDetailSectionStatus.error,
      };
      emitTransform(
        (state) => state.copyWith(
          cancellationStatus: status,
          clearCancellationErrorMessage: true,
          clearCancellation: true,
        ),
      );
    }
  }

  Future<void> loadActions({
    required int generation,
    required int sourceVersion,
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
      final dto = await orderRepository.getAvailableActions(
        salesOrderId: orderId,
        expectedSourceVersion: sourceVersion,
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
        timeline = await orderRepository.getTimeline(
          salesOrderId: orderId,
          expectedSourceVersion: sourceVersion,
        );
        timelineOk = true;
      }),
      runOne(() async {
        returns = await orderRepository.getReturnSummary(
          salesOrderId: orderId,
          expectedSourceVersion: sourceVersion,
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
    // S17/S18/S19: lỗi mang mã phân nhánh (NO_PERMISSION/DATA_SCOPE_DENIED -> blocked,
    // PROJECTION_PENDING -> projectionPending). Mọi section con khi lỗi xoá errorMessage
    // để UI tự fallback chuỗi chuẩn (TH-05 6.4, Bảng 4.4).
    final code = error is AppException ? error.code : null;
    final status = switch (code) {
      'NO_PERMISSION' || 'DATA_SCOPE_DENIED' => SalesOrderDetailSectionStatus.blocked,
      'PROJECTION_PENDING' => SalesOrderDetailSectionStatus.projectionPending,
      _ => SalesOrderDetailSectionStatus.error,
    };
    return switch (section) {
      _SectionKind.payment => state.copyWith(
        paymentStatus: status,
        clearPaymentErrorMessage: true,
        clearPayment: status == SalesOrderDetailSectionStatus.blocked,
      ),
      _SectionKind.history => state.copyWith(
        historyStatus: status,
        clearHistoryErrorMessage: true,
        clearHistory: status == SalesOrderDetailSectionStatus.blocked,
      ),
      _SectionKind.actions => state.copyWith(
        actionsStatus: status,
        clearActionsErrorMessage: true,
        clearActions: status == SalesOrderDetailSectionStatus.blocked,
      ),
    };
  }
}

enum _SectionKind { payment, history, actions }
