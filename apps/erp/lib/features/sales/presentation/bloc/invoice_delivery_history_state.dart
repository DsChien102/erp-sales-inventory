import 'package:equatable/equatable.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../models/invoice_delivery_history_vm.dart';

enum InvoiceDeliveryHistoryStatus {
  initial,
  loading,
  loaded,
  failure,
}

final class InvoiceDeliveryHistoryState extends Equatable {
  const InvoiceDeliveryHistoryState({
    this.status = InvoiceDeliveryHistoryStatus.initial,
    this.rows = const [],
    this.displayState = DeliveryDisplayState.notSent,
    this.hasSecondaryAttention = false,
    this.errorMessage,
  });

  final InvoiceDeliveryHistoryStatus status;
  final List<InvoiceDeliveryHistoryRowVm> rows;
  final DeliveryDisplayState displayState;
  final bool hasSecondaryAttention;
  final String? errorMessage;

  bool get isLoading => status == InvoiceDeliveryHistoryStatus.loading;
  bool get isEmpty => status == InvoiceDeliveryHistoryStatus.loaded && rows.isEmpty;

  InvoiceDeliveryHistoryState copyWith({
    InvoiceDeliveryHistoryStatus? status,
    List<InvoiceDeliveryHistoryRowVm>? rows,
    DeliveryDisplayState? displayState,
    bool? hasSecondaryAttention,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InvoiceDeliveryHistoryState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      displayState: displayState ?? this.displayState,
      hasSecondaryAttention: hasSecondaryAttention ?? this.hasSecondaryAttention,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    rows,
    displayState,
    hasSecondaryAttention,
    errorMessage,
  ];
}
