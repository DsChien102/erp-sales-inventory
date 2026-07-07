import 'dart:async';

import 'hash_query_key.dart';
import 'infinite_query.dart';
import 'infinite_query_observer.dart';
import 'infinite_query_options.dart';
import 'mutation.dart';
import 'mutation_cache.dart';
import 'mutation_context.dart';
import 'mutation_options.dart';
import 'query_cache.dart';
import 'query_key.dart';
import 'query_observer.dart';
import 'query_options.dart';
import 'query_state.dart';

/// Central facade for query and mutation cache management.
class QueryClient implements IMutationClient {
  QueryClient({
    QueryClientOptions options = const QueryClientOptions(),
    QueryCache? queryCache,
    MutationCache? mutationCache,
  })  : _options = options,
        _queryCache = queryCache ?? QueryCache(),
        _mutationCache = mutationCache ?? MutationCache() {
    _mutationContext = MutationContext(this);
  }

  final QueryClientOptions _options;
  final QueryCache _queryCache;
  final MutationCache _mutationCache;
  final _infiniteQueries = <String, InfiniteQuery<dynamic, dynamic>>{};
  late final MutationContext _mutationContext;

  QueryCache get queryCache => _queryCache;

  MutationContext get mutationContext => _mutationContext;

  QueryObserver<T> watchQuery<T>({
    required QueryKey queryKey,
    required QueryFn<T> queryFn,
    Duration? staleTime,
    Duration? gcTime,
    int? retry,
    Duration Function(int attempt)? retryDelay,
    bool Function(Object error)? retryOn,
    bool? refetchOnMount,
    bool enabled = true,
    T? initialData,
    T? placeholderData,
    T Function(T data)? select,
  }) {
    final options = _buildQueryOptions<T>(
      queryKey: queryKey,
      queryFn: queryFn,
      staleTime: staleTime,
      gcTime: gcTime,
      retry: retry,
      retryDelay: retryDelay,
      retryOn: retryOn,
      refetchOnMount: refetchOnMount,
      enabled: enabled,
      initialData: initialData,
      placeholderData: placeholderData,
      select: select,
    );

    final query = _queryCache.buildQuery(options);
    return QueryObserver<T>(
      query: query,
      refetchOnMount: options.refetchOnMount ?? true,
    );
  }

  Future<QueryState<T>> fetchQuery<T>({
    required QueryKey queryKey,
    required QueryFn<T> queryFn,
    Duration? staleTime,
    Duration? gcTime,
    int? retry,
    Duration Function(int attempt)? retryDelay,
    bool Function(Object error)? retryOn,
    bool enabled = true,
    T? initialData,
    T? placeholderData,
    T Function(T data)? select,
  }) async {
    final options = _buildQueryOptions<T>(
      queryKey: queryKey,
      queryFn: queryFn,
      staleTime: staleTime,
      gcTime: gcTime,
      retry: retry,
      retryDelay: retryDelay,
      retryOn: retryOn,
      enabled: enabled,
      initialData: initialData,
      placeholderData: placeholderData,
      select: select,
    );

    final query = _queryCache.buildQuery(options);
    return query.fetch(force: true);
  }

  Future<QueryState<T>> prefetchQuery<T>({
    required QueryKey queryKey,
    required QueryFn<T> queryFn,
    Duration? staleTime,
    Duration? gcTime,
  }) {
    return fetchQuery(
      queryKey: queryKey,
      queryFn: queryFn,
      staleTime: staleTime,
      gcTime: gcTime,
    );
  }

  @override
  T? getQueryData<T>(QueryKey queryKey) {
    return _queryCache.getQueryData<T>(queryKey);
  }

  @override
  void setQueryData<T>(QueryKey queryKey, T data) {
    _queryCache.setQueryData(queryKey, data);
  }

  @override
  Future<void> invalidateQueries({
    QueryKeyFilter? queryKey,
    bool exact = false,
  }) async {
    final queries = _queryCache.findQueries(queryKey: queryKey, exact: exact);
    for (final query in queries) {
      query.invalidate();
      if (query.hasObservers) {
        await query.fetch();
      }
    }
  }

  @override
  Future<void> refetchQueries({
    QueryKeyFilter? queryKey,
    bool exact = false,
  }) async {
    final queries = _queryCache.findQueries(queryKey: queryKey, exact: exact);
    await Future.wait(queries.map((query) => query.fetch(force: true)));
  }

  Mutation<TData, TVariables> buildMutation<TData, TVariables>({
    required MutationFn<TData, TVariables> mutationFn,
    OnMutate<TData, TVariables>? onMutate,
    OnMutationSuccess<TData, TVariables>? onSuccess,
    OnMutationError<TData, TVariables>? onError,
    OnMutationSettled<TData, TVariables>? onSettled,
    int? retry,
    Duration Function(int attempt)? retryDelay,
    List<Object?>? mutationKey,
  }) {
    final options = MutationOptions<TData, TVariables>(
      mutationFn: mutationFn,
      onMutate: onMutate,
      onSuccess: onSuccess,
      onError: onError,
      onSettled: onSettled,
      retry: retry,
      retryDelay: retryDelay,
      mutationKey: mutationKey,
    ).mergeDefaults(_options.mutations);

    return _mutationCache.buildMutation(
      options: options,
      context: _mutationContext,
    );
  }

  InfiniteQueryObserver<TData, TPageParam> watchInfiniteQuery<TData, TPageParam>({
    required QueryKey queryKey,
    required InfiniteQueryFn<TData, TPageParam> queryFn,
    required TPageParam initialPageParam,
    required GetNextPageParam<TData, TPageParam> getNextPageParam,
    GetPreviousPageParam<TData, TPageParam>? getPreviousPageParam,
    Duration? staleTime,
    Duration? gcTime,
    int? retry,
    bool enabled = true,
    int? maxPages,
  }) {
    final options = InfiniteQueryOptions<TData, TPageParam>(
      queryKey: queryKey,
      queryFn: queryFn,
      initialPageParam: initialPageParam,
      getNextPageParam: getNextPageParam,
      getPreviousPageParam: getPreviousPageParam,
      staleTime: staleTime,
      gcTime: gcTime,
      retry: retry,
      enabled: enabled,
      maxPages: maxPages,
    ).mergeDefaults(_options.queries);

    final hashedKey = hashQueryKey(queryKey);
    final existing = _infiniteQueries[hashedKey];
    final query = existing != null
        ? (existing as InfiniteQuery<TData, TPageParam>..updateOptions(options))
        : InfiniteQuery<TData, TPageParam>(
            options: options,
            scheduler: _queryCache.scheduler,
          );

    _infiniteQueries[hashedKey] = query;
    return InfiniteQueryObserver<TData, TPageParam>(query: query);
  }

  void clear() {
    _queryCache.clear();
    _mutationCache.clear();
    for (final query in _infiniteQueries.values) {
      query.dispose();
    }
    _infiniteQueries.clear();
  }

  void dispose() {
    clear();
    _queryCache.dispose();
    _mutationCache.dispose();
  }

  QueryOptions<T> _buildQueryOptions<T>({
    required QueryKey queryKey,
    required QueryFn<T> queryFn,
    Duration? staleTime,
    Duration? gcTime,
    int? retry,
    Duration Function(int attempt)? retryDelay,
    bool Function(Object error)? retryOn,
    bool? refetchOnMount,
    bool enabled = true,
    T? initialData,
    T? placeholderData,
    T Function(T data)? select,
  }) {
    return QueryOptions<T>(
      queryKey: queryKey,
      queryFn: queryFn,
      staleTime: staleTime,
      gcTime: gcTime,
      retry: retry,
      retryDelay: retryDelay,
      retryOn: retryOn,
      refetchOnMount: refetchOnMount,
      enabled: enabled,
      initialData: initialData,
      placeholderData: placeholderData,
      select: select,
    ).mergeDefaults(_options.queries);
  }
}
