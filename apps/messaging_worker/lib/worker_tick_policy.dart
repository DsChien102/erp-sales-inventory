import 'messaging_worker_tick_result.dart';

/// Adaptive tick intervals based on worker backlog activity.
final class WorkerTickPolicy {
  WorkerTickPolicy({
    this.activeInterval = const Duration(seconds: 3),
    this.idleInterval = const Duration(seconds: 15),
    this.maxIdleInterval = const Duration(seconds: 30),
    this.idleTicksBeforeBackoff = 3,
  });

  final Duration activeInterval;
  final Duration idleInterval;
  final Duration maxIdleInterval;
  final int idleTicksBeforeBackoff;

  var _consecutiveIdleTicks = 0;

  Duration nextInterval(MessagingWorkerTickResult result) {
    if (result.hadBacklog) {
      _consecutiveIdleTicks = 0;
      return activeInterval;
    }

    _consecutiveIdleTicks++;
    if (_consecutiveIdleTicks < idleTicksBeforeBackoff) {
      return activeInterval;
    }

    final backoffSteps = _consecutiveIdleTicks - idleTicksBeforeBackoff + 1;
    final idleSeconds = idleInterval.inSeconds * backoffSteps;
    final cappedSeconds = idleSeconds.clamp(
      idleInterval.inSeconds,
      maxIdleInterval.inSeconds,
    );
    return Duration(seconds: cappedSeconds);
  }

  void reset() {
    _consecutiveIdleTicks = 0;
  }
}
