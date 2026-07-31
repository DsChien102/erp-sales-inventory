/// Password reset request result (§S14, plan 3.2).
///
/// Locked shape: exposes only operation metadata. Never carries raw reset
/// code, nonce, password, access token or refresh token.
final class PasswordResetRequestResultDto {
  const PasswordResetRequestResultDto({
    required this.operationId,
    required this.maskedEmail,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  final String operationId;
  final String maskedEmail;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
}
