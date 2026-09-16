import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../models/invoice_delivery_history_vm.dart';
import '../support/order_invoice_delivery_error_message.dart';
import 'invoice_delivery_history_state.dart';

/// Loads authoritative SG07-D01 delivery history for one sales order.
final class InvoiceDeliveryHistoryCubit extends Cubit<InvoiceDeliveryHistoryState> {
  InvoiceDeliveryHistoryCubit({
    required String salesOrderId,
    required IExecutionContext executionContext,
    required IModuleMediator mediator,
  }) : _salesOrderId = salesOrderId,
       _executionContext = executionContext,
       _mediator = mediator,
       super(const InvoiceDeliveryHistoryState());

  final String _salesOrderId;
  final IExecutionContext _executionContext;
  final IModuleMediator _mediator;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: InvoiceDeliveryHistoryStatus.loading,
        clearError: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final dto = await _mediator.executeQueryAsync(
        GetInvoiceDeliveryHistoryQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: _salesOrderId,
        ),
      );
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
            errorMessage: OrderInvoiceDeliveryErrorMessage.of(error),
          ),
        );
      }
    }
  }
}
