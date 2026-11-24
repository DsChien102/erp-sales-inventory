import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_draft.dart';

enum ProgramFormStatus {
  loading,
  editing,
  saving,
  locked,
  loadError,
}

class ProgramFormState {
  final ProgramFormStatus status;
  final ProgramFormDraft draft;
  final ProgramFormOptions? options;
  final ProgramDetail? editingDetail;
  final Map<String, String> errors;
  final bool showErrors;
  final String? submitError;
  final bool versionConflict;
  final String? savedProgramId;
  final bool isEdit;
  final bool ending;
  final String? endError;
  final bool endedSuccessfully;

  const ProgramFormState({
    this.status = ProgramFormStatus.loading,
    required this.draft,
    this.options,
    this.editingDetail,
    this.errors = const {},
    this.showErrors = false,
    this.submitError,
    this.versionConflict = false,
    this.savedProgramId,
    this.isEdit = false,
    this.ending = false,
    this.endError,
    this.endedSuccessfully = false,
  });

  factory ProgramFormState.initial() => ProgramFormState(
        draft: ProgramFormDraft.initial(),
      );

  SupplierOption? get overlapping {
    if (isEdit) return null;
    final supId = draft.supplierId;
    if (supId == null || options == null) return null;
    for (final s in options!.suppliers) {
      if (s.partnerId == supId && s.activeProgram != null) {
        return s;
      }
    }
    return null;
  }

  ProgramFormState copyWith({
    ProgramFormStatus? status,
    ProgramFormDraft? draft,
    ProgramFormOptions? options,
    ProgramDetail? editingDetail,
    Map<String, String>? errors,
    bool? showErrors,
    String? submitError,
    bool clearSubmitError = false,
    bool? versionConflict,
    String? savedProgramId,
    bool clearSavedProgramId = false,
    bool? isEdit,
    bool? ending,
    String? endError,
    bool clearEndError = false,
    bool? endedSuccessfully,
  }) {
    return ProgramFormState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      options: options ?? this.options,
      editingDetail: editingDetail ?? this.editingDetail,
      errors: errors ?? this.errors,
      showErrors: showErrors ?? this.showErrors,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      versionConflict: versionConflict ?? this.versionConflict,
      savedProgramId:
          clearSavedProgramId ? null : (savedProgramId ?? this.savedProgramId),
      isEdit: isEdit ?? this.isEdit,
      ending: ending ?? this.ending,
      endError: clearEndError ? null : (endError ?? this.endError),
      endedSuccessfully: endedSuccessfully ?? this.endedSuccessfully,
    );
  }
}

