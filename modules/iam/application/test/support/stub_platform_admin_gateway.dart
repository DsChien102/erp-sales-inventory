import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

/// Default [IPlatformAdminGateway] stub — override only methods under test.
base class StubPlatformAdminGateway implements IPlatformAdminGateway {
  @override
  Future<bool> hasPlatformPermission(String permission) async => true;

  @override
  Future<CursorPageDto<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
    String? cursor,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<PlatformUserDetailDto> getPlatformUser(String userId) async => throw UnimplementedError();

  @override
  Future<void> sendActivationInvitation({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
  Future<void> restorePlatformUser({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
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
    String? registeredAddressText,
    String? ownerUserId,
    String? ownerEmail,
    String? ownerGivenName,
    String? ownerFamilyName,
    String? ownerPhone,
    String? correlationId,
  }) async => throw UnimplementedError();

  @override
  Future<TenantOnboardingOperationDto?> getTenantOnboardingOperation(
    String operationId,
  ) async => throw UnimplementedError();

  @override
  Future<TenantOnboardingOperationDto> retryTenantOnboardingOperation({
    required String operationId,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
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
  }) async => throw UnimplementedError();

  @override
  Future<CursorPageDto<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
    String? readinessState,
    String? warningCode,
    String? cursor,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId) async =>
      throw UnimplementedError();

  @override
  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  ) async => throw UnimplementedError();

  @override
  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
  Future<void> restorePlatformTenant({
    required String tenantId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
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
  }) async => throw UnimplementedError();

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(
    String auditLogId,
  ) async => throw UnimplementedError();
}
