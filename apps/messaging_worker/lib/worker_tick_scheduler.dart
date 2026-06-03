import 'dart:async';
import 'dart:convert';

import 'messaging_worker_loop.dart';
import 'worker_tick_policy.dart';

/// Runs [MessagingWorkerLoop.runOnce] on an adaptive schedule while `--serve` is active.
final class WorkerTickScheduler {
  WorkerTickScheduler({
    required MessagingWorkerLoop loop,
    required WorkerTickPolicy policy,
    void Function(String message)? log,
  }) : _loop = loop,
       _policy = policy,
       _log = log ?? _defaultLog;

  final MessagingWorkerLoop _loop;
  final WorkerTickPolicy _policy;
  final void Function(String message) _log;

  Timer? _trigger;
  var _started = false;
  var _inFlight = false;

  static void _defaultLog(String message) {
    // ignore: avoid_print
    print(message);
  }

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _policy.reset();
    _scheduleNext(_policy.activeInterval);
  }

  void stop() {
    _started = false;
    _trigger?.cancel();
    _trigger = null;
    _inFlight = false;
    _policy.reset();
  }

  void _scheduleNext(Duration interval) {
    _trigger?.cancel();
    if (!_started) {
      return;
    }
    _trigger = Timer(interval, _enqueueTick);
  }

  void _enqueueTick() {
    if (!_started) {
      return;
    }
    if (_inFlight) {
      _scheduleNext(_policy.activeInterval);
      return;
    }

    _inFlight = true;
    unawaited(_runTick());
  }

  Future<void> _runTick() async {
    try {
      final result = await _loop.runOnce();
      _log('tick ${jsonEncode(result.toJson())}');
      if (_started) {
        _scheduleNext(_policy.nextInterval(result));
      }
    } catch (error, stackTrace) {
      _log('tick error error=$error stack=$stackTrace');
      if (_started) {
        _scheduleNext(_policy.activeInterval);
      }
    } finally {
      _inFlight = false;
    }
  }
}
