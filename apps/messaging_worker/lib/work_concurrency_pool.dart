import 'dart:async';

/// Limits how many partition groups run concurrently inside one worker tick.
final class WorkConcurrencyPool {
  WorkConcurrencyPool(this._maxConcurrency);

  final int _maxConcurrency;
  int _active = 0;
  final _waiters = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();
    try {
      return await task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_active < _maxConcurrency) {
      _active++;
      return;
    }

    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
      return;
    }

    _active--;
  }
}
