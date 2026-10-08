import 'package:vet45_iam_domain/domain.dart';

import '../iam_json.dart';

/// Mức sẵn sàng tổ chức (`get_tenant_readiness`). Giữ đến 2-B2 bỏ readiness.
final class TenantReadiness {
  const TenantReadiness({
    required this.tenantId,
    required this.status,
    required this.blockers,
    required this.warnings,
    required this.evaluatedAt,
    required this.tenantVersion,
    required this.canActivate,
  });

  final String tenantId;
  final TenantLifecycleStatus status;
  final List<String> blockers;
  final List<String> warnings;
  final DateTime evaluatedAt;
  final int tenantVersion;
  final bool canActivate;

  factory TenantReadiness.fromJson(Map<String, dynamic> row) {
    return TenantReadiness(
      tenantId: row['tenant_id'] as String,
      status: _lifecycle(row['status'] as String?),
      blockers: iamStringList(row['blockers']),
      warnings: iamStringList(row['warnings']),
      evaluatedAt: DateTime.parse(row['evaluated_at'] as String),
      tenantVersion: (row['tenant_version'] as num?)?.toInt() ?? 1,
      canActivate: row['can_activate'] as bool? ?? false,
    );
  }
}

TenantLifecycleStatus _lifecycle(String? raw) {
  return switch (raw) {
    'provisioning' => TenantLifecycleStatus.provisioning,
    'suspended' => TenantLifecycleStatus.suspended,
    'closed' => TenantLifecycleStatus.closed,
    _ => TenantLifecycleStatus.active,
  };
}

// TODO(P9): xoá typedef khi cubit không còn tên DTO cũ.
typedef TenantReadinessDto = TenantReadiness;
