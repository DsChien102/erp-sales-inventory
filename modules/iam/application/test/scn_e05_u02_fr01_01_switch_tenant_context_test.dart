import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// scn_e05_u02_fr01_01 — SwitchTenantContextCommandHandler scenarios (§S2).
class _FakeCurrentTenant implements ICurrentTenant {
  _FakeCurrentTenant(this.tenantId);

  @override
  final String? tenantId;
}

class _FakePreferencePort implements IPlatformUserPreferencePort {
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
  _ScenarioAccessGateway({
    this.switchResult,
    this.switchError,
  });

  final TenantContextDto? switchResult;
  final Object? switchError;

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async {
    if (switchError != null) {
      throw switchError!;
    }
    return switchResult!;
  }

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async =>
      const TenantContextDto(status: TenantContextStatus.none);

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
  group('scn_e05_u02_fr01_01 SwitchTenantContextCommandHandler', () {
    test('switch_ok — valid target updates preference + session', () async {
      final preference = _FakePreferencePort();
      final session = _FakeSessionPort();
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchResult: const TenantContextDto(
            status: TenantContextStatus.valid,
            tenantId: 'tenant-b',
            tenantName: 'Beta',
            roleLabel: 'staff',
            tenantStatus: TenantLifecycleStatus.active,
          ),
        ),
        preferencePort: preference,
        sessionPort: session,
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      final result = await handler.handle(
        SwitchTenantContextCommand(targetTenantId: 'tenant-b'),
      );

      expect(result.status, TenantContextStatus.valid);
      expect(result.tenantId, 'tenant-b');
      expect(preference.lastSelected, 'tenant-b');
      expect(session.establishedTenantId, 'tenant-b');
    });

    test('switch_same_tenant — validation error', () async {
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(),
        preferencePort: _FakePreferencePort(),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      expect(
        () => handler.handle(
          SwitchTenantContextCommand(targetTenantId: 'tenant-a'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('switch_denied — gateway error propagates', () async {
      final preference = _FakePreferencePort();
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchError: ApplicationException('TENANT_ACCESS_DENIED'),
        ),
        preferencePort: preference,
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-x')),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'TENANT_ACCESS_DENIED',
          ),
        ),
      );
      expect(preference.lastSelected, isNull);
    });

    test('switch_suspended — gateway error propagates', () async {
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchError: ApplicationException('TENANT_SUSPENDED'),
        ),
        preferencePort: _FakePreferencePort(),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-s')),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'TENANT_SUSPENDED',
          ),
        ),
      );
    });

    test('switch_closed — gateway error propagates', () async {
      final handler = SwitchTenantContextCommandHandler(
        accessGateway: _ScenarioAccessGateway(
          switchError: ApplicationException('TENANT_CLOSED'),
        ),
        preferencePort: _FakePreferencePort(),
        sessionPort: _FakeSessionPort(),
        currentTenant: _FakeCurrentTenant('tenant-a'),
      );

      await expectLater(
        handler.handle(SwitchTenantContextCommand(targetTenantId: 'tenant-c')),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'TENANT_CLOSED',
          ),
        ),
      );
    });
  });
}
