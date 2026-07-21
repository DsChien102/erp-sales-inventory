import 'package:vet45_iam_domain/domain.dart';

/// Tenant row for the current user's accessible-tenants selector (S1).
///
/// [status] uses domain [TenantLifecycleStatus] (aligned with D-01).
final class AccessibleTenantDto {
  const AccessibleTenantDto({
    required this.tenantId,
    required this.name,
    required this.roleLabel,
    required this.status,
    this.isCurrent = false,
  });

  final String tenantId;
  final String name;

  /// Interim: role code (e.g. owner/staff). FE may localize later.
  final String roleLabel;
  final TenantLifecycleStatus status;
  final bool isCurrent;

  AccessibleTenantDto copyWith({
    String? tenantId,
    String? name,
    String? roleLabel,
    TenantLifecycleStatus? status,
    bool? isCurrent,
  }) {
    return AccessibleTenantDto(
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      roleLabel: roleLabel ?? this.roleLabel,
      status: status ?? this.status,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
