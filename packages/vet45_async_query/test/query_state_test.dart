import 'package:async_query/async_query.dart';
import 'package:test/test.dart';

void main() {
  group('QueryState', () {
    test('derives isLoading and isRefetching correctly', () {
      final loading = deriveQueryState<String>(
        data: null,
        error: null,
        status: QueryStatus.pending,
        fetchStatus: FetchStatus.fetching,
        dataUpdatedAt: null,
        errorUpdatedAt: null,
        isStale: true,
        failureCount: 0,
      );
      expect(loading.isLoading, isTrue);
      expect(loading.isRefetching, isFalse);

      final refetching = deriveQueryState<String>(
        data: 'cached',
        error: null,
        status: QueryStatus.success,
        fetchStatus: FetchStatus.fetching,
        dataUpdatedAt: DateTime.now(),
        errorUpdatedAt: null,
        isStale: false,
        failureCount: 0,
      );
      expect(refetching.isRefetching, isTrue);
      expect(refetching.isLoading, isFalse);
    });
  });

  group('RetryResolver', () {
    test('respects maxRetries', () {
      final resolver = RetryResolver(
        maxRetries: 2,
        retryDelay: (_) => Duration.zero,
        retryOn: (_) => true,
      );
      expect(resolver.shouldRetry(Exception(), 1), isTrue);
      expect(resolver.shouldRetry(Exception(), 2), isTrue);
      expect(resolver.shouldRetry(Exception(), 3), isFalse);
    });
  });
}
