import 'query_key.dart';
import 'query_options.dart';

typedef InfiniteQueryFn<TData, TPageParam> = Future<TData> Function(
  TPageParam pageParam,
);

typedef GetNextPageParam<TData, TPageParam> = TPageParam? Function(
  TPageParam? lastPageParam,
  TData lastPage,
  List<TData> allPages,
);

typedef GetPreviousPageParam<TData, TPageParam> = TPageParam? Function(
  TPageParam? firstPageParam,
  TData firstPage,
  List<TData> allPages,
);

/// Options for infinite/paginated queries.
class InfiniteQueryOptions<TData, TPageParam> {
  InfiniteQueryOptions({
    required this.queryKey,
    required this.queryFn,
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    this.staleTime,
    this.gcTime,
    this.retry,
    this.enabled = true,
    this.maxPages,
  });

  final QueryKey queryKey;
  final InfiniteQueryFn<TData, TPageParam> queryFn;
  final TPageParam initialPageParam;
  final GetNextPageParam<TData, TPageParam> getNextPageParam;
  final GetPreviousPageParam<TData, TPageParam>? getPreviousPageParam;
  final Duration? staleTime;
  final Duration? gcTime;
  final int? retry;
  final bool enabled;
  final int? maxPages;

  InfiniteQueryOptions<TData, TPageParam> mergeDefaults(
    QueryOptionsDefaults defaults,
  ) {
    return InfiniteQueryOptions<TData, TPageParam>(
      queryKey: queryKey,
      queryFn: queryFn,
      initialPageParam: initialPageParam,
      getNextPageParam: getNextPageParam,
      getPreviousPageParam: getPreviousPageParam,
      staleTime: staleTime ?? defaults.staleTime,
      gcTime: gcTime ?? defaults.gcTime,
      retry: retry ?? defaults.retry,
      enabled: enabled && defaults.enabled,
      maxPages: maxPages,
    );
  }
}
