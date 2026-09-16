import 'package:equatable/equatable.dart';
import 'package:vet45_einvoice_application/application.dart';
import '../../models/sales_order/sales_order_actions_vm.dart';
import '../../models/sales_order_cancellation/sales_order_cancellation_vm.dart';
import '../../models/sales_order/sales_order_detail_vm.dart';
import '../../models/sales_order/sales_order_history_vm.dart';
import '../../models/sales_order_settlement/sales_order_payment_vm.dart';
import '../../models/sales_receipt/sales_receipt_operation_state.dart';

enum SalesOrderDetailStatus {
  initial,
  loading,
  loaded,
  blocked,
  notFound,
  projectionPending,
  error,
}

enum SalesOrderDetailSectionStatus {
  idle,
  loading,
  loaded,
  blocked,
  projectionPending,
  error,
}

class SalesOrderDetailState extends Equatable {
  const SalesOrderDetailState({
    this.core,
    this.sourceVersion,
    this.currentReceiptId,
    this.requestGeneration = 0,
    this.status = SalesOrderDetailStatus.initial,
    this.errorMessage,
    this.payment,
    this.history,
    this.paymentStatus = SalesOrderDetailSectionStatus.idle,
    this.historyStatus = SalesOrderDetailSectionStatus.idle,
    this.paymentErrorMessage,
    this.historyErrorMessage,
    this.receipt = const SalesReceiptOperationState(),
    this.receiptStatus = SalesOrderDetailSectionStatus.idle,
    this.actions,
    this.actionsStatus = SalesOrderDetailSectionStatus.idle,
    this.actionsErrorMessage,
    this.cancellation,
    this.cancellationStatus = SalesOrderDetailSectionStatus.idle,
    this.cancellationErrorMessage,
    this.precheckBlockerMessages = const [],
    this.postSaleFeedbackMessage,
    this.eInvoiceProjection,
  });

  final SalesOrderDetailVm? core;
  final int? sourceVersion;
  final String? currentReceiptId;
  final int requestGeneration;
  final SalesOrderDetailStatus status;
  final String? errorMessage;
  final SalesOrderPaymentVm? payment;
  final SalesOrderHistoryVm? history;
  final SalesOrderDetailSectionStatus paymentStatus;
  final SalesOrderDetailSectionStatus historyStatus;
  final String? paymentErrorMessage;
  final String? historyErrorMessage;
  final SalesReceiptOperationState receipt;
  final SalesOrderDetailSectionStatus receiptStatus;
  final SalesOrderActionsVm? actions;
  final SalesOrderDetailSectionStatus actionsStatus;
  final String? actionsErrorMessage;
  final SalesOrderCancellationVm? cancellation;
  final SalesOrderDetailSectionStatus cancellationStatus;
  final String? cancellationErrorMessage;
  final List<String> precheckBlockerMessages;
  final String? postSaleFeedbackMessage;
  final OrderInvoiceProjectionDto? eInvoiceProjection;

  SalesOrderDetailVm? get vm => core;

  SalesOrderDetailState copyWith({
    SalesOrderDetailVm? core,
    int? sourceVersion,
    String? currentReceiptId,
    int? requestGeneration,
    SalesOrderDetailStatus? status,
    String? errorMessage,
    bool clearCore = false,
    bool clearErrorMessage = false,
    bool clearSourceVersion = false,
    bool clearCurrentReceiptId = false,
    SalesOrderPaymentVm? payment,
    SalesOrderHistoryVm? history,
    bool clearPayment = false,
    bool clearHistory = false,
    SalesOrderDetailSectionStatus? paymentStatus,
    SalesOrderDetailSectionStatus? historyStatus,
    String? paymentErrorMessage,
    String? historyErrorMessage,
    bool clearPaymentErrorMessage = false,
    bool clearHistoryErrorMessage = false,
    SalesReceiptOperationState? receipt,
    bool clearReceipt = false,
    SalesOrderDetailSectionStatus? receiptStatus,
    SalesOrderActionsVm? actions,
    bool clearActions = false,
    SalesOrderDetailSectionStatus? actionsStatus,
    String? actionsErrorMessage,
    bool clearActionsErrorMessage = false,
    SalesOrderCancellationVm? cancellation,
    bool clearCancellation = false,
    SalesOrderDetailSectionStatus? cancellationStatus,
    String? cancellationErrorMessage,
    bool clearCancellationErrorMessage = false,
    List<String>? precheckBlockerMessages,
    bool clearPrecheckBlockerMessages = false,
    String? postSaleFeedbackMessage,
    bool clearPostSaleFeedbackMessage = false,
    OrderInvoiceProjectionDto? eInvoiceProjection,
    bool clearEInvoiceProjection = false,
  }) {
    return SalesOrderDetailState(
      core: clearCore ? null : (core ?? this.core),
      sourceVersion: clearSourceVersion ? null : (sourceVersion ?? this.sourceVersion),
      currentReceiptId: clearCurrentReceiptId ? null : (currentReceiptId ?? this.currentReceiptId),
      requestGeneration: requestGeneration ?? this.requestGeneration,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      payment: clearPayment ? null : (payment ?? this.payment),
      history: clearHistory ? null : (history ?? this.history),
      paymentStatus: paymentStatus ?? this.paymentStatus,
      historyStatus: historyStatus ?? this.historyStatus,
      paymentErrorMessage: clearPaymentErrorMessage
          ? null
          : (paymentErrorMessage ?? this.paymentErrorMessage),
      historyErrorMessage: clearHistoryErrorMessage
          ? null
          : (historyErrorMessage ?? this.historyErrorMessage),
      receipt: clearReceipt ? const SalesReceiptOperationState() : (receipt ?? this.receipt),
      receiptStatus: receiptStatus ?? this.receiptStatus,
      actions: clearActions ? null : (actions ?? this.actions),
      actionsStatus: actionsStatus ?? this.actionsStatus,
      actionsErrorMessage: clearActionsErrorMessage
          ? null
          : (actionsErrorMessage ?? this.actionsErrorMessage),
      cancellation: clearCancellation ? null : (cancellation ?? this.cancellation),
      cancellationStatus: cancellationStatus ?? this.cancellationStatus,
      cancellationErrorMessage: clearCancellationErrorMessage
          ? null
          : (cancellationErrorMessage ?? this.cancellationErrorMessage),
      precheckBlockerMessages: clearPrecheckBlockerMessages
          ? const []
          : (precheckBlockerMessages ?? this.precheckBlockerMessages),
      postSaleFeedbackMessage: clearPostSaleFeedbackMessage
          ? null
          : (postSaleFeedbackMessage ?? this.postSaleFeedbackMessage),
      eInvoiceProjection: clearEInvoiceProjection
          ? null
          : (eInvoiceProjection ?? this.eInvoiceProjection),
    );
  }

  @override
  List<Object?> get props => [
    core,
    sourceVersion,
    currentReceiptId,
    requestGeneration,
    status,
    errorMessage,
    payment,
    history,
    paymentStatus,
    historyStatus,
    paymentErrorMessage,
    historyErrorMessage,
    receipt,
    receiptStatus,
    actions,
    actionsStatus,
    actionsErrorMessage,
    cancellation,
    cancellationStatus,
    cancellationErrorMessage,
    precheckBlockerMessages,
    postSaleFeedbackMessage,
    eInvoiceProjection,
  ];
}
