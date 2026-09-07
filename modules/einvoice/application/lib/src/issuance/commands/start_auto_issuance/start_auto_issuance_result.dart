final class AutoIssuanceResultDto {
  const AutoIssuanceResultDto({
    required this.started,
    this.skipped = false,
    this.processId,
    this.attemptId,
    this.status,
    this.reason,
  });

  final bool started;
  final bool skipped;
  final String? processId;
  final String? attemptId;
  final String? status;
  final String? reason;
}
