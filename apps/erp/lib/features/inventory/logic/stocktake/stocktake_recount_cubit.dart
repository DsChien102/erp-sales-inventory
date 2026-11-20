import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/idempotency_key.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_recount_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StocktakeRecountCubit extends Cubit<StocktakeRecountState> {
  StocktakeRecountCubit({
    required StocktakeRepository repository,
    required this.sessionId,
    String Function() newKey = newIdempotencyKey,
  }) : _repository = repository,
       _newKey = newKey,
       super(const StocktakeRecountState());

  final StocktakeRepository _repository;
  final String sessionId;
  final String Function() _newKey;

  String? _pendingSubmitKey;
  String? _pendingCancelKey;

  Future<void> load() async {
    _pendingSubmitKey = null;
    _pendingCancelKey = null;
    emit(const StocktakeRecountState(status: StocktakeRecountStatus.loading));
    try {
      final session = await _repository.get(sessionId);
      if (session.status != StocktakeStatus.recount) {
        emit(
          StocktakeRecountState(
            status: StocktakeRecountStatus.ready,
            session: session,
            navigatedStatus: session.status,
          ),
        );
        return;
      }

      final varianceLines = session.lines.where((l) => l.needsRecount);
      final inputs = <String, String>{
        for (final line in varianceLines)
          line.lineId: line.recountQty == null
              ? ''
              : formatQuantity(line.recountQty!.toDouble()),
      };
      final reasons = <String, StocktakeLossReason>{
        for (final line in varianceLines)
          if ((line.variance ?? 0) < 0)
            line.lineId: line.lossReason ?? defaultLossReason(line),
      };

      emit(
        StocktakeRecountState(
          status: StocktakeRecountStatus.ready,
          session: session,
          inputs: inputs,
          reasons: reasons,
        ),
      );
    } catch (_) {
      emit(
        const StocktakeRecountState(status: StocktakeRecountStatus.loadError),
      );
    }
  }

  void setCount(String lineId, String rawText) {
    _pendingSubmitKey = null;
    final nextInputs = Map<String, String>.from(state.inputs)
      ..[lineId] = rawText;
    emit(state.copyWith(inputs: nextInputs, clearSubmitError: true));
  }

  void applySameAsFirst(StocktakeLine line) {
    final first = line.firstQty;
    if (first == null) return;
    setCount(line.lineId, formatQuantity(first.toDouble()));
  }

  void setReason(String lineId, StocktakeLossReason reason) {
    _pendingSubmitKey = null;
    final nextReasons = Map<String, StocktakeLossReason>.from(state.reasons)
      ..[lineId] = reason;
    emit(state.copyWith(reasons: nextReasons, clearSubmitError: true));
  }

  void prepareSubmitKey() {
    _pendingSubmitKey ??= _newKey();
    emit(state.copyWith(clearSubmitError: true));
  }

  Future<void> submitRecount() async {
    if (state.missingCount > 0 ||
        state.status == StocktakeRecountStatus.submitting) {
      return;
    }
    final key = _pendingSubmitKey ??= _newKey();
    emit(
      state.copyWith(
        status: StocktakeRecountStatus.submitting,
        clearSubmitError: true,
      ),
    );
    try {
      final counts = [
        for (final line in state.varianceLines)
          StocktakeCountInput(
            lineId: line.lineId,
            quantity: parseStocktakeCount(state.inputs[line.lineId] ?? '')!,
            lossReason: (line.variance ?? 0) < 0
                ? (state.reasons[line.lineId] ?? defaultLossReason(line))
                : null,
          ),
      ];
      final res = await _repository.submitRecount(
        idempotencyKey: key,
        sessionId: sessionId,
        counts: counts,
      );
      emit(
        state.copyWith(
          status: StocktakeRecountStatus.ready,
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
          status: StocktakeRecountStatus.ready,
          submitError: inventoryErrorMessage(e, fallback: e.userMessage()),
        ),
      );
    } catch (e) {
      final appError = AppException.from(e);
      emit(
        state.copyWith(
          status: StocktakeRecountStatus.ready,
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
        state.status == StocktakeRecountStatus.submitting) {
      return;
    }
    final key = _pendingCancelKey ??= _newKey();
    emit(
      state.copyWith(
        status: StocktakeRecountStatus.submitting,
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
          status: StocktakeRecountStatus.ready,
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
          status: StocktakeRecountStatus.ready,
          submitError: inventoryErrorMessage(e, fallback: e.userMessage()),
        ),
      );
    } catch (e) {
      final appError = AppException.from(e);
      emit(
        state.copyWith(
          status: StocktakeRecountStatus.ready,
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
          status: StocktakeRecountStatus.ready,
          session: latest,
          stateChangeKind: kind,
          stateChangeStatus: latest.status,
        ),
      );
    } catch (e) {
      final appError = AppException.from(e);
      emit(
        state.copyWith(
          status: StocktakeRecountStatus.ready,
          submitError: inventoryErrorMessage(
            appError,
            fallback: appError.userMessage(),
          ),
        ),
      );
    }
  }
}
