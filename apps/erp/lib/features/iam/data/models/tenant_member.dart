/// Trạng thái vòng đời của một thành viên trong tổ chức.
enum MembershipStatus { active, inactive, removed }

/// Dòng danh sách thành viên (`list_tenant_members`).
final class TenantMember {
  const TenantMember({
    required this.membershipId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.roleId,
    required this.roleLabel,
    required this.isOwner,
    required this.status,
    required this.joinedAt,
    required this.version,
  });

  final String membershipId;
  final String userId;
  final String displayName;
  final String email;
  final String roleId;
  final String roleLabel;
  final bool isOwner;

  /// Wire: `active` | `inactive` | `removed`.
  final String status;
  final DateTime joinedAt;
  final int version;

  factory TenantMember.fromJson(Map<String, dynamic> row) {
    return TenantMember(
      membershipId: row['membership_id'] as String? ?? row['user_id'] as String,
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      roleId: row['role_id'] as String? ?? row['role'] as String? ?? '',
      roleLabel: row['role_label'] as String? ?? row['role'] as String? ?? '',
      isOwner: row['is_owner'] as bool? ?? false,
      status: row['status'] as String? ?? 'active',
      joinedAt: DateTime.parse(
        (row['joined_at'] as String?) ?? (row['created_at'] as String),
      ),
      version: (row['version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Chi tiết thành viên (`get_tenant_member` và các RPC vòng đời).
final class TenantMemberDetail {
  const TenantMemberDetail({
    required this.membershipId,
    required this.tenantId,
    required this.userId,
    this.displayName,
    this.email,
    required this.role,
    this.roleLabel,
    required this.isOwner,
    required this.isSoleOwner,
    required this.status,
    required this.version,
    required this.joinedAt,
    this.lastActivityAt,
    this.statusChangedAt,
    this.removedAt,
  });

  final String membershipId;
  final String tenantId;
  final String userId;
  final String? displayName;
  final String? email;
  final String role;
  final String? roleLabel;
  final bool isOwner;
  final bool isSoleOwner;
  final MembershipStatus status;
  final int version;
  final DateTime joinedAt;
  final DateTime? lastActivityAt;
  final DateTime? statusChangedAt;
  final DateTime? removedAt;

  factory TenantMemberDetail.fromJson(Map<String, dynamic> row) {
    return TenantMemberDetail(
      membershipId: row['membership_id'] as String,
      tenantId: row['tenant_id'] as String,
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String?,
      email: row['email'] as String?,
      role: row['role'] as String,
      roleLabel: row['role_label'] as String?,
      isOwner: row['is_owner'] as bool? ?? false,
      isSoleOwner: row['is_sole_owner'] as bool? ?? false,
      status: _membershipStatus(row['status'] as String?),
      version: (row['version'] as num?)?.toInt() ?? 1,
      joinedAt: DateTime.parse(row['joined_at'] as String),
      lastActivityAt: row['last_activity_at'] == null
          ? null
          : DateTime.parse(row['last_activity_at'] as String),
      statusChangedAt: row['status_changed_at'] == null
          ? null
          : DateTime.parse(row['status_changed_at'] as String),
      removedAt: row['removed_at'] == null
          ? null
          : DateTime.parse(row['removed_at'] as String),
    );
  }
}

MembershipStatus _membershipStatus(String? raw) {
  return switch (raw) {
    'inactive' => MembershipStatus.inactive,
    'removed' => MembershipStatus.removed,
    _ => MembershipStatus.active,
  };
}

// TODO(P9): xoá typedef khi cubit / widget không còn tên DTO cũ.
typedef TenantMemberDto = TenantMember;
typedef TenantMemberDetailDto = TenantMemberDetail;
