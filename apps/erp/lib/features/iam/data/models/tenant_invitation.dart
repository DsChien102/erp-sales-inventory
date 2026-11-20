import '../iam_json.dart';

/// Dòng danh sách lời mời. Không chứa token.
final class TenantInvitation {
  const TenantInvitation({
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
  final String deliveryStatus;
  final String deliveryCorrelationId;
  final int version;

  factory TenantInvitation.fromJson(Map<String, dynamic> row) {
    return TenantInvitation(
      invitationId: row['invitation_id'] as String,
      inviteeEmail: row['invitee_email'] as String,
      initialRoleId: row['initial_role_id'] as String,
      initialRoleLabel: (row['initial_role_label'] as String?) ?? '',
      status: row['status'] as String,
      expiresAt: iamTimestamp(row['expires_at'])!,
      deliveryStatus: (row['delivery_status'] as String?) ?? 'unknown',
      deliveryCorrelationId: (row['delivery_correlation_id'] as String?) ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Chi tiết lời mời. Không chứa token.
final class TenantInvitationDetail {
  const TenantInvitationDetail({
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

  factory TenantInvitationDetail.fromJson(
    Map<String, dynamic> row, {
    String defaultDeliveryStatus = 'queued',
  }) {
    return TenantInvitationDetail(
      invitationId: row['invitation_id'] as String,
      inviteeEmail: row['invitee_email'] as String,
      initialRoleId: row['initial_role_id'] as String,
      initialRoleLabel: (row['initial_role_label'] as String?) ?? '',
      status: row['status'] as String,
      expiresAt: iamTimestamp(row['expires_at'])!,
      deliveryStatus: (row['delivery_status'] as String?) ?? defaultDeliveryStatus,
      deliveryCorrelationId: (row['delivery_correlation_id'] as String?) ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
      createdAt: iamTimestamp(row['created_at'])!,
      createdBy: (row['created_by'] as String?) ?? '',
      lastSentAt: iamTimestamp(row['last_sent_at']),
      revokedAt: iamTimestamp(row['revoked_at']),
      declinedAt: iamTimestamp(row['declined_at']),
    );
  }

  TenantInvitation toSummary() => TenantInvitation(
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

final class AssignableInvitationRole {
  const AssignableInvitationRole({required this.roleId, required this.label});

  final String roleId;
  final String label;

  factory AssignableInvitationRole.fromJson(Map<String, dynamic> row) {
    final roleId = row['role_id'];
    final label = row['label'];
    return AssignableInvitationRole(
      roleId: roleId == null ? '' : roleId.toString(),
      label: label == null ? '' : label.toString(),
    );
  }
}

// TODO(P9): xoá typedef khi cubit / widget không còn tên DTO cũ.
typedef InvitationSummaryDto = TenantInvitation;
typedef InvitationDetailDto = TenantInvitationDetail;
typedef AssignableRoleOptionDto = AssignableInvitationRole;
