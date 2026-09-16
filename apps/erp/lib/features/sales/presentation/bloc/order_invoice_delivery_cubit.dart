import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../support/order_einvoice_idempotency_key_factory.dart';
import '../support/order_invoice_delivery_error_message.dart';
import 'order_invoice_delivery_state.dart';

/// Owns SG-07 send/resend sheet context load and submit orchestration.
///
/// Projection polling stays on [OrderEInvoiceCubit]; host refreshes after
/// accepted `PROCESSING`.
final class OrderInvoiceDeliveryCubit extends Cubit<OrderInvoiceDeliveryState> {
  OrderInvoiceDeliveryCubit({
    required String salesOrderId,
    required IExecutionContext executionContext,
    required IModuleMediator mediator,
    OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory =
        const OrderEInvoiceIdempotencyKeyFactory(),
  }) : _salesOrderId = salesOrderId,
       _executionContext = executionContext,
       _mediator = mediator,
       _idempotencyKeyFactory = idempotencyKeyFactory,
       super(const OrderInvoiceDeliveryState());

  final String _salesOrderId;
  final IExecutionContext _executionContext;
  final IModuleMediator _mediator;
  final OrderEInvoiceIdempotencyKeyFactory _idempotencyKeyFactory;

  String? _pendingEmailKey;
  String? _pendingIdempotencyKey;

  Future<SendInvoiceSheetContextDto?> loadContext() async {
    emit(
      state.copyWith(
        status: OrderInvoiceDeliveryStatus.loadingContext,
        clearError: true,
        lockedAfterConflict: false,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final context = await _mediator.executeQueryAsync(
        GetSendInvoiceSheetContextQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: _salesOrderId,
        ),
      );
      if (isClosed) return context;
      emit(
        state.copyWith(
          status: OrderInvoiceDeliveryStatus.ready,
          sheetContext: context,
          clearError: true,
        ),
      );
      return context;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderInvoiceDeliveryStatus.failure,
            errorMessage: OrderInvoiceDeliveryErrorMessage.of(error),
          ),
        );
      }
      return null;
    }
  }

  Future<bool> submit(String recipientEmail) async {
    if (state.isSubmitting ||
        state.sheetContext == null ||
        state.status == OrderInvoiceDeliveryStatus.loadingContext ||
        state.operationLocked) {
      return false;
    }

    final trimmed = recipientEmail.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final sheetContext = state.sheetContext;
    emit(
      state.copyWith(
        status: OrderInvoiceDeliveryStatus.submitting,
        sheetContext: sheetContext,
        clearError: true,
      ),
    );

    final idempotencyKey = _idempotencyKeyFor(trimmed);

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final result = await _mediator.executeCommandAsync(
        SendElectronicInvoiceCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: _salesOrderId,
          recipientEmail: trimmed,
          idempotencyKey: idempotencyKey,
        ),
      );

      if (result.status != DeliveryStatus.processing) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: OrderInvoiceDeliveryStatus.failure,
              sheetContext: sheetContext,
              errorMessage: OrderInvoiceDeliveryErrorMessage.fallback,
            ),
          );
        }
        return false;
      }

      _pendingEmailKey = null;
      _pendingIdempotencyKey = null;
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderInvoiceDeliveryStatus.accepted,
            sheetContext: sheetContext,
            acceptedDeliveryId: result.deliveryId,
            clearError: true,
          ),
        );
      }
      return true;
    } catch (error) {
      final locked = error.toString().contains('OPERATION_IN_PROGRESS');
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderInvoiceDeliveryStatus.failure,
            sheetContext: sheetContext,
            errorMessage: OrderInvoiceDeliveryErrorMessage.of(error),
            lockedAfterConflict: locked ? true : state.lockedAfterConflict,
          ),
        );
      }
      return false;
    }
  }

  String _idempotencyKeyFor(String email) {
    final normalized = email.trim().toLowerCase();
    if (_pendingEmailKey != normalized || _pendingIdempotencyKey == null) {
      _pendingEmailKey = normalized;
      _pendingIdempotencyKey = _idempotencyKeyFactory.next();
    }
    return _pendingIdempotencyKey!;
  }
}
