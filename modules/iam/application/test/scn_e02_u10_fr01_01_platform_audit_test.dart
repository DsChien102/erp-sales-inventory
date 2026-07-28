import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _AuditGateway implements IPlatformAdminGateway {
  String? searchQuery;
  PlatformAuditLogStatus? searchStatus;
  String? getId;

  @override
  Future<bool> hasPlatformPermission(String permission) async => true;

  @override
  Future<List<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  }) async =>
      const [];

  @override
  Future<PlatformUserDetailDto> getPlatformUser(String userId) async =>
      throw UnimplementedError();

  @override
  Future<void> sendActivationInvitation(String userId) async {}

  @override
  Future<void> requestPasswordReset(String userId) async {}

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
  }) async {}

  @override
  Future<void> restorePlatformUser(String userId) async {}

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId) async =>
      throw UnimplementedError();

  @override
  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
  }) async {}

  @override
  Future<void> restorePlatformTenant(String tenantId) async {}

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required String idempotencyKey,
  }) async {}

  @override
  Future<List<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    String? query,
    PlatformAuditLogStatus? status,
  }) async {
    searchQuery = query;
    searchStatus = status;
    return [
      PlatformAuditLogSummaryDto(
        id: 'aud-1',
        title: 'Đã tạm ngừng tổ chức',
        actionCode: 'platform.tenant.suspend',
        status: PlatformAuditLogStatus.success,
        actorName: 'Admin',
        actorRole: 'ops',
        targetOrgName: 'Store',
        targetOrgCode: 'TEN-1',
        timestamp: DateTime.utc(2026, 7, 13),
        sourceApp: 'admin',
      ),
    ];
  }

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(
    String auditLogId,
  ) async {
    getId = auditLogId;
    return PlatformAuditLogDetailDto(
      id: auditLogId,
      title: 'Đã tạm ngừng tổ chức',
      actionCode: 'platform.tenant.suspend',
      status: PlatformAuditLogStatus.success,
      statusLabel: 'Thành công',
      actorName: 'Admin',
      actorRole: 'ops',
      targetOrgName: 'Store',
      targetOrgCode: 'TEN-1',
      timestamp: DateTime.utc(2026, 7, 13),
      sourceApp: 'admin',
      correlationId: 'COR-1',
      beforeState: 'active',
      afterState: 'suspended',
    );
  }
}

void main() {
  group('scn_e02_u10_fr01_01 platform audit', () {
    test('audit_search_ok delegates', () async {
      final gateway = _AuditGateway();
      final handler = SearchPlatformAuditLogsQueryHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        SearchPlatformAuditLogsQuery(
          query: 'tạm',
          status: PlatformAuditLogStatus.success,
        ),
      );

      expect(gateway.searchQuery, 'tạm');
      expect(gateway.searchStatus, PlatformAuditLogStatus.success);
      expect(result.single.id, 'aud-1');
    });

    test('audit detail redacted fields present', () async {
      final gateway = _AuditGateway();
      final handler = GetPlatformAuditLogQueryHandler(platformGateway: gateway);

      final result = await handler.handle(
        GetPlatformAuditLogQuery(auditLogId: 'aud-1'),
      );

      expect(gateway.getId, 'aud-1');
      expect(result.correlationId, 'COR-1');
      expect(result.beforeState, isNotEmpty);
      expect(result.afterState, isNotEmpty);
    });
  });
}
