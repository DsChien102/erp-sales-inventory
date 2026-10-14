import '../data/models/valuation_work_item.dart';

enum ValuationQueueStatus {
  initial,
  loading,
  success,
  failure,
}

class ValuationQueueState {
  const ValuationQueueState({
    this.status = ValuationQueueStatus.initial,
    this.items = const [],
    this.query = '',
    this.filter = 'ALL',
    this.errorMessage,
  });

  final ValuationQueueStatus status;
  final List<ValuationWorkItem> items;
  final String query;
  final String filter;
  final String? errorMessage;

  bool get isLoading => status == ValuationQueueStatus.loading;
  bool get isSuccess => status == ValuationQueueStatus.success;

  ValuationQueueState copyWith({
    ValuationQueueStatus? status,
    List<ValuationWorkItem>? items,
    String? query,
    String? filter,
    String? errorMessage,
  }) {
    return ValuationQueueState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
