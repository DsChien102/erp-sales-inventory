import 'package:vet45_iam_domain/domain.dart';

import '../shared/cursor_page_dto.dart';
import '../platform/queries/get_platform_audit_log/platform_audit_log_detail_dto.dart';
import '../platform/shared/platform_audit_log_summary_dto.dart';
import '../platform/queries/get_platform_tenant/platform_tenant_detail_dto.dart';
import '../platform/shared/platform_tenant_member_dto.dart';
import '../platform/shared/platform_tenant_summary_dto.dart';
import '../platform/shared/platform_user_detail_dto.dart';
import '../platform/shared/platform_user_status.dart';
import '../platform/shared/platform_user_summary_dto.dart';
import '../platform/shared/tenant_onboarding_result_dto.dart';

/// Port for platform-scoped Admin reads/mutations (TH-01 S15/S16).
///
/// Infrastructure implements via Supabase RPCs under `iam.*`.
abstract interface class IPlatformAdminGateway {
  Future<bool> hasPlatformPermission(String permission);

  Future<CursorPageDto<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
    String? cursor,
    int limit = 20,
  });

  Future<PlatformUserDetailDto> getPlatformUser(String userId);

  Future<void> sendActivationInvitation({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> requestPasswordReset({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> restorePlatformUser({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required bool isNewUser,
    required String organizationName,
    required String idempotencyKey,
    String? organizationDisplayName,
    String? contactEmail,
    String? contactPhone,
    String? contactAddressText,
    String? provinceCode,
    String? communeCode,
    String? legalName,
    String? taxCode,
    String? legalEntityType,
    String? registeredAddressText,
    String? ownerUserId,
    String? ownerEmail,
    String? ownerGivenName,
    String? ownerFamilyName,
    String? ownerPhone,
    String? correlationId,
  });

  /// Re-assign owner on a provisioning tenant with no active owner membership.
  Future<TenantOnboardingResultDto> reinviteProvisioningOwner({
    required String tenantId,
    required bool isNewUser,
    required String idempotencyKey,
    String? ownerUserId,
    String? ownerEmail,
    String? ownerGivenName,
    String? ownerFamilyName,
    String? ownerPhone,
    String? correlationId,
  });

  // ── S16: platform tenants / audit ──────────────────────────

  Future<CursorPageDto<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
    String? readinessState,
    String? warningCode,
    String? cursor,
    int limit = 20,
  });

  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId);

  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  );

  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> restorePlatformTenant({
    required String tenantId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> closePlatformTenant({
    required String tenantId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<CursorPageDto<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    DateTime? fromUtc,
    DateTime? toUtc,
    String? actorUserId,
    String? targetType,
    String? targetId,
    String? action,
    String? result,
    String? source,
    String? correlationId,
    String? cursor,
    int limit = 20,
  });

  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(String auditLogId);
}
