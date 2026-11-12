import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';

enum StocktakeListStatus { loading, ready, loadError }

enum StocktakeListFilter {
  all('ALL', 'Tất cả'),
  counting('COUNTING', 'Đang đếm'),
  recount('RECOUNT', 'Đếm lại'),
  done('DONE', 'Đã xong');

  const StocktakeListFilter(this.key, this.label);
  final String key;
  final String label;

  bool matches(StocktakeListRow row) => switch (this) {
    StocktakeListFilter.all => true,
    StocktakeListFilter.counting => row.status == StocktakeStatus.counting,
    StocktakeListFilter.recount => row.status == StocktakeStatus.recount,
    StocktakeListFilter.done =>
      row.status == StocktakeStatus.completed ||
          row.status == StocktakeStatus.cancelled,
  };

  static StocktakeListFilter fromKey(String key) => values.firstWhere(
    (f) => f.key == key,
    orElse: () => StocktakeListFilter.all,
  );
}

class StocktakeListState extends Equatable {
  const StocktakeListState({
    this.status = StocktakeListStatus.loading,
    this.all = const [],
    this.visible = const [],
    this.query = '',
    this.filter = StocktakeListFilter.all,
    this.counts = const {},
    this.errorMessage,
  });

  final StocktakeListStatus status;
  final List<StocktakeListRow> all;
  final List<StocktakeListRow> visible;
  final String query;
  final StocktakeListFilter filter;
  final Map<StocktakeListFilter, int> counts;
  final String? errorMessage;

  StocktakeListState copyWith({
    StocktakeListStatus? status,
    List<StocktakeListRow>? all,
    List<StocktakeListRow>? visible,
    String? query,
    StocktakeListFilter? filter,
    Map<StocktakeListFilter, int>? counts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StocktakeListState(
      status: status ?? this.status,
      all: all ?? this.all,
      visible: visible ?? this.visible,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      counts: counts ?? this.counts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    all,
    visible,
    query,
    filter,
    counts,
    errorMessage,
  ];
}

