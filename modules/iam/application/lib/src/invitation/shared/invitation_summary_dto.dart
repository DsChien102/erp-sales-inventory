/// Invitation list row (§S6). Never includes token/hash.
final class InvitationSummaryDto {
  const InvitationSummaryDto({
    required this.invitationId,
    required this.inviteeEmail,
    required this.initialRoleId,
    required this.initialRoleLabel,
    required this.status,
    required this.expiresAt,
    required this.deliveryStatus,
    required this.deliveryCorrelationId,
    required this.version,
  });

  final String invitationId;
  final String inviteeEmail;
  final String initialRoleId;
  final String initialRoleLabel;

  /// Wire: `pending` | `accepted` | `declined` | `revoked` | `expired`.
  final String status;
  final DateTime expiresAt;

  /// Independent delivery projection: `queued` | `sent` | `failed` | …
  final String deliveryStatus;
  final String deliveryCorrelationId;
  final int version;
}
