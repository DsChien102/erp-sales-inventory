import 'package:vet45_iam_domain/domain.dart';

/// Resolved TenantContext snapshot for EP-05 switch / bootstrap (S2/S3).
final class TenantContextDto {
  const TenantContextDto({
    required this.status,
    this.tenantId,
    this.tenantName,
    this.roleLabel,
    this.isOwner = false,
    this.permissions = const [],
    this.tenantStatus,
    this.invalidationReason,
    this.blockedErrorCode,
  });

  final TenantContextStatus status;
  final String? tenantId;
  final String? tenantName;

  /// Interim: role code (e.g. store_owner/staff). FE may localize later.
  final String? roleLabel;

  /// Ownership is orthogonal to [roleLabel] (Owner ≠ role).
  final bool isOwner;
  final List<String> permissions;
  final TenantLifecycleStatus? tenantStatus;

  /// Set when [status] is [TenantContextStatus.invalidated] (US-04).
  final TenantContextInvalidationReason? invalidationReason;

  /// APPENDICES §6.4 code for FE blocked state (e.g. TENANT_ACCESS_DENIED).
  final String? blockedErrorCode;

  TenantContextDto copyWith({
    TenantContextStatus? status,
    String? tenantId,
    String? tenantName,
    String? roleLabel,
    bool? isOwner,
    List<String>? permissions,
    TenantLifecycleStatus? tenantStatus,
    TenantContextInvalidationReason? invalidationReason,
    String? blockedErrorCode,
  }) {
    return TenantContextDto(
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      roleLabel: roleLabel ?? this.roleLabel,
      isOwner: isOwner ?? this.isOwner,
      permissions: permissions ?? this.permissions,
      tenantStatus: tenantStatus ?? this.tenantStatus,
      invalidationReason: invalidationReason ?? this.invalidationReason,
      blockedErrorCode: blockedErrorCode ?? this.blockedErrorCode,
    );
  }
}
