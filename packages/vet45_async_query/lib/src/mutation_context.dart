import 'query_key.dart';

/// Cache operations exposed to mutation callbacks.
abstract interface class IMutationClient {
  Future<void> invalidateQueries({
    QueryKeyFilter? queryKey,
    bool exact = false,
  });

  Future<void> refetchQueries({
    QueryKeyFilter? queryKey,
    bool exact = false,
  });

  void setQueryData<T>(QueryKey queryKey, T data);

  T? getQueryData<T>(QueryKey queryKey);
}

/// Context passed to mutation callbacks for cache operations.
class MutationContext {
  MutationContext(this.client);

  final IMutationClient client;
}
