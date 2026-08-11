import 'invitation_summary_dto.dart';

/// Invitation detail (§S6). Never includes token/hash.
final class InvitationDetailDto {
  const InvitationDetailDto({
    required this.invitationId,
    required this.inviteeEmail,
    required this.initialRoleId,
    required this.initialRoleLabel,
    required this.status,
    required this.expiresAt,
    required this.deliveryStatus,
    required this.deliveryCorrelationId,
    required this.version,
    required this.createdAt,
    required this.createdBy,
    this.lastSentAt,
    this.revokedAt,
    this.declinedAt,
  });

  final String invitationId;
  final String inviteeEmail;
  final String initialRoleId;
  final String initialRoleLabel;

  /// Wire: `pending` | `accepted` | `declined` | `revoked` | `expired`.
  final String status;
  final DateTime expiresAt;
  final String deliveryStatus;
  final String deliveryCorrelationId;
  final int version;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? lastSentAt;
  final DateTime? revokedAt;
  final DateTime? declinedAt;

  InvitationSummaryDto toSummary() => InvitationSummaryDto(
        invitationId: invitationId,
        inviteeEmail: inviteeEmail,
        initialRoleId: initialRoleId,
        initialRoleLabel: initialRoleLabel,
        status: status,
        expiresAt: expiresAt,
        deliveryStatus: deliveryStatus,
        deliveryCorrelationId: deliveryCorrelationId,
        version: version,
      );
}
