import 'package:messaging_worker/messaging_worker_tick_result.dart';
import 'package:messaging_worker/worker_tick_policy.dart';
import 'package:test/test.dart';

MessagingWorkerTickResult _result({required bool hadBacklog}) {
  return MessagingWorkerTickResult(
    tenantsProcessed: hadBacklog ? 1 : 0,
    rounds: hadBacklog ? 1 : 0,
    durationMs: 1,
    errorsCount: 0,
    hadBacklog: hadBacklog,
  );
}

void main() {
  group('WorkerTickPolicy', () {
    test('returns active interval when backlog was processed', () {
      final policy = WorkerTickPolicy(
        activeInterval: const Duration(seconds: 3),
        idleInterval: const Duration(seconds: 15),
        maxIdleInterval: const Duration(seconds: 30),
      );

      expect(policy.nextInterval(_result(hadBacklog: true)), const Duration(seconds: 3));
      expect(policy.nextInterval(_result(hadBacklog: false)), const Duration(seconds: 3));
      expect(policy.nextInterval(_result(hadBacklog: true)), const Duration(seconds: 3));
    });

    test('backs off after consecutive idle ticks', () {
      final policy = WorkerTickPolicy(
        activeInterval: const Duration(seconds: 3),
        idleInterval: const Duration(seconds: 15),
        maxIdleInterval: const Duration(seconds: 30),
        idleTicksBeforeBackoff: 3,
      );

      expect(policy.nextInterval(_result(hadBacklog: false)), const Duration(seconds: 3));
      expect(policy.nextInterval(_result(hadBacklog: false)), const Duration(seconds: 3));
      expect(policy.nextInterval(_result(hadBacklog: false)), const Duration(seconds: 15));
      expect(policy.nextInterval(_result(hadBacklog: false)), const Duration(seconds: 30));
      expect(policy.nextInterval(_result(hadBacklog: false)), const Duration(seconds: 30));
    });

    test('resets to active interval after backlog returns', () {
      final policy = WorkerTickPolicy(
        activeInterval: const Duration(seconds: 3),
        idleInterval: const Duration(seconds: 15),
        maxIdleInterval: const Duration(seconds: 30),
        idleTicksBeforeBackoff: 3,
      );

      for (var i = 0; i < 4; i++) {
        policy.nextInterval(_result(hadBacklog: false));
      }

      expect(policy.nextInterval(_result(hadBacklog: true)), const Duration(seconds: 3));
    });
  });
}
