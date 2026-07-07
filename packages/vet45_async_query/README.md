# async_query

TanStack Query-inspired async state management for Dart and Flutter.

`async_query` separates **server state** (fetching, caching, synchronization) from UI state. The core package is pure Dart; Flutter widgets live in `async_query_flutter`.

## Features

- Query cache with stale-while-revalidate
- Request deduplication (multiple subscribers, one network call)
- Two-axis state model: `QueryStatus` + `FetchStatus`
- Query invalidation and prefetching
- Mutations with optimistic updates and rollback
- Infinite/paginated queries
- Automatic retry with exponential backoff
- Flutter widgets: `UseQuery`, `UseMutation`, `UseInfiniteQuery`
- App lifecycle refetch on resume

## Packages

| Package | Description |
|---------|-------------|
| `async_query` | Pure Dart core engine |
| `async_query_flutter` | Flutter widgets and providers |
| `async_query_example` | Demo app (list, detail, mutation) |

## Quick start

```yaml
dependencies:
  async_query: ^0.1.0
  async_query_flutter: ^0.1.0
```

```dart
import 'package:async_query/async_query.dart';
import 'package:async_query_flutter/async_query_flutter.dart';

final client = QueryClient();

void main() {
  runApp(
    QueryClientProvider(
      client: client,
      child: MaterialApp(home: UsersPage()),
    ),
  );
}

class UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UseQuery<List<User>>(
      queryKey: const ['users'],
      queryFn: () => api.fetchUsers(),
      staleTime: const Duration(minutes: 5),
      builder: (context, result) {
        if (result.isLoading) return CircularProgressIndicator();
        if (result.isError) return Text('${result.error}');
        return ListView(
          children: result.data!.map((u) => ListTile(title: Text(u.name))).toList(),
        );
      },
    );
  }
}
```

## Core API

```dart
// Manual observer (tests, custom UI)
final observer = client.watchQuery<List<User>>(
  queryKey: ['users'],
  queryFn: () => api.fetchUsers(),
);
observer.stream.listen((state) => print(state.data));

// Invalidation
await client.invalidateQueries(queryKey: ['users']);

// Prefetch
await client.prefetchQuery(
  queryKey: ['user', id],
  queryFn: () => api.fetchUser(id),
);

// Mutations
final mutation = client.buildMutation<User, CreateUserRequest>(
  mutationFn: (req) => api.createUser(req),
  onSuccess: (_, __, ctx) => ctx.client.invalidateQueries(
    queryKey: ['users'],
  ),
);
await mutation.mutate(request);
```

## Query keys

Use stable, serializable keys:

```dart
const ['users']
['users', userId]
['users', userId, 'posts']
```

Do **not** use object identity or auto-generated IDs as cache keys.

## State model

| Flag | Meaning |
|------|---------|
| `isLoading` | First fetch in progress (no cached data) |
| `isFetching` | Any fetch in progress |
| `isRefetching` | Background refresh while showing cached data |
| `isStale` | Data older than `staleTime` |
| `isError` | Fetch failed with no cached data |

## Running the example

```bash
cd async_query
dart pub get
cd packages/async_query_flutter && flutter pub get
cd ../../example && flutter run
```

## Testing

```bash
cd async_query
dart test
cd packages/async_query_flutter && flutter test
```

## Comparison with manual Cubit pattern

Without `async_query`, each screen implements its own `loading/success/failure` state, manual refetch after mutations, and no cross-screen cache. With `async_query`:

- Navigating list → detail → back reuses cached list data (within `staleTime`)
- Multiple widgets requesting the same key share one fetch
- Mutations invalidate related queries declaratively

## License

MIT
