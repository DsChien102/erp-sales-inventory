import 'fetch_status.dart';
import 'query_status.dart';

/// State for paginated/infinite queries.
class InfiniteQueryState<TData, TPageParam> {
  const InfiniteQueryState({
    this.pages = const [],
    this.pageParams = const [],
    this.error,
    this.status = QueryStatus.pending,
    this.fetchStatus = FetchStatus.idle,
    this.hasNextPage = false,
    this.isFetchingNextPage = false,
    this.isRefetching = false,
    this.isLoading = false,
    this.dataUpdatedAt,
  });

  final List<TData> pages;
  final List<TPageParam> pageParams;
  final Object? error;
  final QueryStatus status;
  final FetchStatus fetchStatus;
  final bool hasNextPage;
  final bool isFetchingNextPage;
  final bool isRefetching;
  final bool isLoading;
  final DateTime? dataUpdatedAt;

  List<TData> get flatData => pages;

  bool get isError => status == QueryStatus.error;
  bool get isSuccess => status == QueryStatus.success;
  bool get isFetching => fetchStatus == FetchStatus.fetching;

  InfiniteQueryState<TData, TPageParam> copyWith({
    List<TData>? pages,
    List<TPageParam>? pageParams,
    Object? error,
    QueryStatus? status,
    FetchStatus? fetchStatus,
    bool? hasNextPage,
    bool? isFetchingNextPage,
    bool? isRefetching,
    bool? isLoading,
    DateTime? dataUpdatedAt,
    bool clearError = false,
  }) {
    return InfiniteQueryState<TData, TPageParam>(
      pages: pages ?? this.pages,
      pageParams: pageParams ?? this.pageParams,
      error: clearError ? null : (error ?? this.error),
      status: status ?? this.status,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isFetchingNextPage: isFetchingNextPage ?? this.isFetchingNextPage,
      isRefetching: isRefetching ?? this.isRefetching,
      isLoading: isLoading ?? this.isLoading,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
    );
  }
}
