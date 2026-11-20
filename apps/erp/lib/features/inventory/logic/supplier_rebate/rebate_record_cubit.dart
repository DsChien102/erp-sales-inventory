import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/core/idempotency_key.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_record_state.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_rules.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RebateRecordCubit extends Cubit<RebateRecordState> {
  final SupplierRebateRepository _rebates;
  final SupplierProgramRepository _programs;
  final String _programId;
  final Duration _debounce;
  final String Function() _newKey;
  final DateTime Function() _now;

  Timer? _debounceTimer;
  String? _pendingIdempotencyKey;
  int _previewSeq = 0;

  RebateRecordCubit({
    required SupplierRebateRepository rebates,
    required SupplierProgramRepository programs,
    required String programId,
    Duration debounce = const Duration(milliseconds: 400),
    String Function()? newKey,
    DateTime Function()? now,
  })  : _rebates = rebates,
        _programs = programs,
        _programId = programId,
        _debounce = debounce,
        _newKey = newKey ?? newIdempotencyKey,
        _now = now ?? DateTime.now,
        super(RebateRecordState(documentDate: (now ?? DateTime.now)()));

  DateTime _todayDateOnly() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> load() async {
    _debounceTimer?.cancel();
    _pendingIdempotencyKey = null;
    final today = _todayDateOnly();
    emit(
      RebateRecordState(
        status: RebateRecordStatus.loading,
        documentDate: today,
      ),
    );

    final ProgramDetail detail;
    try {
      detail = await _programs.get(_programId);
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: RebateRecordStatus.loadError));
      return;
    }
    if (isClosed) return;

    if (!detail.viewerIsOwner) {
      emit(
        state.copyWith(
          status: RebateRecordStatus.notOwner,
          program: detail,
        ),
      );
      return;
    }

    if (detail.row.kind != ProgramKind.volumeRebate ||
        detail.row.status != ProgramStatus.reached) {
      emit(
        state.copyWith(
          status: RebateRecordStatus.notReached,
          program: detail,
        ),
      );
      return;
    }

    try {
      final preview = await _rebates.preview(programId: _programId);
      if (isClosed) return;
      final amountText = MoneyFormatter.formatMinorPlain(
        preview.proposedAmountVnd,
      );
      final draft = state.copyWith(
        status: RebateRecordStatus.ready,
        program: detail,
        preview: preview,
        previewLoading: false,
        documentDate: today,
        amountText: amountText,
        showErrors: false,
        confirming: false,
        clearErrorCode: true,
      );
      emit(draft.copyWith(errors: _validate(draft)));
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.programNotReached) {
        emit(
          state.copyWith(
            status: RebateRecordStatus.notReached,
            program: detail,
          ),
        );
      } else if (appEx.code == InventoryErrorCode.permissionDenied) {
        emit(
          state.copyWith(
            status: RebateRecordStatus.notOwner,
            program: detail,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: RebateRecordStatus.loadError,
            program: detail,
          ),
        );
      }
    }
  }

  void setDocumentNo(String value) {
    _pendingIdempotencyKey = null;
    final next = state.copyWith(documentNo: value, clearErrorCode: true);
    emit(next.copyWith(errors: _validate(next)));
  }

  void setDocumentDate(DateTime value) {
    _pendingIdempotencyKey = null;
    final next = state.copyWith(documentDate: value, clearErrorCode: true);
    emit(next.copyWith(errors: _validate(next)));
  }

  void setReason(String value) {
    _pendingIdempotencyKey = null;
    final next = state.copyWith(reason: value, clearErrorCode: true);
    emit(next.copyWith(errors: _validate(next)));
  }

  void setAmountText(String value) {
    _debounceTimer?.cancel();
    _previewSeq++;
    _pendingIdempotencyKey = null;
    final next = state.copyWith(
      amountText: value,
      previewLoading: false,
      clearErrorCode: true,
      clearPreviewErrorCode: true,
    );
    final errors = _validate(next);
    emit(next.copyWith(errors: errors));

    final parsed = parseMoneyInput(value);
    if (errors['amount'] != null || parsed == null) {
      return;
    }

    _debounceTimer = Timer(_debounce, () => _refreshPreview(parsed));
  }

  Future<void> _refreshPreview(int amount) async {
    final seq = ++_previewSeq;
    emit(state.copyWith(previewLoading: true, clearPreviewErrorCode: true));
    try {
      final updated = await _rebates.preview(
        programId: _programId,
        amountVnd: amount,
      );
      if (isClosed || seq != _previewSeq) return;
      final next = state.copyWith(
        preview: updated,
        previewLoading: false,
        clearPreviewErrorCode: true,
      );
      emit(next.copyWith(errors: _validate(next)));
    } catch (e) {
      if (isClosed || seq != _previewSeq) return;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.programNotReached) {
        emit(
          state.copyWith(
            status: RebateRecordStatus.stale,
            previewLoading: false,
            errorCode: appEx.code,
          ),
        );
      } else if (appEx.code == InventoryErrorCode.permissionDenied) {
        emit(
          state.copyWith(
            status: RebateRecordStatus.notOwner,
            previewLoading: false,
            errorCode: appEx.code,
          ),
        );
      } else {
        emit(
          state.copyWith(
            previewLoading: false,
            previewErrorCode: appEx.code,
          ),
        );
      }
    }
  }

  Future<void> submit() async {
    final errors = _validate(state);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          showErrors: true,
          confirming: false,
          clearErrorCode: true,
          errors: errors,
        ),
      );
      return;
    }
    final amount = parseMoneyInput(state.amountText);
    if (amount == null) return;

    final needsFreshPreview = state.previewLoading ||
        state.preview == null ||
        state.preview!.amountVnd != amount;
    if (needsFreshPreview) {
      _debounceTimer?.cancel();
      await _refreshPreview(amount);
      if (isClosed ||
          state.status != RebateRecordStatus.ready ||
          state.previewErrorCode != null ||
          state.preview?.amountVnd != amount) {
        return;
      }
    }

    emit(
      state.copyWith(
        showErrors: true,
        confirming: true,
        clearErrorCode: true,
        errors: _validate(state),
      ),
    );
  }

  void cancelConfirm() {
    emit(state.copyWith(confirming: false));
  }

  Future<void> confirm() async {
    if (state.status == RebateRecordStatus.submitting) return;
    final errors = _validate(state);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          showErrors: true,
          confirming: false,
          errors: errors,
        ),
      );
      return;
    }

    final amount = parseMoneyInput(state.amountText)!;
    final proposed = state.preview?.proposedAmountVnd ?? 0;
    final overrideReason =
        needsOverrideReason(amount, proposed) ? state.reason.trim() : null;

    _pendingIdempotencyKey ??= _newKey();
    final key = _pendingIdempotencyKey!;

    emit(
      state.copyWith(
        status: RebateRecordStatus.submitting,
        confirming: false,
        clearErrorCode: true,
      ),
    );

    try {
      final result = await _rebates.record(
        idempotencyKey: key,
        programId: _programId,
        documentNo: state.documentNo,
        documentDate: state.documentDate,
        amountVnd: amount,
        overrideReason: overrideReason,
      );
      if (isClosed) return;
      _pendingIdempotencyKey = null;
      emit(
        state.copyWith(
          status: RebateRecordStatus.recorded,
          result: result,
          clearErrorCode: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.programNotReached) {
        _pendingIdempotencyKey = null;
        emit(
          state.copyWith(
            status: RebateRecordStatus.stale,
            errorCode: appEx.code,
          ),
        );
      } else if (appEx.code == InventoryErrorCode.permissionDenied) {
        _pendingIdempotencyKey = null;
        emit(
          state.copyWith(
            status: RebateRecordStatus.notOwner,
            errorCode: appEx.code,
          ),
        );
      } else {
        // Giữ nguyên form và _pendingIdempotencyKey để thử lại an toàn.
        emit(
          state.copyWith(
            status: RebateRecordStatus.ready,
            errorCode: appEx.code,
          ),
        );
      }
    }
  }

  Map<String, String> _validate(RebateRecordState s) {
    final out = <String, String>{};
    final docNoErr = documentNoError(s.documentNo);
    if (docNoErr != null) {
      out['documentNo'] = docNoErr;
    }

    final program = s.program;
    if (program != null) {
      final docDateErr = documentDateError(
        s.documentDate,
        program.row.startedOn,
        _todayDateOnly(),
      );
      if (docDateErr != null) {
        out['documentDate'] = docDateErr;
      }
    }

    final base = s.preview?.baseAmountVnd ?? program?.baseAmountVnd ?? 0;
    final parsed = parseMoneyInput(s.amountText);
    final amtErr = rebateAmountError(parsed, base);
    if (amtErr != null) {
      out['amount'] = amtErr;
    }

    final proposed = s.preview?.proposedAmountVnd ?? 0;
    final needReason =
        s.preview != null && needsOverrideReason(parsed, proposed);
    final reasonErr = overrideReasonError(s.reason, required: needReason);
    if (reasonErr != null) {
      out['reason'] = reasonErr;
    }

    return out;
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

