import 'package:erp/core/errors/app_exception.dart';
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
  }) : super(
         SalesReturnExchangeDetailState(
           orderId: orderId,
           returnExchangeId: returnExchangeId,
         ),
       );

  final ReturnExchangeRepository returnExchangeRepository;
  final SalesOrderRepository orderRepository;
  final IExecutionContext executionContext;

  int _loadGeneration = 0;

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
      await executionContext.requireTenantId();
      await executionContext.requireUserId();
      final correlationId = executionContext.correlationId;
      if (correlationId.trim().isEmpty) {
        throw const AppException('CONTEXT_INVALID');
      }

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
}
