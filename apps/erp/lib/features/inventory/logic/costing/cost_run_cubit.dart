import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class CostRunCubit extends Cubit<CostRunState> {
  CostRunCubit(this._repo) : super(const CostRunState());

  final CostingRepository _repo;
  static const _uuid = Uuid();
  String? _pendingPublishKey;

  void startDraft(CostRunKind kind, DateTime period) {
    _pendingPublishKey = null;
    emit(
      CostRunState(
        phase: CostRunPhase.draft,
        kind: kind,
        period: period,
      ),
    );
  }

  Future<void> load(String runId) async {
    _pendingPublishKey = null;
    emit(state.copyWith(phase: CostRunPhase.calculating, clearMessage: true));
    try {
      final run = await _repo.getRun(runId);
      if (isClosed) return;
      emit(
        CostRunState(
          phase: CostRunPhase.loaded,
          kind: run.kind,
          period: run.periodMonth,
          run: run,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.permissionDenied) {
        emit(state.copyWith(phase: CostRunPhase.denied));
        return;
      }
      emit(
        state.copyWith(
          phase: CostRunPhase.error,
          message: inventoryErrorMessage(
            appEx,
            fallback: 'Không tải được lần tính giá vốn.',
          ),
        ),
      );
    }
  }

  Future<void> calculate() async {
    if (state.phase == CostRunPhase.calculating) return;
    _pendingPublishKey = null;
    emit(state.copyWith(phase: CostRunPhase.calculating, clearMessage: true));
    try {
      final run = await _repo.createRun(
        idempotencyKey: _uuid.v4(),
        kind: state.kind,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: CostRunPhase.loaded,
          kind: run.kind,
          period: run.periodMonth,
          run: run,
          clearMessage: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.permissionDenied) {
        emit(state.copyWith(phase: CostRunPhase.denied));
        return;
      }
      emit(
        state.copyWith(
          phase: state.run != null ? CostRunPhase.loaded : CostRunPhase.error,
          message: inventoryErrorMessage(
            appEx,
            fallback: 'Không tính được giá vốn.',
          ),
        ),
      );
    }
  }

  Future<bool> publish() async {
    final current = state.run;
    if (current == null || state.phase == CostRunPhase.publishing) return false;
    _pendingPublishKey ??= _uuid.v4();
    final key = _pendingPublishKey!;

    emit(state.copyWith(phase: CostRunPhase.publishing, clearMessage: true));
    try {
      final updated = await _repo.publish(
        idempotencyKey: key,
        runId: current.runId,
      );
      if (isClosed) return false;
      _pendingPublishKey = null;
      emit(
        state.copyWith(
          phase: CostRunPhase.published,
          run: updated,
          clearMessage: true,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.permissionDenied) {
        _pendingPublishKey = null;
        emit(state.copyWith(phase: CostRunPhase.denied));
        return false;
      }
      if (appEx.code == InventoryErrorCode.costRunStale) {
        _pendingPublishKey = null;
        emit(
          state.copyWith(
            phase: CostRunPhase.loaded,
            run: current.copyWith(status: CostRunStatus.stale),
            message: inventoryErrorMessage(
              appEx,
              fallback: 'Dữ liệu đầu vào đã thay đổi. Hãy tạo lần tính kế tiếp.',
            ),
          ),
        );
        return false;
      }
      emit(
        state.copyWith(
          phase: CostRunPhase.loaded,
          message: inventoryErrorMessage(
            appEx,
            fallback: 'Không công bố được giá vốn.',
          ),
        ),
      );
      return false;
    }
  }

  Future<void> discard() async {
    final current = state.run;
    if (current == null) return;
    try {
      await _repo.discard(
        idempotencyKey: _uuid.v4(),
        runId: current.runId,
      );
      if (isClosed) return;
      _pendingPublishKey = null;
      emit(state.copyWith(phase: CostRunPhase.discarded, clearMessage: true));
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.permissionDenied) {
        emit(state.copyWith(phase: CostRunPhase.denied));
        return;
      }
      emit(
        state.copyWith(
          message: inventoryErrorMessage(
            appEx,
            fallback: 'Không bỏ được lần tính.',
          ),
        ),
      );
    }
  }
}

