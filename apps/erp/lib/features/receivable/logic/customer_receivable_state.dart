import 'package:equatable/equatable.dart';

import '../data/receivable_models.dart';

enum LoadStatus { loading, ready, error }

class CustomerReceivableState extends Equatable {
  const CustomerReceivableState({
    this.detailStatus = LoadStatus.loading,
    this.detail,
    this.historyStatus = LoadStatus.loading,
    this.history = const [],
    this.historyCursor,
    this.historyLoadingMore = false,
  });

  final LoadStatus detailStatus;
  final CustomerReceivableDetail? detail;
  final LoadStatus historyStatus;
  final List<ReceivableHistoryItem> history;
  final String? historyCursor;
  final bool historyLoadingMore;

  CustomerReceivableState copyWith({
    LoadStatus? detailStatus,
    CustomerReceivableDetail? detail,
    LoadStatus? historyStatus,
    List<ReceivableHistoryItem>? history,
    String? Function()? historyCursor,
    bool? historyLoadingMore,
  }) => CustomerReceivableState(
    detailStatus: detailStatus ?? this.detailStatus,
    detail: detail ?? this.detail,
    historyStatus: historyStatus ?? this.historyStatus,
    history: history ?? this.history,
    historyCursor: historyCursor != null ? historyCursor() : this.historyCursor,
    historyLoadingMore: historyLoadingMore ?? this.historyLoadingMore,
  );

  @override
  List<Object?> get props => [
    detailStatus,
    detail,
    historyStatus,
    history,
    historyCursor,
    historyLoadingMore,
  ];
}
