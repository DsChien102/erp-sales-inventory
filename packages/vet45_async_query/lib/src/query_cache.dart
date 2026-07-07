import 'hash_query_key.dart';
import 'notify_scheduler.dart';
import 'query.dart';
import 'query_key.dart';
import 'query_options.dart';

/// In-memory store of [Query] instances keyed by hashed query key.
class QueryCache {
  QueryCache({NotifyScheduler? scheduler})
      : _scheduler = scheduler ?? NotifyScheduler();

  final NotifyScheduler _scheduler;
  final _queries = <String, Query<dynamic>>{};

  NotifyScheduler get scheduler => _scheduler;

  Query<T> buildQuery<T>(QueryOptions<T> options) {
    final hashedKey = hashQueryKey(options.queryKey);
    final existing = _queries[hashedKey];
    if (existing != null) {
      final query = existing as Query<T>;
      query.updateOptions(options);
      query.onGcDue = _handleGcDue;
      return query;
    }

    final query = Query<T>(
      queryKey: options.queryKey,
      hashedKey: hashedKey,
      options: options,
      scheduler: _scheduler,
    )..onGcDue = _handleGcDue;

    _queries[hashedKey] = query;
    return query;
  }

  Query<T>? getQuery<T>(QueryKey queryKey) {
    final hashedKey = hashQueryKey(queryKey);
    final query = _queries[hashedKey];
    return query as Query<T>?;
  }

  T? getQueryData<T>(QueryKey queryKey) {
    return getQuery<T>(queryKey)?.rawData;
  }

  void setQueryData<T>(QueryKey queryKey, T data) {
    final query = getQuery<T>(queryKey);
    if (query != null) {
      query.setData(data);
      return;
    }

    final options = QueryOptions<T>(
      queryKey: queryKey,
      queryFn: () => Future<T>.error(
        StateError('No queryFn registered for key $queryKey'),
      ),
    );
    final created = buildQuery(options);
    created.setData(data, manual: false);
  }

  Iterable<Query<dynamic>> getAllQueries() => _queries.values;

  List<Query<dynamic>> findQueries({
    QueryKeyFilter? queryKey,
    bool exact = false,
  }) {
    if (queryKey == null) return _queries.values.toList();

    return _queries.values.where((query) {
      if (exact) {
        return queryKeyMatchesFilter(query.queryKey, queryKey) &&
            query.queryKey.length == queryKey.length;
      }
      return queryKeyMatchesFilter(query.queryKey, queryKey);
    }).toList();
  }

  void remove(Query<dynamic> query) {
    _queries.remove(query.hashedKey);
    query.dispose();
  }

  void clear() {
    for (final query in _queries.values) {
      query.dispose();
    }
    _queries.clear();
  }

  void _handleGcDue(Query<dynamic> query) {
    if (query.hasObservers) return;
    remove(query);
  }

  void dispose() {
    clear();
    _scheduler.dispose();
  }
}
