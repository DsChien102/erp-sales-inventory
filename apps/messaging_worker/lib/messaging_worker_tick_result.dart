/// Metrics returned by a single worker tick.
final class MessagingWorkerTickResult {
  const MessagingWorkerTickResult({
    required this.tenantsProcessed,
    required this.rounds,
    required this.durationMs,
    required this.errorsCount,
    required this.hadBacklog,
    this.tickId = '',
    this.workDiscovered = 0,
    this.partitions = 0,
    this.queuesSucceeded = 0,
    this.queuesSkipped = 0,
    this.queuesUnknown = 0,
    this.hadWorkTrue = 0,
    this.byModule = const {},
    this.byQueue = const {},
    this.discoveryMs = 0,
    this.processMs = 0,
    this.maxPartitionDurationMs = 0,
  });

  final int tenantsProcessed;
  final int rounds;
  final int durationMs;
  final int errorsCount;
  final bool hadBacklog;

  /// Correlation id shared across logs for this tick.
  final String tickId;

  /// Total discovery rows across all rounds.
  final int workDiscovered;

  /// Distinct partition groups processed (last non-empty round max, or total).
  final int partitions;

  final int queuesSucceeded;
  final int queuesSkipped;
  final int queuesUnknown;

  /// Times [Process*] returned `true` (had remaining work in batch).
  final int hadWorkTrue;

  /// Counts keyed by module schema (e.g. `iam`).
  final Map<String, int> byModule;

  /// Counts keyed by `module.queue` (e.g. `iam.outbox`).
  final Map<String, int> byQueue;

  final int discoveryMs;
  final int processMs;
  final int maxPartitionDurationMs;

  Map<String, Object?> toJson() => {
    'event': 'tick_end',
    'tickId': tickId,
    'tenantsProcessed': tenantsProcessed,
    'rounds': rounds,
    'durationMs': durationMs,
    'errorsCount': errorsCount,
    'hadBacklog': hadBacklog,
    'workDiscovered': workDiscovered,
    'partitions': partitions,
    'queuesSucceeded': queuesSucceeded,
    'queuesSkipped': queuesSkipped,
    'queuesUnknown': queuesUnknown,
    'hadWorkTrue': hadWorkTrue,
    'byModule': byModule,
    'byQueue': byQueue,
    'discoveryMs': discoveryMs,
    'processMs': processMs,
    'maxPartitionDurationMs': maxPartitionDurationMs,
  };
}
