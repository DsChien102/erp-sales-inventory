import 'dart:async';

import 'fetch_status.dart';
import 'notify_scheduler.dart';
import 'query_key.dart';
import 'query_options.dart';
import 'query_state.dart';
import 'query_status.dart';
import 'retry_resolver.dart';

typedef QueryStateListener<T> = void Function(QueryState<T> state);

/// A single cached query instance keyed by [queryKey].
class Query<T> {
  Query({
    required this.queryKey,
    required this.hashedKey,
    required QueryOptions<T> options,
    required NotifyScheduler scheduler,
  })  : _options = options,
        _scheduler = scheduler {
    if (options.initialData != null) {
      _data = options.initialData;
      _status = QueryStatus.success;
      _dataUpdatedAt = DateTime.now();
      _isStale = false;
    }
  }

  final QueryKey queryKey;
  final String hashedKey;

  QueryOptions<T> _options;
  final NotifyScheduler _scheduler;

  final _listeners = <QueryStateListener<T>>{};
  int _observerCount = 0;

  T? _data;
  Object? _error;
  QueryStatus _status = QueryStatus.pending;
  FetchStatus _fetchStatus = FetchStatus.idle;
  DateTime? _dataUpdatedAt;
  DateTime? _errorUpdatedAt;
  bool _isStale = true;
  int _failureCount = 0;
  Object? _failureReason;

  Future<T>? _fetchPromise;
  Timer? _gcTimer;
  void Function(Query<T>)? onGcDue;

  QueryOptions<T> get options => _options;

  RetryResolver get _retryResolver => RetryResolver(
        maxRetries: _options.retry ?? 0,
        retryDelay: _options.retryDelay ?? QueryOptionsDefaults().retryDelay,
        retryOn: _options.retryOn ?? QueryOptionsDefaults().retryOn,
      );

  void updateOptions(QueryOptions<T> options) {
    _options = options;
  }

  int get observerCount => _observerCount;

  QueryState<T> get state {
    final data = _selectData(_data);
    return deriveQueryState<T>(
      data: data,
      error: _error,
      status: _status,
      fetchStatus: _fetchStatus,
      dataUpdatedAt: _dataUpdatedAt,
      errorUpdatedAt: _errorUpdatedAt,
      isStale: _isStale || isStaleByTime,
      failureCount: _failureCount,
      failureReason: _failureReason,
    );
  }

  T? get rawData => _data;

  T? _selectData(T? data) {
    if (data == null) {
      return _options.placeholderData;
    }
    final select = _options.select;
    if (select == null) return data;
    return select(data);
  }

  void addListener(QueryStateListener<T> listener) {
    _listeners.add(listener);
    _cancelGcTimer();
    listener(state);
  }

  void removeListener(QueryStateListener<T> listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty && _observerCount == 0) {
      _scheduleGc();
    }
  }

  void onObserverAdded() {
    _observerCount++;
    _cancelGcTimer();
  }

  void onObserverRemoved() {
    _observerCount = (_observerCount - 1).clamp(0, 999999);
    if (_observerCount == 0 && _listeners.isEmpty) {
      _scheduleGc();
    }
  }

  void _scheduleGc() {
    _cancelGcTimer();
    final gcTime = _options.gcTime ?? Duration.zero;
    if (gcTime <= Duration.zero) return;
    _gcTimer = Timer(gcTime, () {
      onGcDue?.call(this);
    });
  }

  void _cancelGcTimer() {
    _gcTimer?.cancel();
    _gcTimer = null;
  }

  bool get isStaleByTime {
    if (_dataUpdatedAt == null) return true;
    final staleTime = _options.staleTime ?? Duration.zero;
    if (staleTime == Duration.zero) return true;
    return DateTime.now().difference(_dataUpdatedAt!) > staleTime;
  }

  bool get hasObservers => _observerCount > 0 || _listeners.isNotEmpty;

  bool get shouldFetch {
    if (!_options.enabled) return false;
    if (_fetchStatus == FetchStatus.fetching) return false;
    if (_status == QueryStatus.pending && _data == null) return true;
    if (_isStale || isStaleByTime) return true;
    return false;
  }

  Future<QueryState<T>> fetch({bool force = false}) async {
    if (!_options.enabled) return state;

    if (_fetchPromise != null) {
      await _fetchPromise;
      if (!force) return state;
    }

    if (!force && !shouldFetch) return state;

    _fetchPromise = _executeFetch();
    try {
      await _fetchPromise;
    } finally {
      _fetchPromise = null;
    }
    return state;
  }

  Future<T> _executeFetch() async {
    _setFetching(true);

    var attempt = _failureCount;
    while (true) {
      try {
        final result = await _options.queryFn();
        _onFetchSuccess(result);
        return result;
      } catch (error, stackTrace) {
        attempt++;
        _failureCount = attempt;
        _failureReason = error;

        if (!_retryResolver.shouldRetry(error, attempt)) {
          _onFetchError(error, stackTrace);
          rethrow;
        }

        final delay = _retryResolver.delayForAttempt(attempt);
        await Future<void>.delayed(delay);
      }
    }
  }

  void _onFetchSuccess(T data) {
    _data = data;
    _error = null;
    _status = QueryStatus.success;
    _dataUpdatedAt = DateTime.now();
    _errorUpdatedAt = null;
    _isStale = false;
    _failureCount = 0;
    _failureReason = null;
    _setFetching(false);
    _notify();
  }

  void _onFetchError(Object error, StackTrace stackTrace) {
    _error = error;
    _status = _data != null ? QueryStatus.success : QueryStatus.error;
    _errorUpdatedAt = DateTime.now();
    _setFetching(false);
    _notify();
  }

  void setData(T data, {bool manual = true}) {
    _data = data;
    _status = QueryStatus.success;
    _dataUpdatedAt = DateTime.now();
    if (manual) _isStale = true;
    _notify();
  }

  void invalidate() {
    _isStale = true;
    _notify();
  }

  void reset() {
    _data = _options.initialData;
    _error = null;
    _status =
        _options.initialData != null ? QueryStatus.success : QueryStatus.pending;
    _fetchStatus = FetchStatus.idle;
    _dataUpdatedAt =
        _options.initialData != null ? DateTime.now() : null;
    _errorUpdatedAt = null;
    _isStale = _options.initialData == null;
    _failureCount = 0;
    _failureReason = null;
    _notify();
  }

  void _setFetching(bool fetching) {
    _fetchStatus = fetching ? FetchStatus.fetching : FetchStatus.idle;
    _notify();
  }

  void _notify() {
    final current = state;
    _scheduler.schedule(() {
      for (final listener in _listeners.toList()) {
        listener(current);
      }
    });
  }

  void dispose() {
    _cancelGcTimer();
    _listeners.clear();
    _fetchPromise = null;
    onGcDue = null;
  }
}
