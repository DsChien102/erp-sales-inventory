import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/idempotency_key.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _versionConflictOverride =
    'Chương trình đã được sửa ở nơi khác. Tải lại để xem bản mới.';

class ProgramDetailCubit extends Cubit<ProgramDetailState> {
  final SupplierProgramRepository _repository;
  final String Function() _newKey;

  String? _programId;

  ProgramDetailCubit({
    required SupplierProgramRepository repository,
    String Function() newKey = newIdempotencyKey,
  })  : _repository = repository,
        _newKey = newKey,
        super(const ProgramDetailState());

  Future<void> load(String id) async {
    _programId = id;
    emit(
      state.copyWith(
        status: ProgramDetailStatus.loading,
        clearActionError: true,
        versionConflict: false,
      ),
    );
    try {
      final detail = await _repository.get(id);
      emit(
        state.copyWith(
          status: ProgramDetailStatus.ready,
          data: detail,
          clearActionError: true,
          versionConflict: false,
        ),
      );
    } catch (e) {
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.contextInvalid ||
          appEx.code == AppErrorCode.notFound) {
        emit(state.copyWith(status: ProgramDetailStatus.notFound));
      } else {
        emit(state.copyWith(status: ProgramDetailStatus.loadError));
      }
    }
  }

  Future<void> refresh() async {
    final id = _programId ?? state.data?.row.id;
    if (id == null) return;
    await load(id);
  }

  Future<bool> end() async {
    final current = state.data;
    if (current == null || state.ending || !state.canEnd) return false;

    emit(
      state.copyWith(
        ending: true,
        clearActionError: true,
        versionConflict: false,
      ),
    );

    try {
      await _repository.end(
        idempotencyKey: _newKey(),
        id: current.row.id,
        expectedRevision: current.revision,
      );
    } catch (e) {
      final appEx = AppException.from(e);
      final isConflict = appEx.code == InventoryErrorCode.versionConflict ||
          appEx.code == AppErrorCode.stateChanged;
      final msg = inventoryErrorMessage(
        appEx,
        fallback: appEx.userMessage(),
        overrides: const {
          InventoryErrorCode.versionConflict: _versionConflictOverride,
          AppErrorCode.stateChanged: _versionConflictOverride,
        },
      );
      emit(
        state.copyWith(
          ending: false,
          actionError: msg,
          versionConflict: isConflict,
        ),
      );
      return false;
    }

    try {
      final updated = await _repository.get(current.row.id);
      emit(
        state.copyWith(
          status: ProgramDetailStatus.ready,
          data: updated,
          ending: false,
          clearActionError: true,
          versionConflict: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          ending: false,
          clearActionError: true,
          versionConflict: false,
          endedLocally: true,
        ),
      );
    }
    return true;
  }
}

