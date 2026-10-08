/// UI-facing failure mapped from IAM application errors.
final class IamUiFailure {
  const IamUiFailure({
    required this.code,
    required this.message,
    this.retryable = false,
    this.requiresReload = false,
    this.requiresStepUp = false,
  });

  final String code;
  final String message;
  final bool retryable;
  final bool requiresReload;
  final bool requiresStepUp;
}
