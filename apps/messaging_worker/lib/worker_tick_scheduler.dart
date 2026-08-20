import 'dart:async';

import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'messaging_worker_loop.dart';
import 'worker_structured_log.dart';
import 'worker_tick_policy.dart';

/// Runs [MessagingWorkerLoop.runOnce] on an adaptive schedule while `--serve` is active.
final class WorkerTickScheduler {
  WorkerTickScheduler({
    required MessagingWorkerLoop loop,
    required WorkerTickPolicy policy,
    ILogger? logger,
  }) : _loop = loop,
       _policy = policy,
       _log = WorkerStructuredLog(logger ?? createWorkerLogger('scheduler'));

  final MessagingWorkerLoop _loop;
  final WorkerTickPolicy _policy;
  final WorkerStructuredLog _log;

  Timer? _trigger;
  var _started = false;
  var _inFlight = false;

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
      // tick_end is logged by MessagingWorkerLoop at INFO.
      if (_started) {
        _scheduleNext(_policy.nextInterval(result));
      }
    } catch (error, stackTrace) {
      _log.severe(
        'tick_error',
        {'error': error.toString()},
        error,
        stackTrace,
      );
      if (_started) {
        _scheduleNext(_policy.activeInterval);
      }
    } finally {
      _inFlight = false;
    }
  }
}
