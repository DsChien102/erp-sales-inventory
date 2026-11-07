import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:erp/features/sales/logic/sales_order_detail_post_sale_actions.dart';
import 'package:erp/features/sales/logic/sales_order_detail_sections_loader.dart';
import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import 'package:erp/features/sales/logic/sales_receipt_operation_handler.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_issue.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_detail_vm.dart'
    show SalesEInvoiceStatus;
import 'package:erp/features/sales/presentation/models/sales_order/sales_post_sale_navigation_intent.dart';
import 'package:erp/features/sales/presentation/models/sales_receipt/sales_receipt_device_action.dart';
import 'package:erp/features/sales/presentation/models/sales_receipt/sales_receipt_operation_state.dart';
import 'package:erp/features/sales/presentation/support/sales_order_cancellation_attempt_factory.dart';
import 'package:erp/features/sales/presentation/support/sales_order_detail_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

class SalesOrderDetailCubit extends Cubit<SalesOrderDetailState> {
  SalesOrderDetailCubit({
    required this.orderId,
    required this.orderRepository,
    required this.receiptRepository,
    required this.paymentRepository,
    required this.cancellationRepository,
    required this.returnExchangeRepository,
    required this.executionContext,
    SalesOrderCancellationAttemptFactory? cancellationAttemptFactory,
    IEInvoiceModule? eInvoiceModule,
  }) : _cancellationAttemptFactory = cancellationAttemptFactory,
       _eInvoiceModule = eInvoiceModule,
       super(const SalesOrderDetailState()) {
    _receiptOps = SalesReceiptOperationHandler(
      salesOrderId: orderId,
      repository: receiptRepository,
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
  final SalesOrderRepository orderRepository;
  final SalesReceiptRepository receiptRepository;
  final SalesPaymentRepository paymentRepository;
  final SalesCancellationRepository cancellationRepository;
  final ReturnExchangeRepository returnExchangeRepository;
  final IExecutionContext executionContext;
  final SalesOrderCancellationAttemptFactory? _cancellationAttemptFactory;

  /// Tùy chọn: khi có, badge HĐĐT trên thẻ chứng từ phản ánh trạng thái thật.
  /// Khi null (test cũ, host chưa nối), badge giữ `notIssued` như trước.
  final IEInvoiceModule? _eInvoiceModule;

  /// Đọc projection HĐĐT để điền badge và cung cấp dữ liệu cho OrderEInvoiceSection.
  /// Không bao giờ ném: einvoice hỏng thì trang chi tiết đơn vẫn phải mở được.
  Future<OrderInvoiceProjectionDto?> _loadEInvoiceProjection() async {
    final module = _eInvoiceModule;
    if (module == null) return null;
    try {
      final tenantId = await executionContext.requireTenantId();
      final actorId = await executionContext.requireUserId();
      final projection = await module.executeQueryAsync(
        GetOrderInvoiceProjectionQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: orderId,
        ),
      );
      return projection;
    } catch (_) {
      return null;
    }
  }

  static SalesEInvoiceStatus _mapProjectionToEInvoiceStatus(
    OrderInvoiceProjectionDto projection,
  ) {
    return switch (projection.issuanceDisplayState) {
      IssuanceDisplayState.notIssued => SalesEInvoiceStatus.notIssued,
      IssuanceDisplayState.processing => SalesEInvoiceStatus.issuing,
      IssuanceDisplayState.failed => SalesEInvoiceStatus.failed,
      IssuanceDisplayState.issued =>
        projection.deliveryDisplayState == DeliveryDisplayState.sent
            ? SalesEInvoiceStatus.sent
            : SalesEInvoiceStatus.issued,
    };
  }

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

  /// As-sold receipt for the «Đơn gốc» tab. Read-only: it has no receipt id,
  /// so print/share of it records no receipt activity.
  Future<SalesReceiptDocumentDto> viewOriginalReceipt() =>
      receiptRepository.getOriginal(salesOrderId: orderId);

  Future<void> printReceipt(SalesReceiptDeviceAction action) => _receiptOps.printReceipt(action);

  Future<void> shareReceipt(SalesReceiptDeviceAction action) => _receiptOps.shareReceipt(action);

  Future<void> retryPaymentSection() async {
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadPayment(
      generation: generation,
      sourceVersion: sourceVersion,
    );
  }

  Future<void> retryHistorySection() async {
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadHistory(
      generation: generation,
      sourceVersion: sourceVersion,
    );
  }

  Future<void> retryCancellationSection() async {
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadCancellation(
      generation: generation,
      sourceVersion: sourceVersion,
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
    if (isClosed || generation != _requestGeneration) return;
    await _sectionsLoader().loadMoreTransactions(
      generation: generation,
      sourceVersion: sourceVersion,
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
        clearEInvoiceProjection: true,
      ),
    );

    try {
      if (isClosed || generation != _requestGeneration) return;

      final detailFuture = orderRepository.getDetail(salesOrderId: orderId);
      final eInvoiceFuture = _loadEInvoiceProjection();

      final dto = await detailFuture;
      final eInvoiceProjection = await eInvoiceFuture;
      final eInvoiceStatus = eInvoiceProjection != null
          ? _mapProjectionToEInvoiceStatus(eInvoiceProjection)
          : SalesEInvoiceStatus.notIssued;
      if (isClosed || generation != _requestGeneration) return;

      final sourceVersion = dto.order.version;
      final isCancelled = dto.order.lifecycleStatus == SalesOrderLifecycleStatus.cancelled;
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          core: SalesOrderDetailMapper.toVm(dto, eInvoiceStatus: eInvoiceStatus),
          eInvoiceProjection: eInvoiceProjection,
          clearEInvoiceProjection: eInvoiceProjection == null,
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
      orderRepository: orderRepository,
      paymentRepository: paymentRepository,
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
      cancellationRepository: cancellationRepository,
      returnExchangeRepository: returnExchangeRepository,
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
    final code = error is AppException ? error.code : null;
    final status = switch (code) {
      'NO_PERMISSION' || 'DATA_SCOPE_DENIED' => SalesOrderDetailStatus.blocked,
      'NOT_FOUND' => SalesOrderDetailStatus.notFound,
      'PROJECTION_PENDING' => SalesOrderDetailStatus.projectionPending,
      _ => SalesOrderDetailStatus.error,
    };
    return state.copyWith(
      status: status,
      requestGeneration: generation,
      clearErrorMessage: true,
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
