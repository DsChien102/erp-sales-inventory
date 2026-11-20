import 'package:equatable/equatable.dart';

import '../data/receivable_models.dart';

enum ReceivableListStatus { loading, ready, error }

class ReceivableListState extends Equatable {
  const ReceivableListState({
    this.status = ReceivableListStatus.loading,
    this.filter = ReceivableFilter.all,
    this.query = '',
    this.summary,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
  });

  final ReceivableListStatus status;
  final ReceivableFilter filter;
  final String query;
  final ReceivableSummary? summary;
  final List<CustomerReceivableRow> items;
  final String? nextCursor;
  final bool loadingMore;

  ReceivableListState copyWith({
    ReceivableListStatus? status,
    ReceivableFilter? filter,
    String? query,
    ReceivableSummary? summary,
    List<CustomerReceivableRow>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
  }) => ReceivableListState(
    status: status ?? this.status,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    summary: summary ?? this.summary,
    items: items ?? this.items,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [status, filter, query, summary, items, nextCursor, loadingMore];
}
