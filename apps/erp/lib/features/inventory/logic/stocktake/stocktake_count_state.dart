import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';

enum StocktakeCountStatus { loading, loadError, ready, submitting }

enum StocktakeCountFilter {
  todo('TODO', 'Chưa đếm'),
  done('DONE', 'Đã đếm'),
  all('ALL', 'Tất cả');

  const StocktakeCountFilter(this.key, this.label);
  final String key;
  final String label;

  static StocktakeCountFilter fromKey(String key) => values.firstWhere(
    (f) => f.key == key,
    orElse: () => StocktakeCountFilter.todo,
  );
}

enum StocktakeStateChangeKind { lockLost, conflict }

class StocktakeCountState extends Equatable {
  const StocktakeCountState({
    this.status = StocktakeCountStatus.loading,
    this.session,
    this.inputs = const {},
    this.filter = StocktakeCountFilter.todo,
    this.query = '',
    this.visibleLineIds = const [],
    this.stateChangeKind,
    this.stateChangeStatus,
    this.submitError,
    this.navigatedStatus,
  });

  final StocktakeCountStatus status;
  final StocktakeSession? session;
  final Map<String, String> inputs;
  final StocktakeCountFilter filter;
  final String query;
  final List<String> visibleLineIds;
  final StocktakeStateChangeKind? stateChangeKind;
  final StocktakeStatus? stateChangeStatus;
  final String? submitError;
  final StocktakeStatus? navigatedStatus;

  List<StocktakeLine> get lines => session?.lines ?? const [];

  int get totalCount => lines.length;

  int get countedCount => lines
      .where((l) => parseStocktakeCount(inputs[l.lineId] ?? '') != null)
      .length;

  int get uncountedCount => totalCount - countedCount;

  List<StocktakeLine> get visibleLines {
    final visibleSet = visibleLineIds.toSet();
    return lines
        .where((l) => visibleSet.contains(l.lineId))
        .toList(growable: false);
  }

  StocktakeCountState copyWith({
    StocktakeCountStatus? status,
    StocktakeSession? session,
    Map<String, String>? inputs,
    StocktakeCountFilter? filter,
    String? query,
    List<String>? visibleLineIds,
    StocktakeStateChangeKind? stateChangeKind,
    bool clearStateChange = false,
    StocktakeStatus? stateChangeStatus,
    String? submitError,
    bool clearSubmitError = false,
    StocktakeStatus? navigatedStatus,
  }) {
    return StocktakeCountState(
      status: status ?? this.status,
      session: session ?? this.session,
      inputs: inputs ?? this.inputs,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      visibleLineIds: visibleLineIds ?? this.visibleLineIds,
      stateChangeKind: clearStateChange
          ? null
          : (stateChangeKind ?? this.stateChangeKind),
      stateChangeStatus: clearStateChange
          ? null
          : (stateChangeStatus ?? this.stateChangeStatus),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      navigatedStatus: navigatedStatus ?? this.navigatedStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    session,
    inputs,
    filter,
    query,
    visibleLineIds,
    stateChangeKind,
    stateChangeStatus,
    submitError,
    navigatedStatus,
  ];
}

