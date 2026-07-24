import 'package:async_query/async_query.dart';
import 'package:test/test.dart';

void main() {
  group('hashQueryKey', () {
    test('produces stable hash for same key', () {
      const key = ['users', 1];
      expect(hashQueryKey(key), hashQueryKey(['users', 1]));
    });

    test('different keys produce different hashes', () {
      expect(hashQueryKey(['users']), isNot(hashQueryKey(['users', 1])));
    });

    test('queryKeyMatchesFilter supports prefix matching', () {
      expect(
        queryKeyMatchesFilter(['users', 1, 'detail'], ['users']),
        isTrue,
      );
      expect(
        queryKeyMatchesFilter(['users', 1], ['users', 2]),
        isFalse,
      );
    });
  });

  group('QueryClient', () {
    late QueryClient client;

    setUp(() {
      client = QueryClient(
        options: const QueryClientOptions(
          queries: QueryOptionsDefaults(
            staleTime: Duration(minutes: 5),
            gcTime: Duration(minutes: 10),
            retry: 0,
          ),
        ),
      );
    });

    tearDown(() {
      client.dispose();
    });

    test('deduplicates in-flight requests for same key', () async {
      var callCount = 0;
      Future<List<int>> queryFn() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return [callCount];
      }

      final observer1 = client.watchQuery<List<int>>(
        queryKey: const ['dedup'],
        queryFn: queryFn,
        refetchOnMount: true,
      );
      final observer2 = client.watchQuery<List<int>>(
        queryKey: const ['dedup'],
        queryFn: queryFn,
        refetchOnMount: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1);
      expect(observer1.currentState.data, [1]);
      expect(observer2.currentState.data, [1]);

      observer1.dispose();
      observer2.dispose();
    });

    test('returns stale data while refetching', () async {
      var callCount = 0;
      Future<String> queryFn() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'result-$callCount';
      }

      final observer = client.watchQuery<String>(
        queryKey: const ['swr'],
        queryFn: queryFn,
        staleTime: Duration.zero,
        refetchOnMount: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(observer.currentState.data, 'result-1');

      await observer.refetch();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(observer.currentState.data, 'result-2');
      expect(observer.currentState.isSuccess, isTrue);

      observer.dispose();
    });

    test('invalidateQueries triggers refetch for active queries', () async {
      var callCount = 0;
      Future<int> queryFn() async {
        callCount++;
        return callCount;
      }

      final observer = client.watchQuery<int>(
        queryKey: const ['invalidate'],
        queryFn: queryFn,
        staleTime: const Duration(minutes: 5),
        refetchOnMount: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(callCount, 1);
      expect(observer.currentState.data, 1);

      await client.invalidateQueries(queryKey: const ['invalidate']);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(callCount, 2);
      expect(observer.currentState.data, 2);

      observer.dispose();
    });

    test('setQueryData and getQueryData work without fetch', () {
      client.setQueryData(const ['manual'], 'hello');
      expect(client.getQueryData<String>(const ['manual']), 'hello');
    });

    test('prefix invalidation matches multiple queries', () async {
      var usersCalls = 0;
      var usersDetailCalls = 0;

      final usersObserver = client.watchQuery<String>(
        queryKey: const ['users'],
        queryFn: () async {
          usersCalls++;
          return 'users-$usersCalls';
        },
        staleTime: const Duration(minutes: 5),
      );
      final detailObserver = client.watchQuery<String>(
        queryKey: const ['users', 1],
        queryFn: () async {
          usersDetailCalls++;
          return 'detail-$usersDetailCalls';
        },
        staleTime: const Duration(minutes: 5),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(usersCalls, 1);
      expect(usersDetailCalls, 1);

      await client.invalidateQueries(queryKey: const ['users']);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(usersCalls, 2);
      expect(usersDetailCalls, 2);

      usersObserver.dispose();
      detailObserver.dispose();
    });

    test('retries failed queries', () async {
      var attempts = 0;
      Future<String> queryFn() async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return 'ok';
      }

      final observer = client.watchQuery<String>(
        queryKey: const ['retry'],
        queryFn: queryFn,
        retry: 3,
        retryDelay: (_) => Duration.zero,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(attempts, 3);
      expect(observer.currentState.data, 'ok');

      observer.dispose();
    });
  });

  group('Mutation', () {
    test('optimistic update rolls back on error', () async {
      final client = QueryClient();
      const listKey = ['items'];

      client.setQueryData(listKey, <String>['a']);

      final mutation = client.buildMutation<List<String>, String>(
        mutationFn: (_) async => throw Exception('fail'),
        onMutate: (item) async {
          final current =
              client.getQueryData<List<String>>(listKey) ?? <String>[];
          client.setQueryData(listKey, [...current, item]);
          return current;
        },
        onError: (_, _, rollback, ctx) async {
          if (rollback is List<String>) {
            ctx.client.setQueryData(listKey, rollback);
          }
        },
      );

      await mutation.mutate('b');
      expect(client.getQueryData<List<String>>(listKey), ['a']);
      client.dispose();
    });

    test('mutation success updates state', () async {
      final client = QueryClient();
      final mutation = client.buildMutation<String, String>(
        mutationFn: (input) async => 'created-$input',
      );

      final result = await mutation.mutate('item');
      expect(result.isSuccess, isTrue);
      expect(result.data, 'created-item');
      client.dispose();
    });
  });

  group('InfiniteQuery', () {
    test('fetches first and next page', () async {
      final client = QueryClient();
      final observer = client.watchInfiniteQuery<List<int>, int>(
        queryKey: const ['infinite'],
        initialPageParam: 0,
        queryFn: (page) async => [page, page + 1],
        getNextPageParam: (lastParam, lastPage, allPages) {
          if (allPages.length >= 2) return null;
          return (lastParam ?? 0) + 2;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(observer.currentState.pages.length, 1);
      expect(observer.currentState.hasNextPage, isTrue);

      await observer.fetchNextPage();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(observer.currentState.pages.length, 2);
      expect(observer.currentState.hasNextPage, isFalse);

      observer.dispose();
      client.dispose();
    });
  });
}
