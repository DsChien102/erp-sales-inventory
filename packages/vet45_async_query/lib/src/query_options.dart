import 'mutation_options.dart';
import 'query_key.dart';

typedef QueryFn<T> = Future<T> Function();

/// Default options applied to all queries unless overridden.
class QueryOptionsDefaults {
  const QueryOptionsDefaults({
    this.staleTime = Duration.zero,
    this.gcTime = Duration.zero,
    this.retry = 3,
    this.retryDelay = _defaultRetryDelay,
    this.retryOn = _defaultRetryOn,
    this.refetchOnMount = true,
    this.refetchInterval,
    this.enabled = true,
  });

  final Duration staleTime;
  final Duration gcTime;
  final int retry;
  final Duration Function(int attempt) retryDelay;
  final bool Function(Object error) retryOn;
  final bool refetchOnMount;
  final Duration? refetchInterval;
  final bool enabled;

  static Duration _defaultRetryDelay(int attempt) {
    return Duration(milliseconds: 200 * (1 << attempt.clamp(0, 10)));
  }

  static bool _defaultRetryOn(Object error) => true;
}

/// Per-query configuration.
class QueryOptions<T> {
  QueryOptions({
    required this.queryKey,
    required this.queryFn,
    this.staleTime,
    this.gcTime,
    this.retry,
    this.retryDelay,
    this.retryOn,
    this.refetchOnMount,
    this.refetchInterval,
    this.enabled = true,
    this.initialData,
    this.placeholderData,
    this.select,
  });

  final QueryKey queryKey;
  final QueryFn<T> queryFn;
  final Duration? staleTime;
  final Duration? gcTime;
  final int? retry;
  final Duration Function(int attempt)? retryDelay;
  final bool Function(Object error)? retryOn;
  final bool? refetchOnMount;
  final Duration? refetchInterval;
  final bool enabled;
  final T? initialData;
  final T? placeholderData;
  final T Function(T data)? select;

  QueryOptions<T> mergeDefaults(QueryOptionsDefaults defaults) {
    return QueryOptions<T>(
      queryKey: queryKey,
      queryFn: queryFn,
      staleTime: staleTime ?? defaults.staleTime,
      gcTime: gcTime ?? defaults.gcTime,
      retry: retry ?? defaults.retry,
      retryDelay: retryDelay ?? defaults.retryDelay,
      retryOn: retryOn ?? defaults.retryOn,
      refetchOnMount: refetchOnMount ?? defaults.refetchOnMount,
      refetchInterval: refetchInterval ?? defaults.refetchInterval,
      enabled: enabled && defaults.enabled,
      initialData: initialData,
      placeholderData: placeholderData,
      select: select,
    );
  }
}

class QueryClientOptions {
  const QueryClientOptions({
    this.queries = const QueryOptionsDefaults(),
    this.mutations = const MutationOptionsDefaults(),
  });

  final QueryOptionsDefaults queries;
  final MutationOptionsDefaults mutations;
}
