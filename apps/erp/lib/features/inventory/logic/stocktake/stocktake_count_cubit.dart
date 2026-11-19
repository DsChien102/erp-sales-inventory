import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/idempotency_key.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

class StocktakeCountCubit extends Cubit<StocktakeCountState> {
  StocktakeCountCubit({
    required StocktakeRepository repository,
    required this.sessionId,
    String Function() newKey = newIdempotencyKey,
    Duration draftDebounce = const Duration(milliseconds: 400),
  }) : _repository = repository,
       _newKey = newKey,
       _draftDebounce = draftDebounce,
       super(const StocktakeCountState());

  final StocktakeRepository _repository;
  final String sessionId;
  final String Function() _newKey;
  final Duration _draftDebounce;

  final Map<String, Timer> _draftTimers = {};
  String? _pendingSubmitKey;
  String? _pendingCancelKey;

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }

  void _cancelTimers() {
    for (final t in _draftTimers.values) {
      t.cancel();
    }
    _draftTimers.clear();
  }

  Future<void> load() async {
    _cancelTimers();
    _pendingSubmitKey = null;
    _pendingCancelKey = null;
    emit(const StocktakeCountState(status: StocktakeCountStatus.loading));
    try {
      final session = await _repository.get(sessionId);
      if (session.status != StocktakeStatus.counting) {
        emit(
          StocktakeCountState(
            status: StocktakeCountStatus.ready,
            session: session,
            navigatedStatus: session.status,
          ),
        );
        return;
      }

      final inputs = <String, String>{
        for (final line in session.lines)
          line.lineId: line.draftQty == null
              ? ''
              : formatQuantity(line.draftQty!.toDouble()),
      };

      emit(
        StocktakeCountState(
          status: StocktakeCountStatus.ready,
          session: session,
          inputs: inputs,
          filter: StocktakeCountFilter.todo,
          visibleLineIds: _computeVisibleIds(
            session.lines,
            inputs,
            StocktakeCountFilter.todo,
            '',
          ),
        ),
      );
    } catch (_) {
      emit(const StocktakeCountState(status: StocktakeCountStatus.loadError));
    }
  }

  void setFilter(StocktakeCountFilter filter) {
    final visibleIds = _computeVisibleIds(
      state.lines,
      state.inputs,
      filter,
      state.query,
    );
    emit(
      state.copyWith(
        filter: filter,
        visibleLineIds: visibleIds,
      ),
    );
  }

  void setQuery(String query) {
    final visibleIds = _computeVisibleIds(
      state.lines,
      state.inputs,
      state.filter,
      query,
    );
    emit(
      state.copyWith(
        query: query,
        visibleLineIds: visibleIds,
      ),
    );
  }

  /// Cập nhật ô nhập của [lineId] và lưu nháp sau 400 ms. Không dựng lại danh sách lọc hiện tại.
  void setCount(String lineId, String rawText) {
    _pendingSubmitKey = null;
    final nextInputs = Map<String, String>.from(state.inputs)
      ..[lineId] = rawText;
    emit(state.copyWith(inputs: nextInputs, clearSubmitError: true));

    _draftTimers[lineId]?.cancel();
    _draftTimers[lineId] = Timer(_draftDebounce, () {
      _persistDraft(lineId, rawText);
    });
  }

  Future<void> _persistDraft(String lineId, String rawText) async {
    final trimmed = rawText.trim();
    final num? qty = trimmed.isEmpty ? null : parseStocktakeCount(rawText);
    if (trimmed.isNotEmpty && qty == null) return;
    try {
      await _repository.saveDraft(
        sessionId: sessionId,
        lineId: lineId,
        quantity: qty,
      );
    } on AppException catch (e) {
      if (e.code == InventoryErrorCode.stocktakeStateChanged && !isClosed) {
        await _handleStateChanged();
      }
    } catch (_) {
      // Lưu nháp thất bại tạm thời không chặn người đang đếm; nút nộp vẫn gửi toàn bộ.
    }
  }

  Future<StocktakeUnexpectedOptions> fetchUnexpectedOptions() =>
      _repository.unexpectedOptions(sessionId);

  Future<StocktakeLine> addUnexpected({
    required String productId,
    String? lotId,
    String? lotCode,
    DateTime? expiryDate,
    String? expiryPrecision,
  }) async {
    try {
      final added = await _repository.addUnexpected(
        sessionId: sessionId,
        productId: productId,
        lotId: lotId,
        lotCode: lotCode,
        expiryDate: expiryDate,
        expiryPrecision: expiryPrecision,
      );
      final session = state.session;
      if (session != null) {
        final nextLines = [...session.lines, added];
        final nextSession = StocktakeSession(
          id: session.id,
          code: session.code,
          scopeKind: session.scopeKind,
          scopeLabel: session.scopeLabel,
          counterName: session.counterName,
          reason: session.reason,
          status: session.status,
          resultKind: session.resultKind,
          openedAt: session.openedAt,
          firstSubmittedAt: session.firstSubmittedAt,
          completedAt: session.completedAt,
          completedByName: session.completedByName,
          cancelledAt: session.cancelledAt,
          cancelReason: session.cancelReason,
          adjustmentValueVnd: session.adjustmentValueVnd,
          stockChanges: session.stockChanges,
          lines: nextLines,
        );
        final nextInputs = Map<String, String>.from(state.inputs)
          ..[added.lineId] = '';
        final nextVisible = _computeVisibleIds(
          nextLines,
          nextInputs,
          state.filter,
          state.query,
        );
        _pendingSubmitKey = null;
        emit(
          state.copyWith(
            session: nextSession,
            inputs: nextInputs,
            visibleLineIds: nextVisible,
            clearSubmitError: true,
          ),
        );
      }
      return added;
    } on AppException catch (e) {
      if (e.code == InventoryErrorCode.stocktakeStateChanged) {
        await _handleStateChanged();
      }
      rethrow;
    }
  }

  void prepareSubmitKey() {
    _pendingSubmitKey ??= _newKey();
    emit(state.copyWith(clearSubmitError: true));
  }

  Future<void> submitFirst() async {
    if (state.uncountedCount > 0 ||
        state.status == StocktakeCountStatus.submitting) {
      return;
    }
    _cancelTimers();
    final key = _pendingSubmitKey ??= _newKey();
    emit(
      state.copyWith(
        status: StocktakeCountStatus.submitting,
        clearSubmitError: true,
      ),
    );
    try {
      final counts = [
        for (final line in state.lines)
          StocktakeCountInput(
            lineId: line.lineId,
            quantity: parseStocktakeCount(state.inputs[line.lineId] ?? '')!,
          ),
      ];
      final res = await _repository.submitFirst(
        idempotencyKey: key,
        sessionId: sessionId,
        counts: counts,
      );
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          navigatedStatus: res.status,
        ),
      );
    } on AppException catch (e) {
      if (e.code == InventoryErrorCode.stocktakeStateChanged) {
        await _handleStateChanged();
        return;
      }
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          submitError: inventoryErrorMessage(e, fallback: e.userMessage()),
        ),
      );
    } catch (e) {
      final appError = AppException.from(e);
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          submitError: inventoryErrorMessage(
            appError,
            fallback: appError.userMessage(),
          ),
        ),
      );
    }
  }

  Future<void> cancel(String reason) async {
    if (reason.trim().isEmpty ||
        state.status == StocktakeCountStatus.submitting) {
      return;
    }
    _cancelTimers();
    final key = _pendingCancelKey ??= _newKey();
    emit(
      state.copyWith(
        status: StocktakeCountStatus.submitting,
        clearSubmitError: true,
      ),
    );
    try {
      final status = await _repository.cancel(
        idempotencyKey: key,
        sessionId: sessionId,
        reason: reason.trim(),
      );
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          navigatedStatus: status,
        ),
      );
    } on AppException catch (e) {
      if (e.code == InventoryErrorCode.stocktakeStateChanged) {
        await _handleStateChanged();
        return;
      }
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          submitError: inventoryErrorMessage(e, fallback: e.userMessage()),
        ),
      );
    } catch (e) {
      final appError = AppException.from(e);
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          submitError: inventoryErrorMessage(
            appError,
            fallback: appError.userMessage(),
          ),
        ),
      );
    }
  }

  Future<void> _handleStateChanged() async {
    try {
      final latest = await _repository.get(sessionId);
      final kind = latest.status == StocktakeStatus.cancelled
          ? StocktakeStateChangeKind.lockLost
          : StocktakeStateChangeKind.conflict;
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          session: latest,
          stateChangeKind: kind,
          stateChangeStatus: latest.status,
        ),
      );
    } catch (e) {
      final appError = AppException.from(e);
      emit(
        state.copyWith(
          status: StocktakeCountStatus.ready,
          submitError: inventoryErrorMessage(
            appError,
            fallback: appError.userMessage(),
          ),
        ),
      );
    }
  }

  List<String> _computeVisibleIds(
    List<StocktakeLine> lines,
    Map<String, String> inputs,
    StocktakeCountFilter filter,
    String query,
  ) {
    final normalized = VTextNormalizer.normalizeForSearch(query.trim());
    return lines
        .where((line) {
          final counted = parseStocktakeCount(inputs[line.lineId] ?? '') != null;
          if (filter == StocktakeCountFilter.todo && counted) return false;
          if (filter == StocktakeCountFilter.done && !counted) return false;
          if (normalized.isEmpty) return true;
          final hay = VTextNormalizer.normalizeForSearch(
            '${line.productName} ${line.productCode} ${line.lotCode ?? ''}',
          );
          return hay.contains(normalized);
        })
        .map((l) => l.lineId)
        .toList(growable: false);
  }
}

