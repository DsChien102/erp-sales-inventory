import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/idempotency_key.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_draft.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_state.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _versionConflictOverride =
    'Chương trình đã được sửa ở nơi khác. Tải lại để xem bản mới.';

class ProgramFormCubit extends Cubit<ProgramFormState> {
  final SupplierProgramRepository _repository;
  final String Function() _newKey;

  String? _editingProgramId;
  String? _initialProductId;
  int _expectedRevision = 1;
  String? _lastPayloadHash;
  String? _lastIdempotencyKey;

  ProgramFormCubit({
    required SupplierProgramRepository repository,
    String Function() newKey = newIdempotencyKey,
  })  : _repository = repository,
        _newKey = newKey,
        super(ProgramFormState.initial());

  Future<void> startCreate({String? supplierId, String? productId}) async {
    _editingProgramId = null;
    _initialProductId = productId;
    _lastPayloadHash = null;
    _lastIdempotencyKey = null;
    final initialDraft = ProgramFormDraft.initial(supplierId: supplierId);
    emit(
      ProgramFormState(
        status: ProgramFormStatus.loading,
        draft: initialDraft,
        isEdit: false,
      ),
    );
    try {
      final opts = await _repository.formOptions();
      final draft = productId != null &&
              opts.products.any((p) => p.productId == productId)
          ? initialDraft.copyWith(productIds: [productId])
          : initialDraft;
      final errs = validateProgramForm(draft, opts.products);
      emit(
        state.copyWith(
          status: ProgramFormStatus.editing,
          draft: draft,
          options: opts,
          errors: errs,
          showErrors: false,
          clearSubmitError: true,
          versionConflict: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProgramFormStatus.loadError));
    }
  }

  Future<void> startEdit(String programId) async {
    _editingProgramId = programId;
    _initialProductId = null;
    _lastPayloadHash = null;
    _lastIdempotencyKey = null;
    emit(
      state.copyWith(
        status: ProgramFormStatus.loading,
        isEdit: true,
        clearSubmitError: true,
        versionConflict: false,
      ),
    );
    try {
      final results = await Future.wait([
        _repository.get(programId),
        _repository.formOptions(),
      ]);
      final detail = results[0] as ProgramDetail;
      final opts = results[1] as ProgramFormOptions;
      _expectedRevision = detail.revision;
      final draft = ProgramFormDraft.fromDetail(detail);
      final isLocked = detail.isLocked ||
          detail.row.status == ProgramStatus.ended ||
          detail.row.status == ProgramStatus.recorded;
      final errs = validateProgramForm(draft, opts.products);

      emit(
        state.copyWith(
          status:
              isLocked ? ProgramFormStatus.locked : ProgramFormStatus.editing,
          draft: draft,
          options: opts,
          editingDetail: detail,
          errors: errs,
          showErrors: false,
          clearSubmitError: true,
          versionConflict: false,
          isEdit: true,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProgramFormStatus.loadError));
    }
  }

  Future<void> reload() async {
    if (_editingProgramId != null) {
      await startEdit(_editingProgramId!);
    } else {
      await startCreate(
        supplierId: state.draft.supplierId,
        productId: _initialProductId,
      );
    }
  }

  Future<void> load() => reload();

  void update(ProgramFormDraft Function(ProgramFormDraft) change) {
    final nextDraft = change(state.draft);
    final products = state.options?.products ?? const [];
    final errs = validateProgramForm(nextDraft, products);
    emit(
      state.copyWith(
        draft: nextDraft,
        errors: errs,
        clearSubmitError: true,
      ),
    );
  }

  Future<void> submit() async {
    if (state.status == ProgramFormStatus.saving ||
        state.status == ProgramFormStatus.locked) {
      return;
    }
    if (state.overlapping != null) {
      return;
    }

    final products = state.options?.products ?? const [];
    final errs = validateProgramForm(state.draft, products);
    if (errs.isNotEmpty) {
      emit(
        state.copyWith(
          errors: errs,
          showErrors: true,
        ),
      );
      return;
    }

    final payload = state.draft.toPayload(forUpdate: state.isEdit);
    final payloadHash =
        '${state.isEdit}:${_editingProgramId ?? ''}:$_expectedRevision:${jsonEncode(payload.toJson())}';
    if (_lastPayloadHash != payloadHash || _lastIdempotencyKey == null) {
      _lastPayloadHash = payloadHash;
      _lastIdempotencyKey = _newKey();
    }

    emit(
      state.copyWith(
        status: ProgramFormStatus.saving,
        errors: errs,
        clearSubmitError: true,
        versionConflict: false,
      ),
    );

    try {
      if (state.isEdit && _editingProgramId != null) {
        final res = await _repository.update(
          idempotencyKey: _lastIdempotencyKey!,
          id: _editingProgramId!,
          expectedRevision: _expectedRevision,
          payload: payload,
        );
        _expectedRevision = res.revision;
        emit(
          state.copyWith(
            status: ProgramFormStatus.editing,
            savedProgramId: res.id,
          ),
        );
      } else {
        final res = await _repository.create(
          idempotencyKey: _lastIdempotencyKey!,
          payload: payload,
        );
        emit(
          state.copyWith(
            status: ProgramFormStatus.editing,
            savedProgramId: res.id,
          ),
        );
      }
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
          status: ProgramFormStatus.editing,
          submitError: msg,
          versionConflict: isConflict,
        ),
      );
    }
  }

  Future<bool> end() async {
    final detail = state.editingDetail;
    if (detail == null || state.ending) return false;

    emit(
      state.copyWith(
        ending: true,
        clearEndError: true,
        versionConflict: false,
      ),
    );

    try {
      await _repository.end(
        idempotencyKey: _newKey(),
        id: detail.row.id,
        expectedRevision: detail.revision,
      );
      emit(
        state.copyWith(
          ending: false,
          endedSuccessfully: true,
          clearEndError: true,
          versionConflict: false,
        ),
      );
      return true;
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
          endError: msg,
          versionConflict: isConflict,
        ),
      );
      return false;
    }
  }
}

