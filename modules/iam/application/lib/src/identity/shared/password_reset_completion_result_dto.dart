/// Password reset completion result (§S14 / OQ-09).
///
/// Never carries credentials or session tokens — only session-policy outcomes.
final class PasswordResetCompletionResultDto {
  const PasswordResetCompletionResultDto({
    required this.currentSessionRotated,
    required this.otherSessionsRevoked,
  });

  /// Current authenticated session remains valid after rotation.
  final bool currentSessionRotated;

  /// Other sessions for the same identity were revoked.
  final bool otherSessionsRevoked;
}
