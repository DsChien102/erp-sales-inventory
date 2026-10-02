import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/stub_platform_admin_gateway.dart';

final class _RecordingGateway extends StubPlatformAdminGateway {
  String? searchQuery;
  TenantLifecycleStatus? searchStatus;
  String? suspendTenantId;
  String? suspendReason;
  String? restoreTenantId;
  String? closeTenantId;
  String? closeReason;
  String? closeKey;
  String? transferTenantId;
  String? transferNewOwner;
  String? transferKey;
  int? lastExpectedVersion;

  @override
  Future<CursorPageDto<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
    String? readinessState,
    String? warningCode,
    String? cursor,
    int limit = 20,
  }) async {
    searchQuery = query;
    searchStatus = status;
    return CursorPageDto(
      items: [
        PlatformTenantSummaryDto(
          tenantId: 't-1',
          name: 'Store',
          code: 'TEN-1',
          status: TenantLifecycleStatus.active,
          createdAt: DateTime.utc(2026, 1, 1),
          memberCount: 2,
          readinessState: readinessState,
          warningCode: warningCode,
        ),
      ],
    );
  }

  @override
  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId) async {
    return PlatformTenantDetailDto(
      tenantId: tenantId,
      name: 'Store',
      code: 'TEN-1',
      status: TenantLifecycleStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      version: 2,
    );
  }

  @override
  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    suspendTenantId = tenantId;
    suspendReason = reason;
    lastExpectedVersion = expectedVersion;
  }

  @override
  Future<void> restorePlatformTenant({
    required String tenantId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    restoreTenantId = tenantId;
    lastExpectedVersion = expectedVersion;
  }

  @override
  Future<void> closePlatformTenant({
    required String tenantId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    closeTenantId = tenantId;
    closeReason = reason;
    closeKey = idempotencyKey;
    lastExpectedVersion = expectedVersion;
  }

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    transferTenantId = tenantId;
    transferNewOwner = newOwnerUserId;
    transferKey = idempotencyKey;
    lastExpectedVersion = expectedVersion;
  }
}

void main() {
  group('scn_e02 platform tenants', () {
    test('search returns cursor page', () async {
      final gateway = _RecordingGateway();
      final page = await SearchPlatformTenantsQueryHandler(
        platformGateway: gateway,
      ).handle(SearchPlatformTenantsQuery(query: 'Store'));
      expect(gateway.searchQuery, 'Store');
      expect(page.items, hasLength(1));
    });

    test('suspend/restore/transfer pass version + idempotencyKey', () async {
      final gateway = _RecordingGateway();
      await SuspendPlatformTenantCommandHandler(platformGateway: gateway).handle(
        SuspendPlatformTenantCommand(
          tenantId: 't-1',
          reason: 'abuse',
          expectedVersion: 2,
          idempotencyKey: 'k1',
        ),
      );
      await RestorePlatformTenantCommandHandler(platformGateway: gateway).handle(
        RestorePlatformTenantCommand(
          tenantId: 't-1',
          expectedVersion: 3,
          idempotencyKey: 'k2',
        ),
      );
      await TransferPlatformTenantOwnershipCommandHandler(
        platformGateway: gateway,
      ).handle(
        TransferPlatformTenantOwnershipCommand(
          tenantId: 't-1',
          newOwnerUserId: 'u-2',
          expectedVersion: 4,
          idempotencyKey: 'k3',
        ),
      );
      expect(gateway.suspendTenantId, 't-1');
      expect(gateway.restoreTenantId, 't-1');
      expect(gateway.transferNewOwner, 'u-2');
      expect(gateway.transferKey, 'k3');
      expect(gateway.lastExpectedVersion, 4);
    });

    test('close passes reason + version + idempotencyKey', () async {
      final gateway = _RecordingGateway();
      await ClosePlatformTenantCommandHandler(platformGateway: gateway).handle(
        ClosePlatformTenantCommand(
          tenantId: 't-1',
          reason: 'Kết thúc hợp đồng',
          expectedVersion: 5,
          idempotencyKey: 'k-close',
        ),
      );
      expect(gateway.closeTenantId, 't-1');
      expect(gateway.closeReason, 'Kết thúc hợp đồng');
      expect(gateway.closeKey, 'k-close');
      expect(gateway.lastExpectedVersion, 5);
    });

    test('close validator requires reason', () async {
      expect(
        () => ClosePlatformTenantCommandValidator().validate(
          ClosePlatformTenantCommand(
            tenantId: 't-1',
            reason: '  ',
            expectedVersion: 1,
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
