import 'package:async_query/async_query.dart';
import 'query_persister.dart';

/// Wraps [QueryClient] with optional persistence hooks.
///
/// Persistence is opt-in: callers serialize [data] before [persist] and
/// deserialize after [restore]. This package provides the integration seam;
/// concrete storage (shared_preferences, hive, file) is app-specific.
class PersistedQueryClient {
  PersistedQueryClient({
    required QueryClient client,
    required QueryPersister persister,
    this.maxAge = const Duration(days: 1),
  })  : _client = client,
        _persister = persister;

  final QueryClient _client;
  final QueryPersister _persister;
  final Duration maxAge;

  QueryClient get client => _client;

  Future<void> hydrateQuery<T>(QueryKey queryKey) async {
    final key = hashQueryKey(queryKey);
    final restored = await _persister.restore(key);
    if (restored is T) {
      _client.setQueryData(queryKey, restored);
    }
  }

  Future<void> persistQuery<T>(QueryKey queryKey) async {
    final data = _client.getQueryData<T>(queryKey);
    if (data != null) {
      await _persister.persist(hashQueryKey(queryKey), data);
    }
  }

  Future<void> clearPersisted() => _persister.clear();

  void dispose() => _client.dispose();
}
