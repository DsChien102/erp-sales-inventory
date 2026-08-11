/// Preview returned by InspectInvitationTokenQuery (§S8).
///
/// Never returned for invalid tokens (no account-existence leak).
final class InvitationTokenInspectionDto {
  const InvitationTokenInspectionDto({
    required this.tenantId,
    required this.tenantName,
    required this.inviteeEmail,
    required this.initialRoleId,
    required this.initialRoleLabel,
    required this.expiresAt,
    required this.accountExists,
  });

  final String tenantId;
  final String tenantName;
  final String inviteeEmail;
  final String initialRoleId;
  final String initialRoleLabel;
  final DateTime expiresAt;
  final bool accountExists;
}
