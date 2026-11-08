import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';

import 'einvoice_error_messages.dart';
import 'invoice_delivery_history_state.dart';
import 'invoice_delivery_history_vm.dart';

/// Loads authoritative SG07-D01 delivery history for one sales order.
final class InvoiceDeliveryHistoryCubit extends Cubit<InvoiceDeliveryHistoryState> {
  InvoiceDeliveryHistoryCubit({
    required String salesOrderId,
    required EInvoiceRepository repository,
  }) : _salesOrderId = salesOrderId,
       _repository = repository,
       super(const InvoiceDeliveryHistoryState());

  final String _salesOrderId;
  final EInvoiceRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: InvoiceDeliveryHistoryStatus.loading,
        clearError: true,
      ),
    );
    try {
      final dto = await _repository.getDeliveryHistory(_salesOrderId);
      if (isClosed) return;

      final sorted = [...dto.deliveries]
        ..sort((left, right) => right.deliveryNo.compareTo(left.deliveryNo));

      emit(
        state.copyWith(
          status: InvoiceDeliveryHistoryStatus.loaded,
          rows: sorted.map(InvoiceDeliveryHistoryRowVm.fromDto).toList(),
          displayState: dto.displayState,
          hasSecondaryAttention: dto.hasSecondaryAttention,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: InvoiceDeliveryHistoryStatus.failure,
            errorMessage: einvoiceDeliveryErrorMessage(error),
          ),
        );
      }
    }
  }
}
