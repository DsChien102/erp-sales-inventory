import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../support/sales_return_exchange_attempt_factory.dart';
import '../../support/sales_return_exchange_mapper.dart';
import 'sales_return_exchange_detail_state.dart';

class SalesReturnExchangeDetailCubit extends Cubit<SalesReturnExchangeDetailState> {
  SalesReturnExchangeDetailCubit({
    required String orderId,
    required String returnExchangeId,
    required this.salesModule,
    required this.executionContext,
    SalesReturnExchangeAttemptFactory? attemptFactory,
  }) : _attemptFactory = attemptFactory ?? SalesReturnExchangeAttemptFactory(),
       super(
         SalesReturnExchangeDetailState(
           orderId: orderId,
           returnExchangeId: returnExchangeId,
         ),
       );

  final ISalesModule salesModule;
  final IExecutionContext executionContext;
  final SalesReturnExchangeAttemptFactory _attemptFactory;

  String? _tenantId;
  String? _actorId;
  String? _correlationId;
  SalesReturnExchangeAttempt<CompleteReturnExchangeCommand>? _currentAttempt;
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
        throw const SalesContractException(
          'CONTEXT_INVALID',
          message: 'Correlation id is required.',
        );
      }
      _tenantId = tenantId;
      _actorId = actorId;
      _correlationId = correlationId.trim();

      final detailDto = await salesModule.executeQueryAsync<ReturnExchangeDetailDto>(
        GetReturnExchangeDetailQuery(
          tenantId: tenantId,
          actorId: actorId,
          returnExchangeId: state.returnExchangeId,
        ),
      );
      if (generation != _loadGeneration || isClosed) return;

      final salesOrderId = detailDto.result.salesOrderId;
      SalesOrderDetailDto? orderDetail;
      try {
        orderDetail = await salesModule.executeQueryAsync<SalesOrderDetailDto>(
          GetSalesOrderDetailQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: salesOrderId,
          ),
        );
      } on Object catch (_) {
        orderDetail = null;
      }

      SalesOrderReturnSummaryDto? returnSummary;
      try {
        returnSummary = await salesModule.executeQueryAsync<SalesOrderReturnSummaryDto>(
          GetSalesOrderReturnSummaryQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: salesOrderId,
          ),
        );
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
    } on SalesContractException catch (error) {
      if (generation != _loadGeneration || isClosed) return;
      emit(_mapLoadError(error));
    } catch (error) {
      if (generation != _loadGeneration || isClosed) return;
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.failure,
          screenError: '$error',
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
      final result = await salesModule.executeCommandAsync<ReturnExchangeResultDto>(
        attempt.command,
      );
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
    } on SalesContractException catch (error) {
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
            screenError: _messageFor(error),
          ),
        );
        return false;
      }
      _currentAttempt = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.failure,
          screenError: _messageFor(error),
        ),
      );
      return false;
    } catch (error) {
      _completeInFlight = false;
      _currentAttempt = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeDetailStatus.failure,
          screenError: '$error',
        ),
      );
      return false;
    }
  }

  SalesReturnExchangeDetailState _mapLoadError(SalesContractException error) {
    if (error.code == 'NOT_FOUND') {
      return state.copyWith(
        status: SalesReturnExchangeDetailStatus.notFound,
        screenError: _messageFor(error),
        clearDetail: true,
      );
    }
    if (error.code == 'PROJECTION_PENDING') {
      return state.copyWith(
        status: SalesReturnExchangeDetailStatus.projectionPending,
        screenError: _messageFor(error),
      );
    }
    if (error.code == 'PERMISSION_DENIED') {
      return state.copyWith(
        status: SalesReturnExchangeDetailStatus.failure,
        screenError: _messageFor(error),
      );
    }
    if (_isRetryable(error)) {
      return state.copyWith(
        status: SalesReturnExchangeDetailStatus.retryableFailure,
        screenError: _messageFor(error),
      );
    }
    return state.copyWith(
      status: SalesReturnExchangeDetailStatus.failure,
      screenError: _messageFor(error),
    );
  }

  bool _isRetryable(SalesContractException error) => error.code == 'DEPENDENCY_UNAVAILABLE';

  String _messageFor(SalesContractException error) {
    return error.message?.trim().isNotEmpty == true ? error.message!.trim() : error.code;
  }
}
