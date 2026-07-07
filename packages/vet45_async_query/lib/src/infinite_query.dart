import 'dart:async';

import 'fetch_status.dart';
import 'infinite_query_options.dart';
import 'infinite_query_state.dart';
import 'notify_scheduler.dart';
import 'query_status.dart';

typedef InfiniteQueryListener<TData, TPageParam> = void Function(
  InfiniteQueryState<TData, TPageParam> state,
);

/// Manages paginated query state with fetch-next-page support.
class InfiniteQuery<TData, TPageParam> {
  InfiniteQuery({
    required InfiniteQueryOptions<TData, TPageParam> options,
    required NotifyScheduler scheduler,
  })  : _options = options,
        _scheduler = scheduler;

  InfiniteQueryOptions<TData, TPageParam> _options;
  final NotifyScheduler _scheduler;

  final _listeners = <InfiniteQueryListener<TData, TPageParam>>{};
  InfiniteQueryState<TData, TPageParam> _state =
      InfiniteQueryState<TData, TPageParam>();

  int _observerCount = 0;
  Future<void>? _fetchPromise;

  InfiniteQueryState<TData, TPageParam> get state => _state;

  void updateOptions(InfiniteQueryOptions<TData, TPageParam> options) {
    _options = options;
  }

  void addListener(InfiniteQueryListener<TData, TPageParam> listener) {
    _listeners.add(listener);
    listener(_state);
  }

  void removeListener(InfiniteQueryListener<TData, TPageParam> listener) {
    _listeners.remove(listener);
  }

  void onObserverAdded() => _observerCount++;
  void onObserverRemoved() => _observerCount = (_observerCount - 1).clamp(0, 999999);

  bool get hasObservers => _observerCount > 0 || _listeners.isNotEmpty;

  Future<InfiniteQueryState<TData, TPageParam>> fetchFirstPage() async {
    if (!_options.enabled) return _state;
    if (_fetchPromise != null) {
      await _fetchPromise;
      return _state;
    }

    _fetchPromise = _fetchFirstPageInternal();
    try {
      await _fetchPromise;
    } finally {
      _fetchPromise = null;
    }
    return _state;
  }

  Future<void> _fetchFirstPageInternal() async {
    _setState(
      _state.copyWith(
        status: QueryStatus.pending,
        fetchStatus: FetchStatus.fetching,
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final page = await _options.queryFn(_options.initialPageParam);
      final nextParam = _options.getNextPageParam(
        _options.initialPageParam,
        page,
        [page],
      );

      _setState(
        _state.copyWith(
          pages: [page],
          pageParams: [_options.initialPageParam],
          status: QueryStatus.success,
          fetchStatus: FetchStatus.idle,
          hasNextPage: nextParam != null,
          isLoading: false,
          dataUpdatedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          status: QueryStatus.error,
          fetchStatus: FetchStatus.idle,
          error: error,
          isLoading: false,
        ),
      );
    }
  }

  Future<InfiniteQueryState<TData, TPageParam>> fetchNextPage() async {
    if (!_state.hasNextPage || _state.isFetchingNextPage) return _state;

    final lastPageParam = _state.pageParams.isNotEmpty
        ? _state.pageParams.last
        : _options.initialPageParam;
    final lastPage = _state.pages.last;

    final nextParam = _options.getNextPageParam(
      lastPageParam,
      lastPage,
      _state.pages,
    );
    if (nextParam == null) {
      _setState(_state.copyWith(hasNextPage: false));
      return _state;
    }

    _setState(_state.copyWith(isFetchingNextPage: true));

    try {
      final page = await _options.queryFn(nextParam);
      final pages = [..._state.pages, page];
      final pageParams = [..._state.pageParams, nextParam];
      final nextNextParam = _options.getNextPageParam(
        nextParam,
        page,
        pages,
      );

      _setState(
        _state.copyWith(
          pages: pages,
          pageParams: pageParams,
          hasNextPage: nextNextParam != null,
          isFetchingNextPage: false,
          dataUpdatedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          error: error,
          isFetchingNextPage: false,
        ),
      );
    }

    return _state;
  }

  Future<InfiniteQueryState<TData, TPageParam>> refetch() async {
    _setState(
      InfiniteQueryState<TData, TPageParam>().copyWith(
        isRefetching: true,
        fetchStatus: FetchStatus.fetching,
      ),
    );
    return fetchFirstPage();
  }

  void _setState(InfiniteQueryState<TData, TPageParam> state) {
    _state = state;
    _scheduler.schedule(() {
      for (final listener in _listeners.toList()) {
        listener(_state);
      }
    });
  }

  void dispose() {
    _listeners.clear();
  }
}
