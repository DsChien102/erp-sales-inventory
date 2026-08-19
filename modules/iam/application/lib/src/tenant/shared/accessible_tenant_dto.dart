import 'package:vet45_iam_domain/domain.dart';

/// Tenant row for the current user's accessible-tenants selector (S1).
///
/// [status] uses domain [TenantLifecycleStatus] (aligned with D-01).
/// [isSelectable] is true only when [status] is [TenantLifecycleStatus.active].
/// [isOwner] is separate from [roleLabel]; owner is not an operational role.
final class AccessibleTenantDto {
  const AccessibleTenantDto({
    required this.tenantId,
    required this.name,
    required this.roleLabel,
    required this.status,
    this.isOwner = false,
    this.isCurrent = false,
  });

  final String tenantId;
  final String name;

  /// Operational role code or label (e.g. store_owner/staff).
  final String roleLabel;
  final TenantLifecycleStatus status;
  final bool isOwner;
  final bool isCurrent;

  /// Selectable in switcher only when tenant lifecycle is active.
  bool get isSelectable => status == TenantLifecycleStatus.active;

  AccessibleTenantDto copyWith({
    String? tenantId,
    String? name,
    String? roleLabel,
    TenantLifecycleStatus? status,
    bool? isOwner,
    bool? isCurrent,
  }) {
    return AccessibleTenantDto(
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      roleLabel: roleLabel ?? this.roleLabel,
      status: status ?? this.status,
      isOwner: isOwner ?? this.isOwner,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
