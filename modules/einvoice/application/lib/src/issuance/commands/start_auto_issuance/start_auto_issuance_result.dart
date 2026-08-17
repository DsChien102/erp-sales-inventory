final class AutoIssuanceResultDto {
  const AutoIssuanceResultDto({
    required this.started, required this.skipped, this.reason,
  });

  final bool started;
  final bool skipped;
  final String? reason;
}
