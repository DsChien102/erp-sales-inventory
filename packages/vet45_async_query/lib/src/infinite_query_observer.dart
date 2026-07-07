import 'dart:async';

import 'infinite_query.dart';
import 'infinite_query_state.dart';

/// Subscribes to an [InfiniteQuery] and exposes its state as a stream.
class InfiniteQueryObserver<TData, TPageParam> {
  InfiniteQueryObserver({
    required InfiniteQuery<TData, TPageParam> query,
  })  : _query = query,
        _currentState = query.state,
        _controller =
            StreamController<InfiniteQueryState<TData, TPageParam>>.broadcast(
          onListen: () {},
        ) {
    _controller.onListen = () {
      if (!_controller.isClosed) {
        _controller.add(_query.state);
      }
    };

    _query.onObserverAdded();
    _query.addListener(_onStateChanged);

    if (_query.state.pages.isEmpty) {
      unawaited(_query.fetchFirstPage());
    }
  }

  final InfiniteQuery<TData, TPageParam> _query;
  final StreamController<InfiniteQueryState<TData, TPageParam>> _controller;
  InfiniteQueryState<TData, TPageParam> _currentState;
  bool _disposed = false;

  Stream<InfiniteQueryState<TData, TPageParam>> get stream => _controller.stream;

  InfiniteQueryState<TData, TPageParam> get currentState => _currentState;

  InfiniteQuery<TData, TPageParam> get query => _query;

  Future<InfiniteQueryState<TData, TPageParam>> fetchNextPage() =>
      _query.fetchNextPage();

  Future<InfiniteQueryState<TData, TPageParam>> refetch() => _query.refetch();

  void _onStateChanged(InfiniteQueryState<TData, TPageParam> state) {
    if (_disposed) return;
    _currentState = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _query.removeListener(_onStateChanged);
    _query.onObserverRemoved();
    unawaited(_controller.close());
  }
}
