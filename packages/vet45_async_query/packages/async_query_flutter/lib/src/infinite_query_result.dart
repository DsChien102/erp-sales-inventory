import 'package:async_query/async_query.dart';

/// View model for infinite query builders.
class InfiniteQueryResult<TData, TPageParam> {
  const InfiniteQueryResult(
    this.state, {
    required this.fetchNextPage,
    required this.refetch,
  });

  final InfiniteQueryState<TData, TPageParam> state;
  final Future<InfiniteQueryState<TData, TPageParam>> Function() fetchNextPage;
  final Future<InfiniteQueryState<TData, TPageParam>> Function() refetch;

  List<TData> get pages => state.pages;
  List<TData> get flatData => state.flatData;
  Object? get error => state.error;

  bool get isLoading => state.isLoading;
  bool get isFetching => state.isFetching;
  bool get isFetchingNextPage => state.isFetchingNextPage;
  bool get isRefetching => state.isRefetching;
  bool get isError => state.isError;
  bool get isSuccess => state.isSuccess;
  bool get hasNextPage => state.hasNextPage;
}
