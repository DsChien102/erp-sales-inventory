/// Password-reset operation snapshot (never includes code / credentials).
final class PasswordResetOperationDto {
  const PasswordResetOperationDto({
    required this.operationId,
    required this.maskedEmail,
    this.expiresAt,
    this.resendAfterSeconds,
  });

  final String operationId;
  final String maskedEmail;
  final DateTime? expiresAt;
  final int? resendAfterSeconds;
}
