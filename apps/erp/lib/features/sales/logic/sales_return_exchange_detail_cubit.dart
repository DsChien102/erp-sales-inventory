import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/logic/sales_post_sale_error_messages.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_attempt_factory.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'sales_return_exchange_detail_state.dart';

class SalesReturnExchangeDetailCubit extends Cubit<SalesReturnExchangeDetailState> {
  SalesReturnExchangeDetailCubit({
    required String orderId,
    required String returnExchangeId,
    required this.returnExchangeRepository,
    required this.orderRepository,
    required this.executionContext,
    SalesReturnExchangeAttemptFactory? attemptFactory,
  }) : _attemptFactory = attemptFactory ?? SalesReturnExchangeAttemptFactory(),
       super(
         SalesReturnExchangeDetailState(
           orderId: orderId,
           returnExchangeId: returnExchangeId,
         ),
       );

  final ReturnExchangeRepository returnExchangeRepository;
  final SalesOrderRepository orderRepository;
  final IExecutionContext executionContext;
  final SalesReturnExchangeAttemptFactory _attemptFactory;

  String? _tenantId;
  String? _actorId;
  String? _correlationId;
  SalesReturnExchangeAttempt<ReturnExchangeMutationRequest>? _currentAttempt;
  int _loadGeneration = 0;
  bool _completeInFlight = false;

  Future<void> load() => _load(showLoading: true);

  Future<void> refresh() => _load(showLoading: false);

  Future<void> _load({required bool showLoading}) async {
    final generation = ++_loadGeneration;
    if (showLoading) {
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.loading,
          clearScreenError: true,
        ),
      );
    }
    try {
      final tenantId = await executionContext.requireTenantId();
      final actorId = await executionContext.requireUserId();
      final correlationId = executionContext.correlationId;
      if (correlationId.trim().isEmpty) {
        throw const AppException('CONTEXT_INVALID');
      }
      _tenantId = tenantId;
      _actorId = actorId;
      _correlationId = correlationId.trim();

      final detailDto = await returnExchangeRepository.getDetail(
        returnExchangeId: state.returnExchangeId,
      );
      if (generation != _loadGeneration || isClosed) return;

      final salesOrderId = detailDto.result.salesOrderId;
      SalesOrderDetailDto? orderDetail;
      try {
        orderDetail = await orderRepository.getDetail(salesOrderId: salesOrderId);
      } on Object catch (_) {
        orderDetail = null;
      }

      SalesOrderReturnSummaryDto? returnSummary;
      try {
        returnSummary = await orderRepository.getReturnSummary(salesOrderId: salesOrderId);
      } on Object catch (_) {
        returnSummary = null;
      }

      if (generation != _loadGeneration || isClosed) return;

      final detailVm = SalesReturnExchangeMapper.toDetailVm(detailDto);
      final status = switch (detailDto.result.status) {
        ReturnExchangeStatus.blocked => SalesReturnExchangeDetailStatus.blocked,
        ReturnExchangeStatus.processing => SalesReturnExchangeDetailStatus.projectionPending,
        _ => SalesReturnExchangeDetailStatus.loaded,
      };

      emit(
        state.copyWith(
          detail: detailVm,
          orderDetail: orderDetail,
          returnSummary: returnSummary,
          status: status,
          clearScreenError: true,
        ),
      );
    } on AppException catch (error) {
      if (generation != _loadGeneration || isClosed) return;
      emit(_mapLoadError(error));
    } catch (_) {
      if (generation != _loadGeneration || isClosed) return;
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.failure,
          screenError: 'Không tải được chi tiết phiếu.',
        ),
      );
    }
  }

  Future<bool> completeIfReady() async {
    if (_completeInFlight) return false;
    final detail = state.detail;
    if (detail == null || !detail.completionReady) {
      return false;
    }
    final tenantId = _tenantId;
    final actorId = _actorId;
    final correlationId = _correlationId;
    if (tenantId == null || actorId == null || correlationId == null) {
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.failure,
          screenError: 'Thiếu ngữ cảnh hoàn tất đổi/trả.',
        ),
      );
      return false;
    }

    _completeInFlight = true;
    emit(
      state.copyWith(
        status: SalesReturnExchangeDetailStatus.completing,
        clearScreenError: true,
      ),
    );

    try {
      final attempt =
          _currentAttempt ??
          _attemptFactory.complete(
            tenantId: tenantId,
            actorId: actorId,
            returnExchangeId: state.returnExchangeId,
            expectedVersion: detail.version,
            correlationId: correlationId,
          );
      _currentAttempt = attempt;
      final result = await returnExchangeRepository.complete(attempt.request);
      _currentAttempt = null;
      _completeInFlight = false;

      if (result.status == ReturnExchangeStatus.processing) {
        emit(
          state.copyWith(
            status: SalesReturnExchangeDetailStatus.projectionPending,
          ),
        );
        return false;
      }

      await refresh();
      return state.detail?.status == ReturnExchangeStatus.completed;
    } on AppException catch (error) {
      _completeInFlight = false;
      if (error.code == 'IMPACT_PENDING') {
        emit(
          state.copyWith(
            status: SalesReturnExchangeDetailStatus.projectionPending,
          ),
        );
        return false;
      }
      if (_isRetryable(error)) {
        emit(
          state.copyWith(
            status: SalesReturnExchangeDetailStatus.retryableFailure,
            screenError: _messageForComplete(error),
          ),
        );
        return false;
      }
      _currentAttempt = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.failure,
          screenError: _messageForComplete(error),
        ),
      );
      return false;
    } catch (_) {
      _completeInFlight = false;
      _currentAttempt = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.failure,
          screenError: 'Không hoàn tất được phiếu. Vui lòng thử lại.',
        ),
      );
      return false;
    }
  }

  SalesReturnExchangeDetailState _mapLoadError(AppException error) {
    if (error.code == 'NOT_FOUND') {
      return state.copyWith(
        status: SalesReturnExchangeDetailStatus.notFound,
        clearScreenError: true,
        clearDetail: true,
      );
    }
    if (error.code == 'PROJECTION_PENDING') {
      return state.copyWith(
        status: SalesReturnExchangeDetailStatus.projectionPending,
        clearScreenError: true,
      );
    }
    final message = salesPostSaleErrorMessage(
      error,
      fallback: 'Không tải được chi tiết phiếu.',
    );
    if (_isRetryable(error)) {
      return state.copyWith(
        status: SalesReturnExchangeDetailStatus.retryableFailure,
        screenError: message,
      );
    }
    return state.copyWith(
      status: SalesReturnExchangeDetailStatus.failure,
      screenError: message,
    );
  }

  bool _isRetryable(AppException error) =>
      error.code == 'DEPENDENCY_UNAVAILABLE' ||
      error.code == 'NETWORK_ERROR' ||
      error.code == 'SYSTEM_ERROR';

  String _messageForComplete(Object error) {
    return salesPostSaleErrorMessage(
      error,
      fallback: 'Không hoàn tất được phiếu. Vui lòng thử lại.',
    );
  }
}
