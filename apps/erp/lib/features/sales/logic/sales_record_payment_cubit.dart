import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/logic/sales_record_payment_state.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:erp/features/sales/presentation/support/sales_record_payment_attempt_factory.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class SalesRecordPaymentCubit extends Cubit<SalesRecordPaymentState> {
  SalesRecordPaymentCubit({
    required SalesPaymentRepository repository,
    required IExecutionContext executionContext,
    required ISalesActiveStoreContext activeStoreContext,
    required this.salesOrderId,
    required this.outstandingMinor,
    SalesRecordPaymentAttemptFactory? attemptFactory,
  }) : _repository = repository,
       _executionContext = executionContext,
       _activeStoreContext = activeStoreContext,
       _attemptFactory = attemptFactory ?? SalesRecordPaymentAttemptFactory(),
       super(
         SalesRecordPaymentState(
           amountMinor: outstandingMinor,
           method: SalesPaymentMethod.cash,
         ),
       );

  final SalesPaymentRepository _repository;
  final IExecutionContext _executionContext;
  final ISalesActiveStoreContext _activeStoreContext;
  final String salesOrderId;
  final int outstandingMinor;
  final SalesRecordPaymentAttemptFactory _attemptFactory;

  SalesRecordPaymentAttempt? _attempt;

  void setAmountMinor(int? value) {
    final wasFailure = state.status == SalesRecordPaymentStatus.failure;
    emit(
      state.copyWith(
        status: wasFailure ? SalesRecordPaymentStatus.editing : state.status,
        canRetry: wasFailure ? false : state.canRetry,
        amountMinor: () => value,
        fieldError: () => null,
        errorMessage: () => null,
      ),
    );
  }

  void setMethod(SalesPaymentMethod method) {
    final wasFailure = state.status == SalesRecordPaymentStatus.failure;
    emit(
      state.copyWith(
        status: wasFailure ? SalesRecordPaymentStatus.editing : state.status,
        canRetry: wasFailure ? false : state.canRetry,
        method: method,
        fieldError: () => null,
        errorMessage: () => null,
      ),
    );
  }

  void setExternalReference(String value) {
    final wasFailure = state.status == SalesRecordPaymentStatus.failure;
    emit(
      state.copyWith(
        status: wasFailure ? SalesRecordPaymentStatus.editing : state.status,
        canRetry: wasFailure ? false : state.canRetry,
        externalReference: value,
        errorMessage: () => null,
      ),
    );
  }

  Future<void> submit() async {
    if (state.status == SalesRecordPaymentStatus.submitting) return;

    final amount = state.amountMinor;
    if (amount == null || amount <= 0) {
      emit(
        state.copyWith(
          fieldError: () => 'Số tiền phải lớn hơn 0.',
          errorMessage: () => null,
        ),
      );
      return;
    }

    if (amount > outstandingMinor) {
      emit(
        state.copyWith(
          fieldError: () => 'Số tiền vượt quá số còn phải thu.',
          errorMessage: () => null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SalesRecordPaymentStatus.submitting,
        fieldError: () => null,
        errorMessage: () => null,
        canRetry: false,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final storeId = await _activeStoreContext.requireActiveStoreId();

      final candidate = _attemptFactory.create(
        tenantId: tenantId,
        actorId: actorId,
        storeId: storeId,
        salesOrderId: salesOrderId,
        amountMinor: amount,
        method: state.method,
        externalReference:
            state.method == SalesPaymentMethod.cash ? null : state.externalReference,
        correlationId: _executionContext.correlationId,
      );

      final activeAttempt =
          (_attempt != null && _attempt!.payloadHash == candidate.payloadHash)
              ? _attempt!
              : candidate;
      _attempt = activeAttempt;

      final result = await _repository.recordPayment(activeAttempt.request);
      _attempt = null;

      emit(
        state.copyWith(
          status: SalesRecordPaymentStatus.succeeded,
          result: () => result,
        ),
      );
    } catch (e) {
      final appError = e is AppException ? e : AppException.from(e);
      final (message, canRetry) = _mapError(appError.code);
      if (!canRetry) {
        _attempt = null;
      }
      emit(
        state.copyWith(
          status: SalesRecordPaymentStatus.failure,
          errorMessage: () => message,
          canRetry: canRetry,
        ),
      );
    }
  }

  static (String, bool) _mapError(String code) {
    return switch (code) {
      'OVERPAYMENT_NOT_ALLOWED' => ('Số tiền vượt quá số còn phải thu.', false),
      'ORDER_CANCELLED' => ('Đơn đã hủy, không thể thu thêm.', false),
      'IDEMPOTENCY_CONFLICT' => ('Yêu cầu bị xung đột', true),
      'NO_PERMISSION' => ('Bạn không có quyền thực hiện thao tác này.', false),
      'DATA_SCOPE_DENIED' => ('Cửa hàng hiện tại không còn khả dụng.', false),
      'REFERENCE_UNAVAILABLE' => ('Đơn hàng không tồn tại hoặc đã bị xóa.', false),
      'CONTEXT_INVALID' => ('Dữ liệu không hợp lệ.', false),
      'NETWORK_ERROR' || 'SYSTEM_ERROR' || _ => (
        'Không thể ghi nhận thanh toán. Vui lòng thử lại.',
        true,
      ),
    };
  }
}
