import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../models/return_exchange_order/sales_return_exchange_result.dart';
import '../../support/sales_return_exchange_attempt_factory.dart';
import '../../support/sales_return_exchange_mapper.dart';
import 'sales_return_exchange_settlement_state.dart';

class SalesReturnExchangeSettlementCubit extends Cubit<SalesReturnExchangeSettlementState> {
  SalesReturnExchangeSettlementCubit({
    required String orderId,
    required String returnExchangeId,
    required this.salesModule,
    required this.executionContext,
    SalesReturnExchangeAttemptFactory? attemptFactory,
  }) : _attemptFactory = attemptFactory ?? SalesReturnExchangeAttemptFactory(),
       super(
         SalesReturnExchangeSettlementState(
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
  SalesReturnExchangeAttempt<ConfirmReturnExchangeCommand>? _currentAttempt;
  int _loadGeneration = 0;
  bool _confirmInFlight = false;

  Future<void> loadAndEvaluate() async {
    final generation = ++_loadGeneration;
    emit(
      state.copyWith(
        status: SalesReturnExchangeSettlementStatus.loading,
        clearScreenError: true,
      ),
    );
    _currentAttempt = null;
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

      final detail = await salesModule.executeQueryAsync<ReturnExchangeDetailDto>(
        GetReturnExchangeDetailQuery(
          tenantId: tenantId,
          actorId: actorId,
          returnExchangeId: state.returnExchangeId,
        ),
      );
      if (generation != _loadGeneration || isClosed) return;

      if (detail.result.status == ReturnExchangeStatus.blocked) {
        emit(
          state.copyWith(
            orderNumber: detail.referenceNumber,
            draftVersion: detail.result.version,
            blockers: const [],
            status: SalesReturnExchangeSettlementStatus.blocked,
            clearScreenError: true,
            clearSettlement: true,
          ),
        );
        return;
      }

      final salesOrderId = detail.result.salesOrderId;
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
      if (generation != _loadGeneration || isClosed) return;

      final sourceOrderNumber = (orderDetail?.order.orderNumber != null && orderDetail!.order.orderNumber.isNotEmpty)
          ? orderDetail.order.orderNumber
          : (detail.referenceNumber.isNotEmpty ? detail.referenceNumber : state.orderNumber);
      final customerDisplayName = orderDetail?.customer?.displayName ?? '';

      final valuation = await salesModule.executeQueryAsync<ReturnExchangeValuationDto>(
        EvaluateReturnPricingImpactQuery(
          tenantId: tenantId,
          actorId: actorId,
          returnExchangeId: state.returnExchangeId,
          expectedSourceVersion: detail.settlementPlan.sourceOrderVersion,
        ),
      );
      if (generation != _loadGeneration || isClosed) return;

      final settlement = SalesReturnExchangeMapper.toSettlementVm(
        returnExchangeId: state.returnExchangeId,
        valuation: valuation,
      );

      emit(
        state.copyWith(
          orderNumber: sourceOrderNumber,
          customerDisplayName: customerDisplayName,
          draftVersion: detail.result.version,
          settlement: settlement,
          valuation: valuation,
          blockers: const [],
          status: SalesReturnExchangeSettlementStatus.ready,
          clearScreenError: true,
          clearSettledNow: true,
          clearPaymentDueDate: true,
          paymentMethod: SalesPaymentMethod.manualBankTransfer,
        ),
      );
    } on SalesContractException catch (error) {
      if (generation != _loadGeneration || isClosed) return;
      if (error.code == 'RETURN_EXCHANGE_BLOCKED') {
        final blockers = _blockersFrom(error);
        emit(
          state.copyWith(
            status: SalesReturnExchangeSettlementStatus.blocked,
            blockers: blockers,
            screenError: _messageFor(error),
            clearSettlement: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: _isRetryable(error)
              ? SalesReturnExchangeSettlementStatus.retryableFailure
              : SalesReturnExchangeSettlementStatus.failure,
          screenError: _messageFor(error),
        ),
      );
    } catch (error) {
      if (generation != _loadGeneration || isClosed) return;
      emit(
        state.copyWith(
          status: SalesReturnExchangeSettlementStatus.failure,
          screenError: '$error',
        ),
      );
    }
  }

  /// Records the amount the customer settles right now (phase-1 capture; the
  /// wire-up to the confirm RPC lands with the backend settlement change).
  void updateSettledNow(int settledNowMinor) {
    if (isClosed) return;
    emit(state.copyWith(settledNowMinor: settledNowMinor));
  }

  /// Records the chosen payment due date (or clears it when the shortfall is
  /// gone). Gates confirmation while an outstanding balance has no due date.
  void updatePaymentDueDate(DateTime? dueDate) {
    if (isClosed) return;
    emit(
      state.copyWith(
        paymentDueDate: dueDate,
        clearPaymentDueDate: dueDate == null,
      ),
    );
  }

  /// Records the method for the amount collected now.
  void updatePaymentMethod(SalesPaymentMethod method) {
    if (isClosed) return;
    emit(state.copyWith(paymentMethod: method));
  }

  /// Toggles whether to offset customer debt in a refund flow.
  void updateOffsetDebt(bool value) {
    if (isClosed) return;
    emit(state.copyWith(offsetDebt: value));
  }

  Future<SalesReturnExchangeResult?> confirm() async {
    if (_confirmInFlight) return null;
    if (!state.canConfirm) return null;
    final tenantId = _tenantId;
    final actorId = _actorId;
    final correlationId = _correlationId;
    final draftVersion = state.draftVersion;
    if (tenantId == null || actorId == null || correlationId == null || draftVersion == null) {
      emit(
        state.copyWith(
          status: SalesReturnExchangeSettlementStatus.failure,
          screenError: 'Thiếu ngữ cảnh quyết toán đổi/trả.',
        ),
      );
      return null;
    }

    _confirmInFlight = true;
    emit(
      state.copyWith(
        status: SalesReturnExchangeSettlementStatus.confirming,
        clearScreenError: true,
      ),
    );

    try {
      final attempt =
          _currentAttempt ??
          _attemptFactory.confirm(
            tenantId: tenantId,
            actorId: actorId,
            returnExchangeId: state.returnExchangeId,
            expectedVersion: draftVersion,
            correlationId: correlationId,
            settledNowMinor: state.settledNowMinor,
            paymentMethod: state.paymentMethod,
            paymentDueDate: state.paymentDueDate,
          );
      _currentAttempt = attempt;
      final result = await salesModule.executeCommandAsync<ReturnExchangeResultDto>(
        attempt.command,
      );
      _currentAttempt = null;
      _confirmInFlight = false;

      if (result.status == ReturnExchangeStatus.processing) {
        emit(
          state.copyWith(status: SalesReturnExchangeSettlementStatus.processing),
        );
        return SalesReturnExchangeResult(
          kind: SalesReturnExchangeResultKind.processing,
          returnExchangeId: result.returnExchangeId,
          salesOrderId: result.salesOrderId,
          version: result.version,
          status: result.status,
        );
      }

      emit(state.copyWith(status: SalesReturnExchangeSettlementStatus.success));
      return SalesReturnExchangeResult(
        kind: SalesReturnExchangeResultKind.confirmed,
        returnExchangeId: result.returnExchangeId,
        salesOrderId: result.salesOrderId,
        version: result.version,
        status: result.status,
      );
    } on SalesContractException catch (error) {
      _confirmInFlight = false;
      return _handleConfirmError(error);
    } catch (error) {
      _confirmInFlight = false;
      _currentAttempt = null;
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SalesReturnExchangeSettlementStatus.failure,
            screenError: '$error',
          ),
        );
      }
      return null;
    }
  }

  Future<SalesReturnExchangeResult?> _handleConfirmError(
    SalesContractException error,
  ) async {
    if (error.code == 'IMPACT_PENDING') {
      emit(
        state.copyWith(status: SalesReturnExchangeSettlementStatus.processing),
      );
      return SalesReturnExchangeResult(
        kind: SalesReturnExchangeResultKind.processing,
        returnExchangeId: state.returnExchangeId,
        salesOrderId: state.orderId,
        version: state.draftVersion ?? 0,
        status: ReturnExchangeStatus.processing,
      );
    }
    if (error.code == 'STALE_VERSION') {
      _currentAttempt = null;
      await loadAndEvaluate();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SalesReturnExchangeSettlementStatus.stale,
            screenError: _messageFor(error),
          ),
        );
      }
      return null;
    }
    if (_isRetryable(error)) {
      emit(
        state.copyWith(
          status: SalesReturnExchangeSettlementStatus.retryableFailure,
          screenError: _messageFor(error),
        ),
      );
      return null;
    }
    _currentAttempt = null;
    emit(
      state.copyWith(
        status: SalesReturnExchangeSettlementStatus.failure,
        screenError: _messageFor(error),
      ),
    );
    return null;
  }

  bool _isRetryable(SalesContractException error) => error.code == 'DEPENDENCY_UNAVAILABLE';

  List<SalesBlockerDto> _blockersFrom(SalesContractException error) {
    final raw = error.details['blockers'];
    return (raw as List).whereType<SalesBlockerDto>().toList();
  }

  String _messageFor(SalesContractException error) {
    return error.message?.trim().isNotEmpty == true ? error.message!.trim() : error.code;
  }
}
