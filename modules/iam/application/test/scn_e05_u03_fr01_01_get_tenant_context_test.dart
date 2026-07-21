import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// scn_e05_u03_fr01_01 — GetTenantContextQueryHandler scenarios (§S3).
class _FakeCurrentTenant implements ICurrentTenant {
  _FakeCurrentTenant(this.tenantId);

  @override
  final String? tenantId;
}

class _FakePreferencePort implements IPlatformUserPreferencePort {
  _FakePreferencePort(this.lastSelected);

  String? lastSelected;

  @override
  Future<String?> getLastSelectedTenantId() async => lastSelected;

  @override
  Future<void> setLastSelectedTenantId(String? tenantId) async {
    lastSelected = tenantId;
  }
}

class _FakeSessionPort implements IIamSessionPort {
  String? establishedTenantId;

  @override
  SessionDto get snapshot => const SessionDto(isAuthenticated: true);

  @override
  Future<void> clear() async {}

  @override
  Future<void> establishAfterSignIn({String? tenantId}) async {
    establishedTenantId = tenantId;
  }

  @override
  Future<void> restoreFromPersistedAuth() async {}
}

class _ScenarioAccessGateway implements IIamAccessGateway {
  _ScenarioAccessGateway(this.onValidate);

  final Future<TenantContextDto> Function(String? sessionTenantId) onValidate;

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) =>
      onValidate(sessionTenantId);

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  @override
  Future<String> bootstrapOwner({String tenantName = 'My Store'}) async =>
      'tenant-1';

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async =>
      null;

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async =>
      true;

  @override
  Future<bool> isMember(String tenantId) async => true;

  @override
  Future<List<TenantMemberDto>> listTenantMembers(String tenantId) async =>
      const [];

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}
}

void main() {
  group('scn_e05_u03_fr01_01 GetTenantContextQueryHandler', () {
    test('bootstrap_valid — preference resolves + establishes session',
        () async {
      final session = _FakeSessionPort();
      final handler = GetTenantContextQueryHandler(
        accessGateway: _ScenarioAccessGateway((id) async {
          expect(id, 'tenant-pref');
          return const TenantContextDto(
            status: TenantContextStatus.valid,
            tenantId: 'tenant-pref',
            tenantName: 'Preferred',
            roleLabel: 'owner',
            tenantStatus: TenantLifecycleStatus.active,
          );
        }),
        preferencePort: _FakePreferencePort('tenant-pref'),
        sessionPort: session,
        currentTenant: _FakeCurrentTenant(null),
      );

      final result = await handler.handle(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );

      expect(result.status, TenantContextStatus.valid);
      expect(result.tenantId, 'tenant-pref');
      expect(session.establishedTenantId, 'tenant-pref');
    });

    test('bootstrap_invalid — OQ-07 returns none without auto-pick', () async {
      final session = _FakeSessionPort();
      final handler = GetTenantContextQueryHandler(
        accessGateway: _ScenarioAccessGateway((id) async {
          return const TenantContextDto(
            status: TenantContextStatus.invalidated,
            tenantId: 'tenant-gone',
            invalidationReason:
                TenantContextInvalidationReason.membershipRemoved,
            blockedErrorCode: 'MEMBERSHIP_REMOVED',
          );
        }),
        preferencePort: _FakePreferencePort('tenant-gone'),
        sessionPort: session,
        currentTenant: _FakeCurrentTenant(null),
      );

      final result = await handler.handle(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );

      expect(result.status, TenantContextStatus.none);
      expect(session.establishedTenantId, isNull);
    });

    test('context_none — no preference / no session', () async {
      final handler = GetTenantContextQueryHandler(
        accessGateway: _ScenarioAccessGateway(
          (_) async => const TenantContextDto(status: TenantContextStatus.none),
        ),
        preferencePort: _FakePreferencePort(null),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant(null),
      );

      final bootstrap = await handler.handle(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );
      expect(bootstrap.status, TenantContextStatus.none);

      final current = await handler.handle(GetTenantContextQuery());
      expect(current.status, TenantContextStatus.none);
    });

    test('context_invalidated — current session returns invalidated', () async {
      final handler = GetTenantContextQueryHandler(
        accessGateway: _ScenarioAccessGateway((id) async {
          expect(id, 'tenant-cur');
          return const TenantContextDto(
            status: TenantContextStatus.invalidated,
            tenantId: 'tenant-cur',
            invalidationReason:
                TenantContextInvalidationReason.tenantSuspended,
            blockedErrorCode: 'TENANT_SUSPENDED',
            tenantStatus: TenantLifecycleStatus.suspended,
          );
        }),
        preferencePort: _FakePreferencePort(null),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-cur'),
      );

      final result = await handler.handle(GetTenantContextQuery());

      expect(result.status, TenantContextStatus.invalidated);
      expect(
        result.invalidationReason,
        TenantContextInvalidationReason.tenantSuspended,
      );
      expect(result.blockedErrorCode, 'TENANT_SUSPENDED');
    });
  });
}
