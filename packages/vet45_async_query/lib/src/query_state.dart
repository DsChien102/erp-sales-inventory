import 'fetch_status.dart';
import 'query_status.dart';

/// Immutable snapshot of a query's state.
class QueryState<T> {
  const QueryState({
    this.data,
    this.error,
    this.status = QueryStatus.pending,
    this.fetchStatus = FetchStatus.idle,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
    this.isStale = true,
    this.isFetching = false,
    this.isLoading = false,
    this.isRefetching = false,
    this.isPaused = false,
    this.failureCount = 0,
    this.failureReason,
  });

  final T? data;
  final Object? error;
  final QueryStatus status;
  final FetchStatus fetchStatus;
  final DateTime? dataUpdatedAt;
  final DateTime? errorUpdatedAt;
  final bool isStale;
  final bool isFetching;
  final bool isLoading;
  final bool isRefetching;
  final bool isPaused;
  final int failureCount;
  final Object? failureReason;

  bool get isError => status == QueryStatus.error;
  bool get isSuccess => status == QueryStatus.success;
  bool get hasData => data != null;

  QueryState<T> copyWith({
    T? data,
    Object? error,
    QueryStatus? status,
    FetchStatus? fetchStatus,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isStale,
    bool? isFetching,
    bool? isLoading,
    bool? isRefetching,
    bool? isPaused,
    int? failureCount,
    Object? failureReason,
    bool clearData = false,
    bool clearError = false,
  }) {
    return QueryState<T>(
      data: clearData ? null : (data ?? this.data),
      error: clearError ? null : (error ?? this.error),
      status: status ?? this.status,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isStale: isStale ?? this.isStale,
      isFetching: isFetching ?? this.isFetching,
      isLoading: isLoading ?? this.isLoading,
      isRefetching: isRefetching ?? this.isRefetching,
      isPaused: isPaused ?? this.isPaused,
      failureCount: failureCount ?? this.failureCount,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QueryState<T> &&
            other.data == data &&
            other.error == error &&
            other.status == status &&
            other.fetchStatus == fetchStatus &&
            other.dataUpdatedAt == dataUpdatedAt &&
            other.errorUpdatedAt == errorUpdatedAt &&
            other.isStale == isStale &&
            other.isFetching == isFetching &&
            other.isLoading == isLoading &&
            other.isRefetching == isRefetching &&
            other.isPaused == isPaused &&
            other.failureCount == failureCount;
  }

  @override
  int get hashCode => Object.hash(
        data,
        error,
        status,
        fetchStatus,
        dataUpdatedAt,
        errorUpdatedAt,
        isStale,
        isFetching,
        isLoading,
        isRefetching,
        isPaused,
        failureCount,
      );
}

QueryState<T> deriveQueryState<T>({
  required T? data,
  required Object? error,
  required QueryStatus status,
  required FetchStatus fetchStatus,
  required DateTime? dataUpdatedAt,
  required DateTime? errorUpdatedAt,
  required bool isStale,
  required int failureCount,
  Object? failureReason,
}) {
  final isFetching = fetchStatus == FetchStatus.fetching;
  final isPaused = fetchStatus == FetchStatus.paused;
  final isLoading = status == QueryStatus.pending && isFetching;
  final isRefetching = status == QueryStatus.success && isFetching;

  return QueryState<T>(
    data: data,
    error: error,
    status: status,
    fetchStatus: fetchStatus,
    dataUpdatedAt: dataUpdatedAt,
    errorUpdatedAt: errorUpdatedAt,
    isStale: isStale,
    isFetching: isFetching,
    isLoading: isLoading,
    isRefetching: isRefetching,
    isPaused: isPaused,
    failureCount: failureCount,
    failureReason: failureReason,
  );
}
