import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/logic/sales_post_sale_error_messages.dart';
import 'package:erp/features/sales/presentation/models/shared/sales_sellable_product_vm.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_attempt_factory.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_pricing_copy.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_session_draft.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/features/sales/data/models.dart';

import 'sales_return_exchange_session_state.dart';

class SalesReturnExchangeSessionCubit extends Cubit<SalesReturnExchangeSessionState> {
  SalesReturnExchangeSessionCubit({
    required String orderId,
    required this.returnExchangeRepository,
    required this.orderRepository,
    required this.session,
    SalesReturnExchangeAttemptFactory? attemptFactory,
    ReturnExchangeEntrySource entrySource = ReturnExchangeEntrySource.standard,
  }) : _attemptFactory = attemptFactory ?? SalesReturnExchangeAttemptFactory(),
       super(
         SalesReturnExchangeSessionState(
           orderId: orderId,
           entrySource: entrySource,
         ),
       );

  final ReturnExchangeRepository returnExchangeRepository;
  final SalesOrderRepository orderRepository;
  final SessionController session;
  final SalesReturnExchangeAttemptFactory _attemptFactory;

  String? _tenantId;
  String? _actorId;
  String? _correlationId;
  SalesReturnExchangeAttempt<dynamic>? _currentAttempt;
  int _loadGeneration = 0;
  List<ReturnExchangeLineInput>? _lastSavedLines;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    emit(
      state.copyWith(
        status: SalesReturnExchangeSessionStatus.loading,
        clearScreenError: true,
        clearFieldError: true,
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

      final detailFuture = orderRepository.getDetail(salesOrderId: state.orderId);
      final precheckFuture = returnExchangeRepository.precheck(salesOrderId: state.orderId);
      final returnableFuture = returnExchangeRepository.getReturnableLines(
        salesOrderId: state.orderId,
      );

      await Future.wait<Object?>([
        detailFuture,
        precheckFuture,
        returnableFuture,
      ]);
      if (generation != _loadGeneration || isClosed) return;

      final detail = await detailFuture;
      final precheck = await precheckFuture;
      final returnable = await returnableFuture;

      // Only surface units the customer can still return/exchange: fully
      // returned original lines and exhausted exchange units (returnable
      // quantity 0) drop out of the picker (ADR-9).
      final returnableUnits = returnable.lines
          .where((line) => line.returnableQuantity.quantityMicros > 0)
          .toList(growable: false);

      // Walk-in orders carry no customer snapshot; they can still be
      // returned/exchanged (only receivable creation needs an identified
      // customer, enforced at settlement).
      final customerDisplayName = detail.customer?.displayName ?? 'Khách lẻ';

      final preserved = SalesReturnExchangeSessionDraft.preserveEdits(
        currentReturns: state.returnEdits,
        currentExchanges: state.exchangeEdits,
        returnableLines: returnableUnits,
      );

      final base = state.copyWith(
        orderNumber: detail.order.orderNumber,
        customerDisplayName: customerDisplayName,
        sourceOrderVersion: returnable.sourceVersion,
        returnableLines: returnableUnits,
        returnEdits: preserved.returnEdits,
        exchangeEdits: preserved.exchangeEdits,
        blockers: localizeBlockers(precheck.blockers, fallback: 'Không thể đổi/trả.'),
        fieldError: preserved.fieldError,
        clearScreenError: true,
        clearFieldError: preserved.fieldError == null,
      );

      if (!precheck.allowed) {
        emit(base.copyWith(status: SalesReturnExchangeSessionStatus.blocked));
      } else {
        emit(base.copyWith(status: SalesReturnExchangeSessionStatus.ready));
      }
      try {
        await refreshExchangePrices();
      } on Object {
        // Preview failure keeps the loaded lines. Save and confirm still re-price.
      }
    } on AppException catch (error) {
      if (generation != _loadGeneration || isClosed) return;
      emit(
        state.copyWith(
          status: SalesReturnExchangeSessionStatus.failure,
          screenError: _messageFor(error),
        ),
      );
    }
  }

  void setReturnQuantity(String salesOrderLineId, int quantity) {
    _invalidateAttempt();
    final line = SalesReturnExchangeSessionDraft.returnableLineOf(
      lines: state.returnableLines,
      salesOrderLineId: salesOrderLineId,
    );
    if (line == null) return;
    final maxMicros = line.returnableQuantity.quantityMicros;
    final clamped = quantity.clamp(0, maxMicros);
    final edits = [...state.returnEdits];
    final index = edits.indexWhere((e) => e.salesOrderLineId == salesOrderLineId);
    if (clamped == 0) {
      if (index >= 0) edits.removeAt(index);
    } else if (index >= 0) {
      edits[index] = edits[index].copyWith(quantityMicros: clamped);
    } else {
      edits.add(
        SalesReturnLineEdit(
          salesOrderLineId: salesOrderLineId,
          quantityMicros: clamped,
        ),
      );
    }
    emit(
      state.copyWith(
        returnEdits: edits,
        status: SalesReturnExchangeSessionStatus.ready,
        clearFieldError: true,
        clearScreenError: true,
      ),
    );
  }

  Future<void> addExchangeProduct(SalesProductSelection selection) async {
    _invalidateAttempt();
    final MoneyDto unitPrice;
    try {
      final preview = await returnExchangeRepository.previewPricing(
        salesOrderId: state.orderId,
        lines: [
          ReturnExchangePricingLineInput(
            productId: selection.productId,
            productUnitId: selection.productUnitId,
          ),
        ],
      );
      unitPrice = preview.lines.single.unitPrice;
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(screenError: _messageFor(error)));
      return;
    } catch (_) {
      // Lỗi mạng/khác: không nói "không xác định được giá" để tránh hiểu nhầm.
      if (isClosed) return;
      emit(state.copyWith(screenError: SalesReturnExchangePricingCopy.previewFailed));
      return;
    }
    if (isClosed) return;
    final edits = [...state.exchangeEdits];
    final index = edits.indexWhere(
      (e) => e.productUnitId == selection.productUnitId,
    );
    if (index >= 0) {
      edits[index] = edits[index].copyWith(
        quantityMicros: edits[index].quantityMicros + QuantityDto.scale,
        unitPrice: unitPrice,
      );
    } else {
      edits.add(
        SalesExchangeLineEdit(
          productId: selection.productId,
          productUnitId: selection.productUnitId,
          productName: selection.productName,
          sku: selection.sku,
          unitLabel: selection.unitLabel,
          unitPrice: unitPrice,
          quantityMicros: QuantityDto.scale,
        ),
      );
    }
    emit(
      state.copyWith(
        exchangeEdits: edits,
        status: SalesReturnExchangeSessionStatus.ready,
        clearFieldError: true,
      ),
    );
  }

  Future<void> refreshExchangePrices() async {
    if (state.exchangeEdits.isEmpty) return;
    final preview = await returnExchangeRepository.previewPricing(
      salesOrderId: state.orderId,
      lines: [
        for (final edit in state.exchangeEdits)
          ReturnExchangePricingLineInput(
            productId: edit.productId,
            productUnitId: edit.productUnitId,
          ),
      ],
    );
    if (isClosed) return;
    final byUnit = {for (final line in preview.lines) line.productUnitId: line.unitPrice};
    final refreshed = [
      for (final edit in state.exchangeEdits)
        edit.copyWith(unitPrice: byUnit[edit.productUnitId] ?? edit.unitPrice),
    ];
    final changed = [
      for (var i = 0; i < refreshed.length; i++)
        refreshed[i].unitPrice.amountMinor != state.exchangeEdits[i].unitPrice.amountMinor,
    ].any((c) => c);
    if (!changed) return;
    // Giá đổi → bỏ lượt lưu đang giữ (vd. sau lỗi retryable), để lần lưu sau
    // tạo lệnh mới với giá mới thay vì gửi lại lệnh cũ mang giá cũ.
    _invalidateAttempt();
    emit(state.copyWith(exchangeEdits: refreshed));
  }

  void setExchangeQuantity(String productUnitId, int quantity) {
    _invalidateAttempt();
    final edits = [...state.exchangeEdits];
    final index = edits.indexWhere((e) => e.productUnitId == productUnitId);
    if (index < 0) return;
    if (quantity <= 0) {
      edits.removeAt(index);
    } else {
      edits[index] = edits[index].copyWith(quantityMicros: quantity);
    }
    emit(
      state.copyWith(
        exchangeEdits: edits,
        status: SalesReturnExchangeSessionStatus.ready,
        clearFieldError: true,
      ),
    );
  }

  Future<String?> saveAndGetReturnExchangeId() async {
    if (!state.canProceed) {
      emit(
        state.copyWith(
          fieldError: 'Chọn ít nhất một dòng trả với số lượng hợp lệ.',
        ),
      );
      return null;
    }
    final tenantId = _tenantId;
    final actorId = _actorId;
    final correlationId = _correlationId;
    final sourceVersion = state.sourceOrderVersion;
    if (tenantId == null || actorId == null || correlationId == null || sourceVersion == null) {
      emit(
        state.copyWith(
          status: SalesReturnExchangeSessionStatus.failure,
          screenError: 'Thiếu ngữ cảnh phiên trả/đổi.',
        ),
      );
      return null;
    }

    final lines = SalesReturnExchangeSessionDraft.buildLines(
      returnEdits: state.returnEdits,
      exchangeEdits: state.exchangeEdits,
      returnableLines: state.returnableLines,
    );
    if (_lastSavedLines != null &&
        state.returnExchangeId != null &&
        SalesReturnExchangeSessionDraft.sameLines(_lastSavedLines!, lines)) {
      return state.returnExchangeId;
    }

    emit(
      state.copyWith(
        status: SalesReturnExchangeSessionStatus.saving,
        clearScreenError: true,
        clearFieldError: true,
      ),
    );

    try {
      if (state.returnExchangeId == null) {
        final attempt =
            (_currentAttempt as SalesReturnExchangeAttempt<ReturnExchangeStartRequest>?) ??
            _attemptFactory.start(
              tenantId: tenantId,
              actorId: actorId,
              salesOrderId: state.orderId,
              entrySource: state.entrySource,
              lines: lines,
              expectedVersion: sourceVersion,
              correlationId: correlationId,
            );
        _currentAttempt = attempt;
        final draft = await returnExchangeRepository.start(attempt.request);
        _lastSavedLines = lines;
        _currentAttempt = null;
        emit(
          state.copyWith(
            status: SalesReturnExchangeSessionStatus.ready,
            returnExchangeId: draft.returnExchangeId,
            draftVersion: draft.version,
          ),
        );
        return draft.returnExchangeId;
      }

      final draftVersion = state.draftVersion;
      if (draftVersion == null) {
        throw const AppException('CONTEXT_INVALID');
      }
      final attempt =
          (_currentAttempt as SalesReturnExchangeAttempt<ReturnExchangeUpdateRequest>?) ??
          _attemptFactory.update(
            tenantId: tenantId,
            actorId: actorId,
            returnExchangeId: state.returnExchangeId!,
            lines: lines,
            expectedVersion: draftVersion,
            correlationId: correlationId,
          );
      _currentAttempt = attempt;
      final draft = await returnExchangeRepository.update(attempt.request);
      _lastSavedLines = lines;
      _currentAttempt = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeSessionStatus.ready,
          returnExchangeId: draft.returnExchangeId,
          draftVersion: draft.version,
        ),
      );
      return draft.returnExchangeId;
    } on AppException catch (error) {
      return _handleSaveError(error);
    }
  }

  Future<bool> discard() async {
    final returnExchangeId = state.returnExchangeId;
    if (returnExchangeId == null) {
      emit(state.copyWith(status: SalesReturnExchangeSessionStatus.discarded));
      return true;
    }
    final tenantId = _tenantId;
    final actorId = _actorId;
    final correlationId = _correlationId;
    if (tenantId == null || actorId == null || correlationId == null) {
      emit(
        state.copyWith(
          status: SalesReturnExchangeSessionStatus.failure,
          screenError: 'Thiếu ngữ cảnh phiên trả/đổi.',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        status: SalesReturnExchangeSessionStatus.saving,
        clearScreenError: true,
      ),
    );
    try {
      final attempt =
          (_currentAttempt as SalesReturnExchangeAttempt<ReturnExchangeMutationRequest>?) ??
          _attemptFactory.discard(
            tenantId: tenantId,
            actorId: actorId,
            returnExchangeId: returnExchangeId,
            correlationId: correlationId,
            expectedVersion: state.draftVersion,
          );
      _currentAttempt = attempt;
      await returnExchangeRepository.cancel(attempt.request);
      _currentAttempt = null;
      _lastSavedLines = null;
      emit(
        state.copyWith(
          status: SalesReturnExchangeSessionStatus.discarded,
          clearReturnExchangeId: true,
          clearDraftVersion: true,
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: _isRetryable(error)
              ? SalesReturnExchangeSessionStatus.retryableFailure
              : SalesReturnExchangeSessionStatus.failure,
          screenError: _messageFor(error),
        ),
      );
      return false;
    }
  }

  Future<String?> _handleSaveError(AppException error) async {
    if (error.code == 'STALE_VERSION' ||
        error.code == 'RETURN_QUANTITY_EXCEEDED' ||
        error.code == 'PRICE_CHANGED') {
      _currentAttempt = null;
      // load() tự làm mới giá món đổi ở cuối, không gọi refreshExchangePrices() lần nữa.
      await load();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SalesReturnExchangeSessionStatus.stale,
            screenError: _messageFor(error),
          ),
        );
      }
      return null;
    }
    if (_isRetryable(error)) {
      emit(
        state.copyWith(
          status: SalesReturnExchangeSessionStatus.retryableFailure,
          screenError: _messageFor(error),
        ),
      );
      return null;
    }
    _currentAttempt = null;
    emit(
      state.copyWith(
        status: SalesReturnExchangeSessionStatus.failure,
        screenError: _messageFor(error),
      ),
    );
    return null;
  }

  void _invalidateAttempt() {
    _currentAttempt = null;
    _lastSavedLines = null;
  }

  bool _isRetryable(AppException error) =>
      error.code == 'DEPENDENCY_UNAVAILABLE' ||
      error.code == 'IMPACT_PENDING' ||
      error.code == 'NETWORK_ERROR' ||
      error.code == 'SYSTEM_ERROR';

  String _messageFor(Object error) {
    return salesPostSaleErrorMessage(
      error,
      fallback: 'Không lưu được phiếu đổi/trả. Vui lòng thử lại.',
      overrides: const {
        'PRICE_CHANGED': SalesReturnExchangePricingCopy.priceChanged,
      },
    );
  }
}
