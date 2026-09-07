import 'dart:async';

import 'query.dart';
import 'query_state.dart';

/// Subscribes to a [Query] and exposes its state as a stream.
class QueryObserver<T> {
  QueryObserver({
    required Query<T> query,
    this.refetchOnMount = true,
    Duration? refetchInterval,
  })  : _query = query,
        _currentState = query.state,
        _refetchInterval = refetchInterval ?? query.options.refetchInterval,
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
      final shouldFetchOnMount = _query.rawData == null
          ? _query.shouldFetch
          : (refetchOnMount && _query.shouldFetch);
      if (shouldFetchOnMount) {
        unawaited(_query.fetch());
      }
      _startRefetchTimer();
    }
  }

  final Query<T> _query;
  final bool refetchOnMount;
  final Duration? _refetchInterval;
  Timer? _refetchTimer;
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

  void _startRefetchTimer() {
    _stopRefetchTimer();
    final interval = _refetchInterval ?? _query.options.refetchInterval;
    if (interval != null && interval > Duration.zero && _query.options.enabled) {
      _refetchTimer = Timer.periodic(interval, (_) {
        if (!_disposed && _query.options.enabled) {
          unawaited(refetch());
        }
      });
    }
  }

  void _stopRefetchTimer() {
    _refetchTimer?.cancel();
    _refetchTimer = null;
  }

  Future<QueryState<T>> refetch() => _query.fetch(force: true);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopRefetchTimer();
    _query.removeListener(_onQueryStateChanged);
    _query.onObserverRemoved();
    unawaited(_controller.close());
  }
}
