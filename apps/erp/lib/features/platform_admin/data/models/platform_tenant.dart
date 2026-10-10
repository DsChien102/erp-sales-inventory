import 'package:erp/core/session/models/tenant_context.dart';

/// Dòng danh sách tổ chức (`search_platform_tenants`).
final class PlatformTenantSummary {
  const PlatformTenantSummary({
    required this.tenantId,
    required this.name,
    required this.code,
    required this.status,
    required this.createdAt,
    this.ownerName,
    this.ownerEmail,
    this.memberCount = 0,
  });

  final String tenantId;
  final String name;
  final String code;
  final TenantStatus status;
  final DateTime createdAt;
  final String? ownerName;
  final String? ownerEmail;
  final int memberCount;

  factory PlatformTenantSummary.fromJson(Map<String, dynamic> row) {
    return PlatformTenantSummary(
      tenantId: row['tenant_id'] as String,
      name: row['name'] as String? ?? '',
      code: row['code'] as String? ?? '',
      status: tenantStatusFromWire(row['status'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
      ownerName: _blankToNull(row['owner_name']),
      ownerEmail: _blankToNull(row['owner_email']),
      memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Chi tiết tổ chức (`get_platform_tenant`). [version] chỉ để gửi `p_expected_version`.
final class PlatformTenantDetail {
  const PlatformTenantDetail({
    required this.tenantId,
    required this.name,
    required this.code,
    required this.status,
    required this.createdAt,
    required this.version,
    this.ownerUserId,
    this.ownerName,
    this.ownerEmail,
    this.ownerRoleLabel,
    this.lastActivityAt,
    this.suspendedAt,
    this.suspendedBy,
    this.suspendReason,
    this.closedAt,
    this.closedBy,
    this.closeReason,
    this.members = const [],
  });

  final String tenantId;
  final String name;
  final String code;
  final TenantStatus status;
  final DateTime createdAt;
  final int version;
  final String? ownerUserId;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerRoleLabel;
  final DateTime? lastActivityAt;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final String? suspendReason;
  final DateTime? closedAt;
  final String? closedBy;
  final String? closeReason;
  final List<PlatformTenantMember> members;

  factory PlatformTenantDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['members'];
    final byUser = <String, PlatformTenantMember>{};
    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final member = PlatformTenantMember.fromJson(Map<String, dynamic>.from(item));
        byUser.putIfAbsent(member.userId, () => member);
      }
    }
    return PlatformTenantDetail(
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: tenantStatusFromWire(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      ownerUserId: json['owner_user_id'] as String?,
      ownerName: _blankToNull(json['owner_name']),
      ownerEmail: _blankToNull(json['owner_email']),
      ownerRoleLabel: _blankToNull(json['owner_role']),
      lastActivityAt: _timestamp(json['last_activity_at']),
      suspendedAt: _timestamp(json['suspended_at']),
      suspendedBy: _blankToNull(json['suspended_by']),
      suspendReason: _blankToNull(json['suspend_reason']),
      closedAt: _timestamp(json['closed_at']),
      closedBy: _blankToNull(json['closed_by']),
      closeReason: _blankToNull(json['close_reason']),
      members: byUser.values.toList(growable: false),
    );
  }
}

/// Thành viên đang hoạt động (`list_platform_tenant_members`, hoặc `members` của chi tiết).
final class PlatformTenantMember {
  const PlatformTenantMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.roleLabel,
    required this.isOwner,
  });

  final String userId;
  final String fullName;
  final String email;
  final String roleLabel;
  final bool isOwner;

  factory PlatformTenantMember.fromJson(Map<String, dynamic> row) {
    return PlatformTenantMember(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      roleLabel: row['role_label'] as String? ?? row['role'] as String? ?? '',
      isOwner: row['is_owner'] as bool? ?? false,
    );
  }
}

String? _blankToNull(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

DateTime? _timestamp(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toUtc();
}
