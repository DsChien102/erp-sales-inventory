import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/models.dart';

import 'einvoice_error_messages.dart';
import 'order_einvoice_idempotency_key_factory.dart';
import 'order_invoice_delivery_state.dart';

/// Owns SG-07 send/resend sheet context load and submit orchestration.
///
/// Projection polling stays on [OrderEInvoiceCubit]; host refreshes after
/// accepted `PROCESSING`.
final class OrderInvoiceDeliveryCubit extends Cubit<OrderInvoiceDeliveryState> {
  OrderInvoiceDeliveryCubit({
    required String salesOrderId,
    required EInvoiceRepository repository,
    OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory =
        const OrderEInvoiceIdempotencyKeyFactory(),
  }) : _salesOrderId = salesOrderId,
       _repository = repository,
       _idempotencyKeyFactory = idempotencyKeyFactory,
       super(const OrderInvoiceDeliveryState());

  final String _salesOrderId;
  final EInvoiceRepository _repository;
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
      final context = await _repository.getSendSheetContext(_salesOrderId);
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
            errorMessage: einvoiceDeliveryErrorMessage(error),
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
      final result = await _repository.send(
        salesOrderId: _salesOrderId,
        recipientEmail: trimmed,
        idempotencyKey: idempotencyKey,
      );

      if (result.status != DeliveryStatus.processing) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: OrderInvoiceDeliveryStatus.failure,
              sheetContext: sheetContext,
              errorMessage: einvoiceDeliveryFallbackMessage,
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
      final locked = error is AppException && error.code == EInvoiceErrorCodes.operationInProgress;
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderInvoiceDeliveryStatus.failure,
            sheetContext: sheetContext,
            errorMessage: einvoiceDeliveryErrorMessage(error),
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
