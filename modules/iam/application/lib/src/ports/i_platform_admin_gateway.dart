import 'package:vet45_iam_domain/domain.dart';

import '../dto/onboarding_owner_input.dart';
import '../dto/platform_audit_log_detail_dto.dart';
import '../dto/platform_audit_log_status.dart';
import '../dto/platform_audit_log_summary_dto.dart';
import '../dto/platform_tenant_detail_dto.dart';
import '../dto/platform_tenant_member_dto.dart';
import '../dto/platform_tenant_summary_dto.dart';
import '../dto/platform_user_detail_dto.dart';
import '../dto/platform_user_status.dart';
import '../dto/platform_user_summary_dto.dart';
import '../dto/tenant_onboarding_result_dto.dart';

/// Port for platform-scoped Admin reads/mutations (TH-01 S15/S16).
///
/// Infrastructure implements via Supabase RPCs under `iam.*`.
abstract interface class IPlatformAdminGateway {
  Future<bool> hasPlatformPermission(String permission);

  Future<List<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  });

  Future<PlatformUserDetailDto> getPlatformUser(String userId);

  Future<void> sendActivationInvitation(String userId);

  Future<void> requestPasswordReset(String userId);

  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
  });

  Future<void> restorePlatformUser(String userId);

  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  });

  // ── S16: platform tenants / audit ──────────────────────────

  Future<List<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
  });

  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId);

  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  );

  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
  });

  Future<void> restorePlatformTenant(String tenantId);

  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required String idempotencyKey,
  });

  Future<List<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    String? query,
    PlatformAuditLogStatus? status,
  });

  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(String auditLogId);
}
