/// Metrics returned by a single worker tick.
final class MessagingWorkerTickResult {
  const MessagingWorkerTickResult({
    required this.tenantsProcessed,
    required this.rounds,
    required this.durationMs,
    required this.errorsCount,
    required this.hadBacklog,
  });

  final int tenantsProcessed;
  final int rounds;
  final int durationMs;
  final int errorsCount;
  final bool hadBacklog;

  Map<String, Object?> toJson() => {
    'tenantsProcessed': tenantsProcessed,
    'rounds': rounds,
    'durationMs': durationMs,
    'errorsCount': errorsCount,
    'hadBacklog': hadBacklog,
  };
}
