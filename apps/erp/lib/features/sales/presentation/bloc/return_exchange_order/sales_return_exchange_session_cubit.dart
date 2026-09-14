import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../models/shared/sales_sellable_product_vm.dart';
import '../../support/sales_return_exchange_attempt_factory.dart';
import '../../support/sales_return_exchange_session_draft.dart';
import 'sales_return_exchange_session_state.dart';

class SalesReturnExchangeSessionCubit extends Cubit<SalesReturnExchangeSessionState> {
  SalesReturnExchangeSessionCubit({
    required String orderId,
    required this.salesModule,
    required this.executionContext,
    SalesReturnExchangeAttemptFactory? attemptFactory,
    ReturnExchangeEntrySource entrySource = ReturnExchangeEntrySource.standard,
  }) : _attemptFactory = attemptFactory ?? SalesReturnExchangeAttemptFactory(),
       super(
         SalesReturnExchangeSessionState(
           orderId: orderId,
           entrySource: entrySource,
         ),
       );

  final ISalesModule salesModule;
  final IExecutionContext executionContext;
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

      final detailFuture = salesModule.executeQueryAsync<SalesOrderDetailDto>(
        GetSalesOrderDetailQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.orderId,
        ),
      );
      final precheckFuture = salesModule.executeQueryAsync<ReturnExchangePrecheckDto>(
        PrecheckReturnExchangeQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.orderId,
        ),
      );
      final returnableFuture = salesModule.executeQueryAsync<ReturnableOrderLinesDto>(
        GetReturnableOrderLinesQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.orderId,
        ),
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

      final customer = detail.customer;
      if (customer == null) {
        throw const SalesContractException(
          'DEPENDENCY_UNAVAILABLE',
          message: 'Sales order customer snapshot is required.',
        );
      }

      final preserved = SalesReturnExchangeSessionDraft.preserveEdits(
        currentReturns: state.returnEdits,
        currentExchanges: state.exchangeEdits,
        returnableLines: returnableUnits,
        reasons: const [],
        conditions: const [],
      );

      final base = state.copyWith(
        orderNumber: detail.order.orderNumber,
        customerDisplayName: customer.displayName,
        sourceOrderVersion: returnable.sourceVersion,
        returnableLines: returnableUnits,
        reasons: const [],
        conditions: const [],
        returnEdits: preserved.returnEdits,
        exchangeEdits: preserved.exchangeEdits,
        blockers: precheck.blockers,
        fieldError: preserved.fieldError,
        clearScreenError: true,
        clearFieldError: preserved.fieldError == null,
      );

      if (!precheck.allowed) {
        emit(base.copyWith(status: SalesReturnExchangeSessionStatus.blocked));
        return;
      }
      emit(base.copyWith(status: SalesReturnExchangeSessionStatus.ready));
    } on SalesContractException catch (error) {
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

  void setReturnReason(String salesOrderLineId, String reasonCode) {
    _invalidateAttempt();
    final normalized = reasonCode.trim().toUpperCase();
    if (!SalesReturnExchangeSessionDraft.hasPolicyCode(state.reasons, normalized)) {
      return;
    }
    final edits = SalesReturnExchangeSessionDraft.upsertReturnEdit(
      current: state.returnEdits,
      salesOrderLineId: salesOrderLineId,
      update: (edit) => edit.copyWith(reasonCode: normalized),
    );
    emit(
      state.copyWith(
        returnEdits: edits,
        status: SalesReturnExchangeSessionStatus.ready,
        clearFieldError: true,
      ),
    );
  }

  void setReturnCondition(String salesOrderLineId, String conditionCode) {
    _invalidateAttempt();
    final normalized = conditionCode.trim().toUpperCase();
    if (!SalesReturnExchangeSessionDraft.hasPolicyCode(
      state.conditions,
      normalized,
    )) {
      return;
    }
    final edits = SalesReturnExchangeSessionDraft.upsertReturnEdit(
      current: state.returnEdits,
      salesOrderLineId: salesOrderLineId,
      update: (edit) => edit.copyWith(conditionCode: normalized),
    );
    emit(
      state.copyWith(
        returnEdits: edits,
        status: SalesReturnExchangeSessionStatus.ready,
        clearFieldError: true,
      ),
    );
  }

  void addExchangeProduct(SalesProductSelection selection) {
    _invalidateAttempt();
    final edits = [...state.exchangeEdits];
    final index = edits.indexWhere(
      (e) => e.productUnitId == selection.productUnitId,
    );
    if (index >= 0) {
      edits[index] = edits[index].copyWith(
        quantityMicros: edits[index].quantityMicros + QuantityDto.scale,
      );
    } else {
      edits.add(
        SalesExchangeLineEdit(
          productId: selection.productId,
          productUnitId: selection.productUnitId,
          productName: selection.productName,
          sku: selection.sku,
          unitLabel: selection.unitLabel,
          unitPrice: selection.unitPrice,
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
            (_currentAttempt as SalesReturnExchangeAttempt<StartReturnExchangeCommand>?) ??
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
        final draft = await salesModule.executeCommandAsync<ReturnExchangeDraftDto>(
          attempt.command,
        );
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
        throw const SalesContractException(
          'CONTEXT_INVALID',
          message: 'Draft version is required for update.',
        );
      }
      final attempt =
          (_currentAttempt as SalesReturnExchangeAttempt<UpdateReturnExchangeCommand>?) ??
          _attemptFactory.update(
            tenantId: tenantId,
            actorId: actorId,
            returnExchangeId: state.returnExchangeId!,
            lines: lines,
            expectedVersion: draftVersion,
            correlationId: correlationId,
          );
      _currentAttempt = attempt;
      final draft = await salesModule.executeCommandAsync<ReturnExchangeDraftDto>(
        attempt.command,
      );
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
    } on SalesContractException catch (error) {
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
          (_currentAttempt as SalesReturnExchangeAttempt<CancelReturnExchangeCommand>?) ??
          _attemptFactory.discard(
            tenantId: tenantId,
            actorId: actorId,
            returnExchangeId: returnExchangeId,
            correlationId: correlationId,
            expectedVersion: state.draftVersion,
          );
      _currentAttempt = attempt;
      await salesModule.executeCommandAsync<ReturnExchangeResultDto>(attempt.command);
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
    } on SalesContractException catch (error) {
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

  Future<String?> _handleSaveError(SalesContractException error) async {
    if (error.code == 'STALE_VERSION' || error.code == 'RETURN_QUANTITY_EXCEEDED') {
      _currentAttempt = null;
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

  bool _isRetryable(SalesContractException error) =>
      error.code == 'DEPENDENCY_UNAVAILABLE' || error.code == 'IMPACT_PENDING';

  String _messageFor(SalesContractException error) {
    final rpcMessage = error.details['rpcMessage'];
    if (error.code == 'DEPENDENCY_UNAVAILABLE' &&
        rpcMessage is String &&
        rpcMessage.trim().isNotEmpty) {
      return rpcMessage.trim();
    }
    return error.message?.trim().isNotEmpty == true ? error.message!.trim() : error.code;
  }
}
