final class AutoDeliveryResultDto {
  const AutoDeliveryResultDto({
    required this.started, required this.skipped, this.reason,
  });

  final bool started;
  final bool skipped;
  final String? reason;
}
