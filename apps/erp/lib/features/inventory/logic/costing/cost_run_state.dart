import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';

enum CostRunPhase {
  draft,
  calculating,
  loaded,
  publishing,
  published,
  discarded,
  denied,
  error,
}

class CostRunState extends Equatable {
  const CostRunState({
    this.phase = CostRunPhase.draft,
    this.kind = CostRunKind.midPeriod,
    this.period,
    this.run,
    this.message,
  });

  final CostRunPhase phase;
  final CostRunKind kind;
  final DateTime? period;
  final CostRunView? run;
  final String? message;

  CostRunState copyWith({
    CostRunPhase? phase,
    CostRunKind? kind,
    DateTime? period,
    CostRunView? run,
    String? message,
    bool clearMessage = false,
  }) {
    return CostRunState(
      phase: phase ?? this.phase,
      kind: kind ?? this.kind,
      period: period ?? this.period,
      run: run ?? this.run,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [phase, kind, period, run, message];
}

