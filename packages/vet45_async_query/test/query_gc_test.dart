import 'package:async_query/async_query.dart';
import 'package:test/test.dart';

void main() {
  test('GC removes query after gcTime when no observers', () async {
    final client = QueryClient(
      options: const QueryClientOptions(
        queries: QueryOptionsDefaults(
          gcTime: Duration(milliseconds: 50),
          staleTime: Duration(minutes: 5),
        ),
      ),
    );

    final observer = client.watchQuery<String>(
      queryKey: const ['gc'],
      queryFn: () async => 'data',
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(client.getQueryData<String>(const ['gc']), 'data');

    observer.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // After GC, getQueryData returns null because query was removed
    expect(client.getQueryData<String>(const ['gc']), isNull);

    client.dispose();
  });
}
