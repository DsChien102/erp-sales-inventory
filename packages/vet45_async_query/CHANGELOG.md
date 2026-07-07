# Changelog

## 0.1.0

- Initial release
- Pure Dart `async_query` core: `QueryClient`, `QueryCache`, `QueryObserver`
- Stale-while-revalidate, request deduplication, GC
- Query invalidation and prefetch
- Mutations with optimistic updates and rollback
- Infinite queries with `InfiniteQuery` and `InfiniteQueryObserver`
- Flutter package: `QueryClientProvider`, `UseQuery`, `UseMutation`, `UseInfiniteQuery`
- `AppLifecycleRefetch` for foreground refetch
- Example app with list, detail, create mutation, pull-to-refresh
