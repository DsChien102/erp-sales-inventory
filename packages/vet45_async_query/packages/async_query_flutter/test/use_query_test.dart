import 'package:async_query_flutter/async_query_flutter.dart';
import 'package:async_query/async_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

QueryClient createTestClient() {
  return QueryClient(
    options: const QueryClientOptions(
      queries: QueryOptionsDefaults(
        gcTime: Duration.zero,
        staleTime: Duration(minutes: 5),
        retry: 0,
      ),
    ),
  );
}

void main() {
  testWidgets('UseQuery fetches and displays data', (tester) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    var callCount = 0;

    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          home: UseQuery<List<String>>(
            queryKey: const ['test'],
            queryFn: () async {
              callCount++;
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return ['hello'];
            },
            builder: (context, result) {
              if (result.isLoading || (result.isFetching && !result.hasData)) {
                return const Text('loading');
              }
              return Text(result.data?.join(',') ?? 'empty');
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('loading'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);
    expect(callCount, 1);
  });

  testWidgets('two UseQuery widgets with same key deduplicate', (tester) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    var callCount = 0;

    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          home: Column(
            children: [
              UseQuery<int>(
                queryKey: const ['dedup'],
                queryFn: () async {
                  callCount++;
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  return 42;
                },
                builder: (context, result) => Text('a-${result.data ?? "?"}'),
              ),
              UseQuery<int>(
                queryKey: const ['dedup'],
                queryFn: () async {
                  callCount++;
                  return 42;
                },
                builder: (context, result) => Text('b-${result.data ?? "?"}'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('a-42'), findsOneWidget);
    expect(find.text('b-42'), findsOneWidget);
    expect(callCount, 1);
  });

  testWidgets('UseMutation executes and shows pending state', (tester) async {
    final client = createTestClient();
    addTearDown(client.dispose);

    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          home: UseMutation<String, String>(
            mutationFn: (input) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return 'done-$input';
            },
            builder: (context, mutation) {
              return Column(
                children: [
                  Text(mutation.isPending ? 'pending' : 'idle'),
                  ElevatedButton(
                    onPressed: () => mutation.mutate('x'),
                    child: const Text('run'),
                  ),
                  if (mutation.isSuccess) Text(mutation.data ?? ''),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('idle'), findsOneWidget);
    await tester.tap(find.text('run'));
    await tester.pump();
    expect(find.text('pending'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('done-x'), findsOneWidget);
  });

  testWidgets('UseQuery automatically refetches when refetchInterval is set', (tester) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    var callCount = 0;

    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          home: UseQuery<int>(
            queryKey: const ['interval-widget-test'],
            queryFn: () async {
              callCount++;
              return callCount;
            },
            refetchInterval: const Duration(milliseconds: 100),
            builder: (context, result) => Text('count-${result.data ?? 0}'),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('count-1'), findsOneWidget);
    expect(callCount, 1);

    await tester.pump(const Duration(milliseconds: 110));
    expect(find.text('count-2'), findsOneWidget);
    expect(callCount, 2);
  });
}
