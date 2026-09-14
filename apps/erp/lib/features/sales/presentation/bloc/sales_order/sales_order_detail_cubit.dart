import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../models/sales_receipt/sales_receipt_device_action.dart';
import '../../models/sales_receipt/sales_receipt_operation_state.dart';
import '../../models/sales_order/sales_post_sale_navigation_intent.dart';
import '../../support/sales_order_cancellation_attempt_factory.dart';
import '../../support/sales_order_detail_mapper.dart';
import '../../support/sales_receipt_operation_handler.dart';
import 'sales_order_detail_post_sale_actions.dart';
import 'sales_order_detail_sections_loader.dart';
import 'sales_order_detail_state.dart';
import 'sales_transaction_result_issue.dart';

class SalesOrderDetailCubit extends Cubit<SalesOrderDetailState> {
  SalesOrderDetailCubit({
    required this.orderId,
    required this.salesModule,
    required this.executionContext,
    SalesOrderCancellationAttemptFactory? cancellationAttemptFactory,
  }) : _cancellationAttemptFactory = cancellationAttemptFactory,
       super(const SalesOrderDetailState()) {
    _receiptOps = SalesReceiptOperationHandler(
      salesOrderId: orderId,
      salesModule: salesModule,
      executionContext: executionContext,
      sourceVersion: () => state.sourceVersion ?? 0,
      hasSourceVersion: () => state.sourceVersion != null,
      knownReceiptId: () => state.currentReceiptId,
      setKnownReceiptId: (id) {
        if (isClosed) return;
        emit(state.copyWith(currentReceiptId: id));
      },
      readReceipt: () => state.receipt,
      emitReceipt: _emitReceipt,
      isClosed: () => isClosed,
      currentGeneration: () => _requestGeneration,
    );
  }

  final String orderId;
  final ISalesModule salesModule;
  final IExecutionContext executionContext;
  final SalesOrderCancellationAttemptFactory? _cancellationAttemptFactory;
  late final SalesReceiptOperationHandler _receiptOps;
  int _requestGeneration = 0;

  Future<void> load() => _loadCore();

  Future<void> refresh() => _loadCore();

  Future<void> ensureReceipt() => _receiptOps.ensureReceipt();

  Future<SalesReceiptDto?> viewReceipt() async {
    await ensureReceipt();
    final receipt = state.receipt;
    if (receipt.status != SalesReceiptOperationStatus.ready || receipt.value == null) {
      return null;
    }
    return receipt.value;
  }

  Future<void> printReceipt(SalesReceiptDeviceAction action) => _receiptOps.printReceipt(action);

  Future<void> shareReceipt(SalesReceiptDeviceAction action) => _receiptOps.shareReceipt(action);

  Future<void> retryPaymentSection() async {
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    final tenantId = await executionContext.requireTenantId();
    final actorId = await executionContext.requireUserId();
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadPayment(
      generation: generation,
      sourceVersion: sourceVersion,
      tenantId: tenantId,
      actorId: actorId,
    );
  }

  Future<void> retryHistorySection() async {
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    final tenantId = await executionContext.requireTenantId();
    final actorId = await executionContext.requireUserId();
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadHistory(
      generation: generation,
      sourceVersion: sourceVersion,
      tenantId: tenantId,
      actorId: actorId,
    );
  }

  Future<void> retryCancellationSection() async {
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    final tenantId = await executionContext.requireTenantId();
    final actorId = await executionContext.requireUserId();
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadCancellation(
      generation: generation,
      sourceVersion: sourceVersion,
      tenantId: tenantId,
      actorId: actorId,
    );
  }

  Future<void> retryActionsSection() => _postSaleActions().retryActionsSection();

  Future<SalesPostSaleNavigationIntent?> requestCancel() => _postSaleActions().requestCancel();

  Future<SalesPostSaleNavigationIntent?> requestReturnExchange() =>
      _postSaleActions().requestReturnExchange();

  /// Confirms SG-10 cancellation. Returns `null` on success; else error message.
  Future<String?> confirmCancellation({required String note}) =>
      _postSaleActions().confirmCancellation(note: note);

  Future<void> loadMoreTransactions() async {
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    final tenantId = await executionContext.requireTenantId();
    final actorId = await executionContext.requireUserId();
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadMoreTransactions(
      generation: generation,
      sourceVersion: sourceVersion,
      tenantId: tenantId,
      actorId: actorId,
    );
  }

  Future<void> _loadCore() async {
    if (isClosed) return;
    final generation = ++_requestGeneration;
    // Drop in-flight get/generate/print/share so completions cannot land on the
    // new core/version (clearReceipt alone only resets Equatable state).
    _receiptOps.invalidate();
    emit(
      state.copyWith(
        status: SalesOrderDetailStatus.loading,
        requestGeneration: generation,
        clearErrorMessage: true,
        paymentStatus: SalesOrderDetailSectionStatus.idle,
        historyStatus: SalesOrderDetailSectionStatus.idle,
        actionsStatus: SalesOrderDetailSectionStatus.idle,
        clearPayment: true,
        clearHistory: true,
        clearActions: true,
        cancellationStatus: SalesOrderDetailSectionStatus.idle,
        clearCancellation: true,
        clearCancellationErrorMessage: true,
        clearPaymentErrorMessage: true,
        clearHistoryErrorMessage: true,
        clearActionsErrorMessage: true,
        clearPrecheckBlockerMessages: true,
        clearPostSaleFeedbackMessage: true,
        clearReceipt: true,
        receiptStatus: SalesOrderDetailSectionStatus.idle,
      ),
    );

    try {
      final tenantId = await executionContext.requireTenantId();
      final actorId = await executionContext.requireUserId();
      if (isClosed || generation != _requestGeneration) return;

      final dto = await salesModule.executeQueryAsync<SalesOrderDetailDto>(
        GetSalesOrderDetailQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: orderId,
        ),
      );
      if (isClosed || generation != _requestGeneration) return;

      final sourceVersion = dto.order.version;
      final isCancelled = dto.order.lifecycleStatus == SalesOrderLifecycleStatus.cancelled;
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          core: SalesOrderDetailMapper.toVm(dto),
          sourceVersion: sourceVersion,
          currentReceiptId: dto.currentReceiptId,
          clearCurrentReceiptId: dto.currentReceiptId == null,
          requestGeneration: generation,
          clearErrorMessage: true,
          paymentStatus: SalesOrderDetailSectionStatus.loading,
          historyStatus: SalesOrderDetailSectionStatus.loading,
          actionsStatus: SalesOrderDetailSectionStatus.loading,
          cancellationStatus: isCancelled
              ? SalesOrderDetailSectionStatus.loading
              : SalesOrderDetailSectionStatus.idle,
          clearPayment: true,
          clearHistory: true,
          clearActions: true,
          clearCancellation: true,
          clearCancellationErrorMessage: true,
          clearPaymentErrorMessage: true,
          clearHistoryErrorMessage: true,
          clearActionsErrorMessage: true,
          clearPrecheckBlockerMessages: true,
          clearPostSaleFeedbackMessage: true,
          clearReceipt: true,
          receiptStatus: SalesOrderDetailSectionStatus.idle,
        ),
      );

      // Do not await dependents before core loaded; fire in parallel.
      unawaited(
        _sectionsLoader().loadAll(
          generation: generation,
          sourceVersion: sourceVersion,
          tenantId: tenantId,
          actorId: actorId,
          isCancelled: isCancelled,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _requestGeneration) return;
      emit(_failureState(error, generation));
    }
  }

  void _emitReceipt(SalesReceiptOperationState receipt) {
    if (isClosed) return;
    emit(
      state.copyWith(
        receipt: receipt,
        receiptStatus: _sectionStatusFor(receipt),
        currentReceiptId: receipt.value?.receiptId ?? state.currentReceiptId,
      ),
    );
  }

  SalesOrderDetailSectionStatus _sectionStatusFor(SalesReceiptOperationState receipt) {
    return switch (receipt.status) {
      SalesReceiptOperationStatus.idle => SalesOrderDetailSectionStatus.idle,
      SalesReceiptOperationStatus.generating ||
      SalesReceiptOperationStatus.printing ||
      SalesReceiptOperationStatus.sharing => SalesOrderDetailSectionStatus.loading,
      SalesReceiptOperationStatus.ready ||
      SalesReceiptOperationStatus.activityWarning => SalesOrderDetailSectionStatus.loaded,
      SalesReceiptOperationStatus.error => switch (receipt.issue) {
        SalesTransactionResultIssue.permissionDenied => SalesOrderDetailSectionStatus.blocked,
        SalesTransactionResultIssue.projectionPending =>
          SalesOrderDetailSectionStatus.projectionPending,
        _ => SalesOrderDetailSectionStatus.error,
      },
    };
  }

  SalesOrderDetailSectionsLoader _sectionsLoader() {
    return SalesOrderDetailSectionsLoader(
      orderId: orderId,
      salesModule: salesModule,
      isClosed: () => isClosed,
      currentGeneration: () => _requestGeneration,
      currentSourceVersion: () => state.sourceVersion,
      readState: () => state,
      emitTransform: (transform) {
        if (isClosed) return;
        emit(transform(state));
      },
    );
  }

  SalesOrderDetailPostSaleActions _postSaleActions() {
    return SalesOrderDetailPostSaleActions(
      orderId: orderId,
      salesModule: salesModule,
      executionContext: executionContext,
      isClosed: () => isClosed,
      currentGeneration: () => _requestGeneration,
      readState: () => state,
      emitTransform: (transform) {
        if (isClosed) return;
        emit(transform(state));
      },
      reloadCore: _loadCore,
      sectionsLoader: _sectionsLoader,
      cancellationAttemptFactory: _cancellationAttemptFactory,
    );
  }

  SalesOrderDetailState _failureState(Object error, int generation) {
    final contract = error is SalesContractException ? error : null;
    final status = switch (contract?.code) {
      'PERMISSION_DENIED' || 'DATA_SCOPE_DENIED' => SalesOrderDetailStatus.blocked,
      'NOT_FOUND' => SalesOrderDetailStatus.notFound,
      'PROJECTION_PENDING' => SalesOrderDetailStatus.projectionPending,
      _ => SalesOrderDetailStatus.error,
    };
    final message = contract?.message;
    final hasMessage = message != null && message.isNotEmpty;
    return state.copyWith(
      status: status,
      requestGeneration: generation,
      errorMessage: hasMessage ? message : null,
      clearErrorMessage: !hasMessage,
      clearCore: true,
      clearSourceVersion: true,
      clearCurrentReceiptId: true,
      paymentStatus: SalesOrderDetailSectionStatus.idle,
      historyStatus: SalesOrderDetailSectionStatus.idle,
      actionsStatus: SalesOrderDetailSectionStatus.idle,
      clearPayment: true,
      clearHistory: true,
      clearActions: true,
      clearPaymentErrorMessage: true,
      clearHistoryErrorMessage: true,
      clearActionsErrorMessage: true,
      clearPrecheckBlockerMessages: true,
      clearPostSaleFeedbackMessage: true,
      clearReceipt: true,
      receiptStatus: SalesOrderDetailSectionStatus.idle,
    );
  }
}
