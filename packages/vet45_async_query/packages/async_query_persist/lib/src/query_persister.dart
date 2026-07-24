/// Persists and restores serialized query cache entries.
abstract interface class QueryPersister {
  Future<void> persist(String key, Object? data);
  Future<Object?> restore(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
