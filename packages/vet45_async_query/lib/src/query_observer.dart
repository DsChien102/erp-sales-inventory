import 'dart:async';

import 'query.dart';
import 'query_state.dart';

/// Subscribes to a [Query] and exposes its state as a stream.
class QueryObserver<T> {
  QueryObserver({
    required Query<T> query,
    this.refetchOnMount = true,
  })  : _query = query,
        _currentState = query.state,
        _controller = StreamController<QueryState<T>>.broadcast(
          onListen: () {},
        ) {
    _controller.onListen = () {
      if (!_controller.isClosed) {
        _controller.add(_query.state);
      }
    };

    _query.onObserverAdded();
    _query.addListener(_onQueryStateChanged);

    if (_query.options.enabled) {
      if (refetchOnMount || _query.shouldFetch) {
        unawaited(_query.fetch());
      }
    }
  }

  final Query<T> _query;
  final bool refetchOnMount;
  final StreamController<QueryState<T>> _controller;
  QueryState<T> _currentState;
  bool _disposed = false;

  Stream<QueryState<T>> get stream => _controller.stream;

  QueryState<T> get currentState => _currentState;

  Query<T> get query => _query;

  void _onQueryStateChanged(QueryState<T> state) {
    if (_disposed) return;
    _currentState = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<QueryState<T>> refetch() => _query.fetch(force: true);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _query.removeListener(_onQueryStateChanged);
    _query.onObserverRemoved();
    unawaited(_controller.close());
  }
}
