import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';

enum StocktakeRecountStatus { loading, loadError, ready, submitting }

class StocktakeRecountState extends Equatable {
  const StocktakeRecountState({
    this.status = StocktakeRecountStatus.loading,
    this.session,
    this.inputs = const {},
    this.reasons = const {},
    this.stateChangeKind,
    this.stateChangeStatus,
    this.submitError,
    this.navigatedStatus,
  });

  final StocktakeRecountStatus status;
  final StocktakeSession? session;
  final Map<String, String> inputs;
  final Map<String, StocktakeLossReason> reasons;
  final StocktakeStateChangeKind? stateChangeKind;
  final StocktakeStatus? stateChangeStatus;
  final String? submitError;
  final StocktakeStatus? navigatedStatus;

  List<StocktakeLine> get varianceLines => (session?.lines ?? const [])
      .where((l) => l.needsRecount)
      .toList(growable: false);

  List<StocktakeLine> get matchedLines => (session?.lines ?? const [])
      .where((l) => !l.needsRecount)
      .toList(growable: false);

  int get missingCount => varianceLines
      .where((l) => parseStocktakeCount(inputs[l.lineId] ?? '') == null)
      .length;

  StocktakeRecountState copyWith({
    StocktakeRecountStatus? status,
    StocktakeSession? session,
    Map<String, String>? inputs,
    Map<String, StocktakeLossReason>? reasons,
    StocktakeStateChangeKind? stateChangeKind,
    bool clearStateChange = false,
    StocktakeStatus? stateChangeStatus,
    String? submitError,
    bool clearSubmitError = false,
    StocktakeStatus? navigatedStatus,
  }) {
    return StocktakeRecountState(
      status: status ?? this.status,
      session: session ?? this.session,
      inputs: inputs ?? this.inputs,
      reasons: reasons ?? this.reasons,
      stateChangeKind:
          clearStateChange ? null : (stateChangeKind ?? this.stateChangeKind),
      stateChangeStatus:
          clearStateChange ? null : (stateChangeStatus ?? this.stateChangeStatus),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      navigatedStatus: navigatedStatus ?? this.navigatedStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    session,
    inputs,
    reasons,
    stateChangeKind,
    stateChangeStatus,
    submitError,
    navigatedStatus,
  ];
}

