import 'package:equatable/equatable.dart';
import 'package:erp/features/einvoice/data/models.dart';

enum OrderInvoiceDeliveryStatus {
  initial,
  loadingContext,
  ready,
  submitting,
  accepted,
  failure,
}

final class OrderInvoiceDeliveryState extends Equatable {
  const OrderInvoiceDeliveryState({
    this.status = OrderInvoiceDeliveryStatus.initial,
    this.sheetContext,
    this.errorMessage,
    this.acceptedDeliveryId,
    this.lockedAfterConflict = false,
  });

  final OrderInvoiceDeliveryStatus status;
  final SendInvoiceSheetContextDto? sheetContext;
  final String? errorMessage;
  final String? acceptedDeliveryId;
  final bool lockedAfterConflict;

  bool get isSubmitting => status == OrderInvoiceDeliveryStatus.submitting;

  bool get operationLocked => lockedAfterConflict || sheetContext?.operationLocked == true;

  OrderInvoiceDeliveryState copyWith({
    OrderInvoiceDeliveryStatus? status,
    SendInvoiceSheetContextDto? sheetContext,
    String? errorMessage,
    String? acceptedDeliveryId,
    bool? lockedAfterConflict,
    bool clearError = false,
    bool clearAcceptedDeliveryId = false,
  }) {
    return OrderInvoiceDeliveryState(
      status: status ?? this.status,
      sheetContext: sheetContext ?? this.sheetContext,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      acceptedDeliveryId: clearAcceptedDeliveryId
          ? null
          : (acceptedDeliveryId ?? this.acceptedDeliveryId),
      lockedAfterConflict: lockedAfterConflict ?? this.lockedAfterConflict,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sheetContext,
    errorMessage,
    acceptedDeliveryId,
    lockedAfterConflict,
  ];
}
