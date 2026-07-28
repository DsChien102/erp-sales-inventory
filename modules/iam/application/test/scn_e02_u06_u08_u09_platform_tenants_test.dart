import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _RecordingGateway implements IPlatformAdminGateway {
  String? searchQuery;
  TenantLifecycleStatus? searchStatus;
  String? getTenantId;
  String? listMembersTenantId;
  String? suspendTenantId;
  String? suspendReason;
  String? restoreTenantId;
  String? transferTenantId;
  String? transferNewOwner;
  String? transferKey;

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
  }) async {
    searchQuery = query;
    searchStatus = status;
    return [
      PlatformTenantSummaryDto(
        tenantId: 't-1',
        name: 'Store',
        code: 'TEN-1',
        status: TenantLifecycleStatus.active,
        createdAt: DateTime.utc(2026, 1, 1),
        memberCount: 2,
      ),
    ];
  }

  @override
  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId) async {
    getTenantId = tenantId;
    return PlatformTenantDetailDto(
      tenantId: tenantId,
      name: 'Store',
      code: 'TEN-1',
      status: TenantLifecycleStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      ownerUserId: 'u-owner',
      members: const [
        PlatformTenantMemberDto(
          userId: 'u-owner',
          fullName: 'Owner',
          email: 'o@x.com',
          roleLabel: 'owner',
          isOwner: true,
        ),
      ],
    );
  }

  @override
  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  ) async {
    listMembersTenantId = tenantId;
    return const [
      PlatformTenantMemberDto(
        userId: 'u-owner',
        fullName: 'Owner',
        email: 'o@x.com',
        roleLabel: 'owner',
        isOwner: true,
      ),
    ];
  }

  @override
  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
  }) async {
    suspendTenantId = tenantId;
    suspendReason = reason;
  }

  @override
  Future<void> restorePlatformTenant(String tenantId) async {
    restoreTenantId = tenantId;
  }

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required String idempotencyKey,
  }) async {
    transferTenantId = tenantId;
    transferNewOwner = newOwnerUserId;
    transferKey = idempotencyKey;
  }

  @override
  Future<List<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    String? query,
    PlatformAuditLogStatus? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(
    String auditLogId,
  ) async =>
      throw UnimplementedError();
}

void main() {
  group('scn_e02_u08_fr01_01 platform tenants read', () {
    test('tenants_search_ok delegates', () async {
      final gateway = _RecordingGateway();
      final handler = SearchPlatformTenantsQueryHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        SearchPlatformTenantsQuery(
          query: 'Store',
          status: TenantLifecycleStatus.active,
        ),
      );

      expect(gateway.searchQuery, 'Store');
      expect(gateway.searchStatus, TenantLifecycleStatus.active);
      expect(result.single.tenantId, 't-1');
    });

    test('tenant_detail_ok delegates', () async {
      final gateway = _RecordingGateway();
      final handler = GetPlatformTenantQueryHandler(platformGateway: gateway);

      final result = await handler.handle(
        GetPlatformTenantQuery(tenantId: 't-1'),
      );

      expect(gateway.getTenantId, 't-1');
      expect(result.members, hasLength(1));
    });

    test('list members delegates', () async {
      final gateway = _RecordingGateway();
      final handler = ListPlatformTenantMembersQueryHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        ListPlatformTenantMembersQuery(tenantId: 't-1'),
      );

      expect(gateway.listMembersTenantId, 't-1');
      expect(result.single.isOwner, isTrue);
    });
  });

  group('scn_e02_u06_fr01_01 platform tenant lifecycle', () {
    test('tenant_suspend_ok requires reason and delegates', () async {
      final gateway = _RecordingGateway();
      final validator = SuspendPlatformTenantCommandValidator();
      final handler = SuspendPlatformTenantCommandHandler(
        platformGateway: gateway,
      );

      await validator.validate(
        SuspendPlatformTenantCommand(tenantId: 't-1', reason: 'risk'),
      );
      await handler.handle(
        SuspendPlatformTenantCommand(tenantId: 't-1', reason: 'risk'),
      );

      expect(gateway.suspendTenantId, 't-1');
      expect(gateway.suspendReason, 'risk');
    });

    test('suspend validator rejects empty reason', () async {
      final validator = SuspendPlatformTenantCommandValidator();
      expect(
        () => validator.validate(
          SuspendPlatformTenantCommand(tenantId: 't-1', reason: ' '),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('tenant_restore_ok delegates', () async {
      final gateway = _RecordingGateway();
      final handler = RestorePlatformTenantCommandHandler(
        platformGateway: gateway,
      );

      await handler.handle(RestorePlatformTenantCommand(tenantId: 't-sus'));

      expect(gateway.restoreTenantId, 't-sus');
    });
  });

  group('scn_e02_u09_fr01_01 ownership transfer', () {
    test('ownership_transfer_ok delegates', () async {
      final gateway = _RecordingGateway();
      final validator = TransferPlatformTenantOwnershipCommandValidator();
      final handler = TransferPlatformTenantOwnershipCommandHandler(
        platformGateway: gateway,
      );

      final command = TransferPlatformTenantOwnershipCommand(
        tenantId: 't-1',
        newOwnerUserId: 'u-2',
        idempotencyKey: 'key-1',
      );
      await validator.validate(command);
      await handler.handle(command);

      expect(gateway.transferTenantId, 't-1');
      expect(gateway.transferNewOwner, 'u-2');
      expect(gateway.transferKey, 'key-1');
    });

    test('transfer validator rejects empty idempotency key', () async {
      final validator = TransferPlatformTenantOwnershipCommandValidator();
      expect(
        () => validator.validate(
          TransferPlatformTenantOwnershipCommand(
            tenantId: 't-1',
            newOwnerUserId: 'u-2',
            idempotencyKey: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
