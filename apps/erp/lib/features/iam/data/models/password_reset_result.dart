final class PasswordResetRequestResult {
  const PasswordResetRequestResult({
    required this.operationId,
    required this.maskedEmail,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  final String operationId;
  final String maskedEmail;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;

  factory PasswordResetRequestResult.fromJson(
    Map<String, dynamic> row, {
    String? maskedEmail,
  }) {
    return PasswordResetRequestResult(
      operationId: row['operation_id'] as String,
      maskedEmail: maskedEmail ?? (row['masked_email'] as String?) ?? '***',
      expiresAt: DateTime.parse(row['expires_at'] as String),
      resendAvailableAt: DateTime.parse(row['resend_available_at'] as String),
    );
  }
}

final class PasswordResetVerifyResult {
  const PasswordResetVerifyResult({required this.verified});

  final bool verified;

  factory PasswordResetVerifyResult.fromJson(Map<String, dynamic> row) {
    return PasswordResetVerifyResult(verified: (row['verified'] as bool?) ?? false);
  }
}

final class PasswordResetCompletionResult {
  const PasswordResetCompletionResult({
    required this.currentSessionRotated,
    required this.otherSessionsRevoked,
  });

  final bool currentSessionRotated;
  final bool otherSessionsRevoked;

  factory PasswordResetCompletionResult.fromJson(Map<String, dynamic> row) {
    return PasswordResetCompletionResult(
      currentSessionRotated: (row['current_session_rotated'] as bool?) ?? false,
      otherSessionsRevoked: (row['other_sessions_revoked'] as bool?) ?? true,
    );
  }
}

/// `lan@gmail.com` → `l***@gmail.com`.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) {
    return '***';
  }
  final local = email.substring(0, at);
  final domain = email.substring(at);
  final head = local.substring(0, 1);
  return '$head***$domain';
}
