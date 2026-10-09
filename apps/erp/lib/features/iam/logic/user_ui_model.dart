enum MemberStatus {
  active,
  suspended,
  removed,
}

/// Invitation lifecycle as rendered in the UI.
///
/// [pending] / [expiring] / [failed] describe an invitation that is still
/// live; the rest are terminal and mirror the wire values documented on
/// `InvitationSummaryDto` (`accepted` | `declined` | `revoked` | `expired`).
enum InvitationStatus {
  pending,
  expiring,
  failed,
  accepted,
  declined,
  revoked,
  expired,
}

final class MemberUiModel {
  final String id;
  final String name;
  final String email;
  final String role;

  /// Mã vai trò (`store_owner`, `staff`, `accountant`, `warehouse`).
  final String roleCode;
  final MemberStatus status;
  final bool isOwner;
  final String identityText;
  final String joinedDate;
  final String lastActiveDate;
  final String dataVersion;
  final String? suspendedAt;
  final String? suspendedBy;
  final String? removedAt;
  final String? removedBy;
  final String? previousRole;

  const MemberUiModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roleCode = '',
    required this.status,
    this.isOwner = false,
    this.identityText = 'Thành viên',
    this.joinedDate = '',
    this.lastActiveDate = '',
    this.dataVersion = '',
    this.suspendedAt,
    this.suspendedBy,
    this.removedAt,
    this.removedBy,
    this.previousRole,
  });
}

final class InvitationUiModel {
  final String id;
  final String email;
  final String role;
  final String statusDetail;
  final InvitationStatus status;
  final String deliveryStatus;
  final DateTime? expiresAt;
  final int version;

  const InvitationUiModel({
    required this.id,
    required this.email,
    required this.role,
    required this.statusDetail,
    required this.status,
    this.deliveryStatus = '',
    this.expiresAt,
    this.version = 0,
  });
}
