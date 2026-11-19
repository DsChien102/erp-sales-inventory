import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/logic/sales_post_sale_error_messages.dart';
import 'package:erp/features/sales/presentation/models/return_exchange_order/sales_return_exchange_result.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_attempt_factory.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_mapper.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_pricing_copy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/features/sales/data/models.dart';

import 'sales_return_exchange_settlement_state.dart';

class SalesReturnExchangeSettlementCubit extends Cubit<SalesReturnExchangeSettlementState> {
  SalesReturnExchangeSettlementCubit({
    required String orderId,
    required String returnExchangeId,
    required this.returnExchangeRepository,
    required this.orderRepository,
    required this.session,
    SalesReturnExchangeAttemptFactory? attemptFactory,
  }) : _attemptFactory = attemptFactory ?? SalesReturnExchangeAttemptFactory(),
       super(
         SalesReturnExchangeSettlementState(
           orderId: orderId,
           returnExchangeId: returnExchangeId,
         ),
       );

  final ReturnExchangeRepository returnExchangeRepository;
  final SalesOrderRepository orderRepository;
  final SessionController session;
  final SalesReturnExchangeAttemptFactory _attemptFactory;

  String? _tenantId;
  String? _actorId;
  String? _correlationId;
  SalesReturnExchangeAttempt<ReturnExchangeConfirmRequest>? _currentAttempt;
  int _loadGeneration = 0;
  bool _confirmInFlight = false;
  List<String> _sentOffsetTargets = const [];

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
      final tenantId = await session.requireTenantId();
      final actorId = await session.requireUserId();
      final correlationId = session.correlationId;
      if (correlationId.trim().isEmpty) {
        throw const AppException('CONTEXT_INVALID');
      }
      _tenantId = tenantId;
      _actorId = actorId;
      _correlationId = correlationId.trim();

      final detail = await returnExchangeRepository.getDetail(
        returnExchangeId: state.returnExchangeId,
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
        orderDetail = await orderRepository.getDetail(salesOrderId: salesOrderId);
      } on Object catch (_) {
        orderDetail = null;
      }
      if (generation != _loadGeneration || isClosed) return;

      final sourceOrderNumber =
          (orderDetail?.order.orderNumber != null && orderDetail!.order.orderNumber.isNotEmpty)
          ? orderDetail.order.orderNumber
          : (detail.referenceNumber.isNotEmpty ? detail.referenceNumber : state.orderNumber);
      final customerDisplayName = orderDetail?.customer?.displayName ?? '';
      // Unknown when the order detail failed to load; the confirm RPC still
      // rejects walk-in receivables in that case.
      final isWalkIn = orderDetail != null && orderDetail.customer == null;

      final valuation = await returnExchangeRepository.evaluate(
        returnExchangeId: state.returnExchangeId,
        expectedSourceVersion: detail.settlementPlan.sourceOrderVersion,
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
          isWalkIn: isWalkIn,
          draftVersion: detail.result.version,
          settlement: settlement,
          valuation: valuation,
          blockers: const [],
          status: SalesReturnExchangeSettlementStatus.ready,
          clearScreenError: true,
          clearSettledNow: true,
          clearPaymentDueDate: true,
          paymentMethod: SalesPaymentMethod.cash,
          selectedOffsetOrderIds: {
            for (final c in valuation.settlementPlan.offsetCandidates)
              c.salesOrderId,
          },
          receivableChanged: false,
        ),
      );
    } on AppException catch (error) {
      if (generation != _loadGeneration || isClosed) return;
      if (error.code == 'PRICE_CHANGED') {
        emit(
          state.copyWith(
            status: SalesReturnExchangeSettlementStatus.stale,
            screenError: SalesReturnExchangePricingCopy.priceChangedGoBack,
          ),
        );
        return;
      }
      if (error.code == 'RETURN_EXCHANGE_BLOCKED') {
        final blockers = _blockersFrom(error);
        emit(
          state.copyWith(
            status: SalesReturnExchangeSettlementStatus.blocked,
            blockers: blockers,
            screenError: 'Không thể đổi/trả.',
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
    } catch (_) {
      if (generation != _loadGeneration || isClosed) return;
      emit(
        state.copyWith(
          status: SalesReturnExchangeSettlementStatus.failure,
          screenError: 'Không quyết toán được phiếu đổi/trả. Vui lòng thử lại.',
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

  /// Tick / bỏ tick một đơn nhận cấn trừ. Đổi danh sách thì khoá chống trùng
  /// phải mới.
  void toggleOffsetTarget(String salesOrderId) {
    if (isClosed) return;
    final next = {...state.selectedOffsetOrderIds};
    if (!next.remove(salesOrderId)) next.add(salesOrderId);
    _currentAttempt = null;
    emit(state.copyWith(selectedOffsetOrderIds: next));
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
    final targets = state.offsetPreview?.targetOrderIds ?? const <String>[];
    _sentOffsetTargets = targets;
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
            offsetTargetOrderIds: targets,
          );
      _currentAttempt = attempt;
      final result = await returnExchangeRepository.confirm(attempt.request);
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
    } on AppException catch (error) {
      _confirmInFlight = false;
      return _handleConfirmError(error);
    } catch (_) {
      _confirmInFlight = false;
      _currentAttempt = null;
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SalesReturnExchangeSettlementStatus.failure,
            screenError: 'Không quyết toán được phiếu đổi/trả. Vui lòng thử lại.',
          ),
        );
      }
      return null;
    }
  }

  Future<SalesReturnExchangeResult?> _handleConfirmError(
    AppException error,
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
    if (error.code == 'PRICE_CHANGED') {
      _currentAttempt = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeSettlementStatus.stale,
          screenError: SalesReturnExchangePricingCopy.priceChangedGoBack,
        ),
      );
      return null;
    }
    if (_sentOffsetTargets.isNotEmpty &&
        (error.code == 'STALE_VERSION' || error.code == 'OFFSET_TARGET_INVALID')) {
      // Công nợ của khách đổi: không tự tải lại, để người dùng chọn lại.
      _currentAttempt = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeSettlementStatus.stale,
          receivableChanged: true,
          screenError: error.code == 'OFFSET_TARGET_INVALID'
              ? _messageFor(error)
              : 'Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.',
        ),
      );
      return null;
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

  bool _isRetryable(AppException error) =>
      error.code == 'DEPENDENCY_UNAVAILABLE' ||
      error.code == 'NETWORK_ERROR' ||
      error.code == 'SYSTEM_ERROR';

  List<SalesBlockerDto> _blockersFrom(AppException error) {
    final raw = error.details?['blockers'];
    if (raw is! List) return const [];
    final parsed = <SalesBlockerDto>[];
    for (final item in raw) {
      if (item is SalesBlockerDto) {
        parsed.add(item);
      } else if (item is Map) {
        parsed.add(
          SalesBlockerDto(
            code: item['code'] as String? ?? 'UNKNOWN',
            message: item['message'] as String? ?? '',
            field: item['field'] as String?,
          ),
        );
      }
    }
    return localizeBlockers(parsed, fallback: 'Không thể đổi/trả.');
  }

  String _messageFor(Object error) {
    return salesPostSaleErrorMessage(
      error,
      fallback: 'Không quyết toán được phiếu đổi/trả. Vui lòng thử lại.',
    );
  }
}
