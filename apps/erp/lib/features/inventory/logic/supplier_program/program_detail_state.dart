import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';

enum ProgramDetailStatus {
  loading,
  ready,
  notFound,
  loadError,
}

class ProgramDetailState {
  final ProgramDetailStatus status;
  final ProgramDetail? data;
  final bool ending;
  final String? actionError;
  final bool versionConflict;
  final bool endedLocally;

  const ProgramDetailState({
    this.status = ProgramDetailStatus.loading,
    this.data,
    this.ending = false,
    this.actionError,
    this.versionConflict = false,
    this.endedLocally = false,
  });

  bool get canEnd {
    if (endedLocally) return false;
    final s = data?.row.status;
    return s == ProgramStatus.active || s == ProgramStatus.reached;
  }

  bool get canEdit => canEnd && !(data?.isLocked ?? true);

  ProgramDetailState copyWith({
    ProgramDetailStatus? status,
    ProgramDetail? data,
    bool? ending,
    String? actionError,
    bool clearActionError = false,
    bool? versionConflict,
    bool? endedLocally,
  }) {
    return ProgramDetailState(
      status: status ?? this.status,
      data: data ?? this.data,
      ending: ending ?? this.ending,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      versionConflict: versionConflict ?? this.versionConflict,
      endedLocally: endedLocally ?? this.endedLocally,
    );
  }
}

